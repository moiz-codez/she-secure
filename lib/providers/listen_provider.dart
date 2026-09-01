import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/sentinel_service.dart';
import 'sos_provider.dart';

class HeardEntry {
  const HeardEntry({required this.what, required this.when, required this.how});

  final String what;
  final String when;
  final String how;
}

/// Distress Listening: continuous mic monitoring for a scream or sustained
/// crying, firing SOS with no confirmation on detection. The actual mic
/// capture and on-device YAMNet inference run in the same background
/// service Smart Sentinel uses (`sentinel_service.dart`) — a separate
/// isolate that keeps listening even if this app is closed. This provider
/// just mirrors that isolate's detection events and owns the brief
/// "Scream detected" flash before navigating, which is cosmetic (the real
/// alert already fired by the time this event arrives).
class ListenProvider extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  ListenProvider({required SosProvider sos}) : _sos = sos;

  final SosProvider _sos;
  final _service = FlutterBackgroundService();

  String? _uid;
  bool listenOn = true;
  String earSensitivity = 'Balanced';
  bool detected = false;
  Timer? _detectionTimer;
  DocumentReference<Map<String, dynamic>>? _doc;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _prefsSub;
  StreamSubscription<Map<String, dynamic>?>? _detectedSub;

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

  void bindUser(String uid) {
    _uid = uid;
    _prefsSub?.cancel();
    _doc = FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('preferences');
    _prefsSub = _doc!.snapshots().listen((snap) {
      final data = snap.data();
      listenOn = data?['listenOn'] as bool? ?? true;
      earSensitivity = data?['earSensitivity'] as String? ?? 'Balanced';
      notifyListeners();
      _pushConfig();
    });

    _detectedSub ??= _service.on('screamDetected').listen((_) => _showDetected());
  }

  Future<void> _pushConfig() async {
    if (_uid == null) return;
    if (listenOn) await Permission.microphone.request();
    await pushBackgroundConfig(
      {'uid': _uid, 'listenOn': listenOn, 'earSensitivity': earSensitivity},
      needed: listenOn,
    );
  }

  void unbindUser() {
    _prefsSub?.cancel();
    _prefsSub = null;
    _detectedSub?.cancel();
    _detectedSub = null;
    _service.invoke('stop');
    _doc = null;
    _uid = null;
    listenOn = true;
    earSensitivity = 'Balanced';
    notifyListeners();
  }

  void toggle() {
    listenOn = !listenOn;
    notifyListeners();
    _doc?.set({'listenOn': listenOn}, SetOptions(merge: true));
    _pushConfig();
  }

  void setSensitivity(String value) {
    earSensitivity = value;
    notifyListeners();
    _doc?.set({'earSensitivity': value}, SetOptions(merge: true));
    _pushConfig();
  }

  /// The real alert has already fired by the time this is called (the
  /// background service fires it immediately on a sustained detection,
  /// with no confirmation step) — this is just the brief on-screen flash
  /// before handing off to the SOS screen.
  void _showDetected() {
    detected = true;
    notifyListeners();
    _sos.markArmedExternally();
    _detectionTimer?.cancel();
    _detectionTimer = Timer(const Duration(milliseconds: 1900), () {
      detected = false;
      notifyListeners();
      onDetectionEscalated?.call();
    });
  }

  /// Demo button — routes through the same background service and the
  /// same real alert-firing path as a genuine detection, rather than a
  /// separate local simulation.
  void simulate() => _service.invoke('simulateScream');

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _prefsSub?.cancel();
    _detectedSub?.cancel();
    super.dispose();
  }
}
