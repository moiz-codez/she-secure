import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

/// On-device YAMNet inference for Distress Listening. Loaded once and
/// reused for every 0.975s window — reloading the interpreter per window
/// would be wasteful and isn't necessary since it's stateless per call.
class AudioDetectionService {
  AudioDetectionService._();

  static Interpreter? _interpreter;
  static int _inputIndex = 0;
  static int _outputIndex = 0;
  static List<int> _inputShape = const [1, 15600];
  static List<int> _outputShape = const [1, 521];
  static Map<String, int>? _labelIndex;

  static const _modelAsset = 'assets/models/yamnet.tflite';
  static const _labelsAsset = 'assets/models/yamnet_class_map.csv';

  /// The exact tensor a packaged model exposes at which index isn't
  /// guaranteed by the file format alone, so this picks the input tensor
  /// shaped for a 15600-sample waveform and the output tensor shaped for
  /// the 521 AudioSet classes, rather than assuming index 0 for both.
  static Future<void> _ensureLoaded() async {
    if (_interpreter != null) return;
    final interpreter = await Interpreter.fromAsset(_modelAsset);

    final inputs = interpreter.getInputTensors();
    final inputIdx = inputs.indexWhere((t) => t.shape.reduce((a, b) => a * b) == 15600);
    _inputIndex = inputIdx >= 0 ? inputIdx : 0;
    _inputShape = inputs[_inputIndex].shape;

    final outputs = interpreter.getOutputTensors();
    final outputIdx = outputs.indexWhere((t) => t.shape.last == 521);
    _outputIndex = outputIdx >= 0 ? outputIdx : 0;
    _outputShape = outputs[_outputIndex].shape;

    _labelIndex = await _loadLabels();
    _interpreter = interpreter;
  }

  static Future<Map<String, int>> _loadLabels() async {
    final csv = await rootBundle.loadString(_labelsAsset);
    final map = <String, int>{};
    for (final line in csv.split('\n').skip(1)) {
      if (line.trim().isEmpty) continue;
      final firstComma = line.indexOf(',');
      final secondComma = line.indexOf(',', firstComma + 1);
      if (firstComma < 0 || secondComma < 0) continue;
      final index = int.tryParse(line.substring(0, firstComma));
      if (index == null) continue;
      var name = line.substring(secondComma + 1).trim();
      if (name.startsWith('"') && name.endsWith('"')) {
        name = name.substring(1, name.length - 1);
      }
      map[name] = index;
    }
    return map;
  }

  static List<dynamic> _zeros(List<int> shape) {
    if (shape.length == 1) return List.filled(shape[0], 0.0);
    return List.generate(shape[0], (_) => _zeros(shape.sublist(1)));
  }

  static List<double> _flatten(dynamic nested) {
    if (nested is List<double>) return nested;
    final out = <double>[];
    void walk(dynamic v) {
      if (v is List) {
        for (final e in v) {
          walk(e);
        }
      } else {
        out.add((v as num).toDouble());
      }
    }

    walk(nested);
    return out;
  }

  /// Runs one inference on a 15600-sample (0.975s @ 16kHz) mono waveform
  /// normalized to [-1, 1]. Returns the confidence for [labels] — the max
  /// across them, since a distress sound may register under either
  /// "Screaming" or "Crying, sobbing".
  static Future<double> classify(List<double> window, List<String> labels) async {
    await _ensureLoaded();
    final interpreter = _interpreter!;

    final input = List<double>.from(window).reshape<double>(_inputShape);
    final output = _zeros(_outputShape);
    interpreter.runForMultipleInputs([input], {_outputIndex: output});

    final scores = _flatten(output);
    final labelIndex = _labelIndex!;
    var best = 0.0;
    for (final label in labels) {
      final idx = labelIndex[label];
      if (idx != null && idx < scores.length && scores[idx] > best) {
        best = scores[idx];
      }
    }
    return best;
  }
}
