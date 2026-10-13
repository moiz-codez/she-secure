"""Runs the app's bundled yamnet.tflite the way sentinel_service.dart,
audio_detection_service.dart and listen_heuristic.dart do (16 kHz mono
PCM16, 0.975 s windows at 50% overlap, max of "Screaming" / "Crying,
sobbing", per-sensitivity threshold x consecutive windows) over labelled
clips, and reports what Distress Listening would do. Rerun after changing
thresholds; keep SENS and HOP in sync with the Dart code.

    pip install ai-edge-litert soundfile numpy
    python tool/yamnet_eval.py <clips-dir>

<clips-dir> holds scream/, crying/ and negative/ folders of .wav files.
Clips used for the Oct 2026 tuning: screams from
github.com/kd-abhidev/Human-scream-detection (positive/, freesound-sourced);
crying_baby plus laughing/dog/rain/siren/train/clock_tick/door_wood_knock/
keyboard_typing from ESC-50 (github.com/karolpiczak/ESC-50); speech from
that scream repo's negative/ folder; Google's audioset/speech_whistling2.wav.
"""
import glob
import os
import sys

import numpy as np
import soundfile as sf
from ai_edge_litert.interpreter import Interpreter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'models')
HERE = sys.argv[1]
WINDOW = 15600
HOP = WINDOW // 2
LABELS = ['Screaming', 'Crying, sobbing']
# listen_heuristic.dart: (confidence threshold, consecutive windows needed)
SENS = {'Alert': (0.4, 1), 'Balanced': (0.4, 2), 'Relaxed': (0.5, 3)}

interp = Interpreter(model_path=os.path.join(ROOT, 'yamnet.tflite'))
interp.allocate_tensors()
inputs, outputs = interp.get_input_details(), interp.get_output_details()
print('inputs :', [(d['name'], list(d['shape'])) for d in inputs])
print('outputs:', [(d['name'], list(d['shape'])) for d in outputs])
inp = next(d for d in inputs if int(np.prod(d['shape'])) == WINDOW)
out = next(d for d in outputs if d['shape'][-1] == 521)

# Same parsing as AudioDetectionService._loadLabels.
names, index = {}, {}
for line in open(os.path.join(ROOT, 'yamnet_class_map.csv'), encoding='utf-8').read().split('\n')[1:]:
    if not line.strip():
        continue
    a = line.index(',')
    b = line.index(',', a + 1)
    name = line[b + 1:].strip()
    if name.startswith('"') and name.endswith('"'):
        name = name[1:-1]
    index[name] = int(line[:a])
    names[int(line[:a])] = name
print('label indices:', {l: index.get(l) for l in LABELS})


def load16k(path):
    audio, sr = sf.read(path, dtype='float32', always_2d=True)
    audio = audio.mean(axis=1)
    if sr != 16000:
        n = int(len(audio) * 16000 / sr)
        audio = np.interp(np.linspace(0, len(audio) - 1, n), np.arange(len(audio)), audio).astype(np.float32)
    # The app reads PCM16 from the mic; quantise the same way.
    return (np.clip(audio, -1, 1) * 32767).astype(np.int16).astype(np.float32) / 32768.0


def windows_scores(audio):
    confs, tops = [], []
    for start in range(0, len(audio) - WINDOW + 1, HOP):
        interp.set_tensor(inp['index'], audio[start:start + WINDOW].reshape(inp['shape']))
        interp.invoke()
        scores = interp.get_tensor(out['index']).reshape(-1)
        confs.append(max(scores[index[l]] for l in LABELS))
        tops.append(names[int(scores.argmax())])
    return confs, tops


def fires(confs, sens):
    threshold, needed = SENS[sens]
    streak = 0
    for c in confs:
        streak = streak + 1 if c >= threshold else 0
        if streak >= needed:
            return True
    return False


groups = {g: sorted(glob.glob(os.path.join(HERE, g, '*.wav'))) for g in ['scream', 'crying', 'negative']}
summary = {}
for group, files in groups.items():
    print(f'\n=== {group} ({len(files)}) ===')
    counts = {s: 0 for s in SENS}
    for f in files:
        confs, tops = windows_scores(load16k(f))
        if not confs:
            continue
        hit = {s: fires(confs, s) for s in SENS}
        for s in SENS:
            counts[s] += hit[s]
        top = max(set(tops), key=tops.count)
        flags = ' '.join(s[0] if hit[s] else '.' for s in SENS)
        print(f'  [{flags}] max={max(confs):.2f} windows={len(confs):2d} top="{top}"  {os.path.basename(f)[:50]}')
    summary[group] = (counts, len(files))

print('\n=== would fire an alert (A=Alert, B=Balanced, R=Relaxed) ===')
for group, (counts, n) in summary.items():
    print(f'  {group:9s} ' + '  '.join(f'{s}: {counts[s]}/{n}' for s in SENS))
