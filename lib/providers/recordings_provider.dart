import 'dart:async';

import 'package:flutter/material.dart';

enum RecordingTab { video, audio, photo }

class RecordingClip {
  const RecordingClip({required this.name, required this.meta, required this.icon});

  final String name;
  final String meta;
  final IconData icon;
}

/// Placeholder capture state for Phase 1. Phase 6 wires this to the real
/// camera/mic and saves files under an on-device `evidence/` folder, with
/// only a metadata reference (not the file itself) kept in Firestore.
class RecordingsProvider extends ChangeNotifier {
  RecordingTab tab = RecordingTab.video;
  bool isRecording = false;
  int seconds = 0;
  Timer? _timer;

  final List<RecordingClip> clips = const [
    RecordingClip(name: 'Video · 12 Aug, 9:44 pm', meta: '1 min 08 s · 24 MB', icon: Icons.videocam_outlined),
    RecordingClip(name: 'Audio · 12 Aug, 9:41 pm', meta: '3 min 22 s · 2.1 MB', icon: Icons.mic_none_rounded),
    RecordingClip(name: 'Photo · 28 Jul, 7:15 pm', meta: '2 images · 3.4 MB', icon: Icons.image_outlined),
    RecordingClip(name: 'Audio · 14 Jul, 4:02 pm', meta: '48 s · 0.6 MB', icon: Icons.mic_none_rounded),
  ];

  void setTab(RecordingTab value) {
    tab = value;
    notifyListeners();
  }

  void toggleRecording() {
    if (isRecording) {
      _timer?.cancel();
      isRecording = false;
      seconds = 0;
      notifyListeners();
      return;
    }
    isRecording = true;
    seconds = 0;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds += 1;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
