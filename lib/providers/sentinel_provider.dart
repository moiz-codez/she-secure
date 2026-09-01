import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'sos_provider.dart';

class RoutineBlock {
  const RoutineBlock({required this.flex, required this.color});

  final int flex;
  final Color color;
}

class WatchItem {
  const WatchItem({required this.icon, required this.label, required this.sub});

  final IconData icon;
  final String label;
  final String sub;
}

class AnomalyEntry {
  const AnomalyEntry({required this.what, required this.when, required this.how});

  final String what;
  final String when;
  final String how;
}

/// Smart Sentinel: routine/anomaly monitoring. The actual sampling loop,
/// baseline check, and 30-second check-in timer all live in the background
/// service (`sentinel_service.dart`) — a separate isolate that keeps
/// running even if this app is closed, which is the whole point. This
/// provider is a thin mirror of that isolate's state (via `invoke`/`on`)
/// plus the Firestore-backed on/off + sensitivity settings.
class SentinelProvider extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  SentinelProvider({required SosProvider sos}) : _sos = sos;

  final SosProvider _sos;
  final _service = FlutterBackgroundService();

  String? _uid;
  bool sentinelOn = true;
  String sensitivity = 'Balanced';
  DocumentReference<Map<String, dynamic>>? _doc;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _prefsSub;
  StreamSubscription<Map<String, dynamic>?>? _startedSub;
  StreamSubscription<Map<String, dynamic>?>? _tickSub;
  StreamSubscription<Map<String, dynamic>?>? _endedSub;

  // Check-in state (the silent "are you safe?" prompt) — mirrored from the
  // background service, not owned here.
  bool checkInActive = false;
  int checkInSecondsLeft = 30;
  String checkInReason = '';

  /// Set by the check-in screen while it's mounted so this provider can
  /// trigger navigation on escalation without owning a BuildContext itself.
  VoidCallback? onEscalated;
  VoidCallback? onConfirmedSafe;

  static const routine = [
    RoutineBlock(flex: 2, color: Color(0xFF2C2F3F)),
    RoutineBlock(flex: 1, color: Color.fromRGBO(229, 82, 126, 0.28)),
    RoutineBlock(flex: 4, color: Color(0xFF2C2F3F)),
    RoutineBlock(flex: 1, color: Color.fromRGBO(229, 82, 126, 0.28)),
    RoutineBlock(flex: 2, color: Color(0xFF2C2F3F)),
  ];

  static const watches = [
    WatchItem(icon: Icons.route_outlined, label: 'Route', sub: 'Your two usual roads home'),
    WatchItem(icon: Icons.schedule_outlined, label: 'Arrival time', sub: 'Home between 5.20 and 5.40 pm'),
    WatchItem(icon: Icons.directions_walk_rounded, label: 'Movement', sub: 'Walking pace, not running'),
    WatchItem(icon: Icons.wifi_rounded, label: 'Familiar places', sub: '6 saved locations'),
  ];

  static const anomalies = [
    AnomalyEntry(what: 'Off route near Hasan Square', when: 'Today, 5.34 pm', how: 'You confirmed safe in 9 s'),
    AnomalyEntry(
      what: 'Running pace, no workout logged',
      when: '24 Aug, 8.02 pm',
      how: 'You confirmed safe in 4 s',
    ),
    AnomalyEntry(what: 'Unknown area, stopped 40 min', when: '11 Aug, 6.15 pm', how: 'Alert sent · Ammi called'),
  ];

  String get statusLabel => sentinelOn ? 'Watching · 12 days learned' : 'Paused';

  String get sensitivityNote => switch (sensitivity) {
        'Relaxed' => 'Asks only when you are far off your usual route for over 30 minutes.',
        'Alert' => 'Asks at the first sign of something unusual. Expect a few false alarms.',
        _ => 'Asks when two signals disagree at once — say, wrong place and running pace.',
      };

  void bindUser(String uid) {
    _uid = uid;
    _prefsSub?.cancel();
    _doc = FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('preferences');
    _prefsSub = _doc!.snapshots().listen((snap) {
      final data = snap.data();
      sentinelOn = data?['sentinelOn'] as bool? ?? true;
      sensitivity = data?['sensitivity'] as String? ?? 'Balanced';
      notifyListeners();
      _pushConfig();
    });

    _startedSub ??= _service.on('checkinStarted').listen((event) {
      checkInActive = true;
      checkInReason = event?['reason'] as String? ?? '';
      checkInSecondsLeft = event?['secondsLeft'] as int? ?? 30;
      notifyListeners();
    });
    _tickSub ??= _service.on('checkinTick').listen((event) {
      checkInSecondsLeft = event?['secondsLeft'] as int? ?? checkInSecondsLeft;
      notifyListeners();
    });
    _endedSub ??= _service.on('checkinEnded').listen((event) {
      checkInActive = false;
      notifyListeners();
      if (event?['escalated'] == true) {
        _sos.markArmedExternally();
        onEscalated?.call();
      } else {
        onConfirmedSafe?.call();
      }
    });
  }

  Future<void> _pushConfig() async {
    if (_uid == null) return;
    if (sentinelOn && !await _service.isRunning()) {
      await Permission.notification.request();
      await _service.startService();
    }
    _service.invoke('configure', {'uid': _uid, 'sentinelOn': sentinelOn, 'sensitivity': sensitivity});
  }

  void unbindUser() {
    _prefsSub?.cancel();
    _prefsSub = null;
    _startedSub?.cancel();
    _startedSub = null;
    _tickSub?.cancel();
    _tickSub = null;
    _endedSub?.cancel();
    _endedSub = null;
    _service.invoke('stop');
    _doc = null;
    _uid = null;
    sentinelOn = true;
    sensitivity = 'Balanced';
    checkInActive = false;
    notifyListeners();
  }

  void toggle() {
    sentinelOn = !sentinelOn;
    notifyListeners();
    _doc?.set({'sentinelOn': sentinelOn}, SetOptions(merge: true));
    _pushConfig();
  }

  void setSensitivity(String value) {
    sensitivity = value;
    notifyListeners();
    _doc?.set({'sensitivity': value}, SetOptions(merge: true));
    _pushConfig();
  }

  /// Forwards the on-screen "I am safe" confirmation to the background
  /// service, which owns the actual timer.
  void confirmSafe() => _service.invoke('confirm');

  /// Fired by a sustained hold on "I am safe" (duress) or the explicit
  /// "send the alert now" button — also forwarded, so there is exactly one
  /// place (the background service) that ever decides to fire.
  void escalateNow() => _service.invoke('escalateNow');

  void simulate() => _service.invoke('simulateCheckIn');

  @override
  void dispose() {
    _prefsSub?.cancel();
    _startedSub?.cancel();
    _tickSub?.cancel();
    _endedSub?.cancel();
    super.dispose();
  }
}
