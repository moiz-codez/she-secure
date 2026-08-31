import 'dart:async';

import 'package:flutter/foundation.dart';

import 'sos_provider.dart';

class HeardEntry {
  const HeardEntry({required this.what, required this.when, required this.how});

  final String what;
  final String when;
  final String how;
}

/// Distress Listening: continuous mic monitoring for a scream or sustained
/// crying, firing SOS with no confirmation on detection. Phase 1 exposes
/// the same "simulate a detected scream" flow as the design canvas;
/// Phase 5 replaces the simulated trigger with real on-device YAMNet
/// inference feeding into the same [heardScream] entry point.
class ListenProvider extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  ListenProvider({required SosProvider sos}) : _sos = sos;

  final SosProvider _sos;

  bool listenOn = true;
  String earSensitivity = 'Balanced';
  bool detected = false;
  Timer? _detectionTimer;

  /// Set by the listen screen while mounted, so this provider can trigger
  /// navigation to the SOS screen on detection.
  VoidCallback? onDetectionEscalated;

  static const heard = [
    HeardEntry(what: 'Loud voices', when: 'Today, 2.14 pm', how: 'Ignored · below threshold'),
    HeardEntry(what: 'Scream detected', when: '19 Aug, 11.48 pm', how: 'Alert sent · 4 contacts'),
  ];

  String get statusLabel => listenOn ? 'Listening' : 'Off';

  String get sensitivityNote => switch (earSensitivity) {
        'Relaxed' => 'Only a clear, sustained scream fires an alert.',
        'Alert' => 'A raised voice or crying is enough. More false alarms.',
        _ => 'A scream or sustained crying fires an alert. Traffic and TV noise are ignored.',
      };

  void toggle() {
    listenOn = !listenOn;
    notifyListeners();
  }

  void setSensitivity(String value) {
    earSensitivity = value;
    notifyListeners();
  }

  void heardScream() {
    detected = true;
    notifyListeners();
    _detectionTimer?.cancel();
    _detectionTimer = Timer(const Duration(milliseconds: 1900), () {
      detected = false;
      notifyListeners();
      _sos.arm();
      onDetectionEscalated?.call();
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    super.dispose();
  }
}
