import 'dart:async';

import 'package:flutter/material.dart';

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

/// Smart Sentinel: routine/anomaly monitoring. Phase 1 exposes the same
/// UI-facing state and the "simulate" / check-in escalation flow the
/// design canvas modeled; Phase 4 replaces the simulated trigger with a
/// real background location+motion service feeding into the same
/// [raiseCheckIn] entry point, so the check-in/escalation logic below
/// doesn't need to change.
class SentinelProvider extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  SentinelProvider({required SosProvider sos}) : _sos = sos;

  final SosProvider _sos;

  bool sentinelOn = true;
  String sensitivity = 'Balanced';

  // Check-in state (the silent "are you safe?" prompt).
  bool checkInActive = false;
  int checkInSecondsLeft = 30;
  String checkInReason = '';
  Timer? _checkInTimer;

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

  void toggle() {
    sentinelOn = !sentinelOn;
    notifyListeners();
  }

  void setSensitivity(String value) {
    sensitivity = value;
    notifyListeners();
  }

  void raiseCheckIn(String reason) {
    _checkInTimer?.cancel();
    checkInActive = true;
    checkInReason = reason;
    checkInSecondsLeft = 30;
    notifyListeners();
    _checkInTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      checkInSecondsLeft -= 1;
      if (checkInSecondsLeft <= 0) {
        timer.cancel();
        _escalate();
      } else {
        notifyListeners();
      }
    });
  }

  void confirmSafe() {
    _checkInTimer?.cancel();
    checkInActive = false;
    notifyListeners();
    onConfirmedSafe?.call();
  }

  /// Fired by a sustained hold on "I am safe" (duress) or the explicit
  /// "send the alert now" button.
  void escalateNow() => _escalate();

  void _escalate() {
    _checkInTimer?.cancel();
    checkInActive = false;
    _sos.arm();
    onEscalated?.call();
  }

  void simulate() {
    raiseCheckIn('You are 2.4 km off your usual route home and moving at running pace.');
  }

  @override
  void dispose() {
    _checkInTimer?.cancel();
    super.dispose();
  }
}
