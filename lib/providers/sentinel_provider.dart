import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/permission_service.dart';
import '../services/sentinel_service.dart';
import '../utils/formatters.dart';
import '../utils/routine_summary.dart';
import '../utils/sentinel_heuristic.dart';
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

  RoutineSummary summary = RoutineSummary.empty;
  List<AnomalyEntry> anomalies = const [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;
  DateTime? _summaryLoadedAt;

  static const _usual = Color(0xFF2C2F3F);
  static const _moving = Color.fromRGBO(229, 82, 126, 0.28);

  /// The weekday strip as runs of same-colour blocks (moving vs. still).
  List<RoutineBlock> get routine {
    final slots = summary.movingSlots;
    if (slots.isEmpty) return const [RoutineBlock(flex: 1, color: _usual)];
    final blocks = <RoutineBlock>[];
    var runStart = 0;
    for (var i = 1; i <= slots.length; i++) {
      if (i == slots.length || slots[i] != slots[runStart]) {
        blocks.add(RoutineBlock(flex: i - runStart, color: slots[runStart] ? _moving : _usual));
        runStart = i;
      }
    }
    return blocks;
  }

  List<WatchItem> get watches {
    final s = summary;
    const learning = 'Still learning';
    final speed = s.typicalSpeed;
    return [
      WatchItem(
        icon: Icons.route_outlined,
        label: 'Route',
        sub: s.sampleCount == 0 ? 'Learns over about 2 weeks' : '${s.sampleCount} readings over ${s.daysLearned} days',
      ),
      WatchItem(
        icon: Icons.schedule_outlined,
        label: 'Arrival time',
        sub: s.settledByMinute == null ? learning : 'Usually settled by ${formatMinuteOfDay(s.settledByMinute!)}',
      ),
      WatchItem(
        icon: Icons.directions_walk_rounded,
        label: 'Movement',
        sub: switch (speed) {
          null => learning,
          < 2.2 => 'Walking pace, not running',
          < 6 => 'Cycling or slow-traffic pace',
          _ => 'Usually in a vehicle',
        },
      ),
      WatchItem(
        icon: Icons.place_outlined,
        label: 'Familiar places',
        sub: s.familiarPlaces == 0 ? learning : '${s.familiarPlaces} saved locations',
      ),
    ];
  }

  String get statusLabel => !sentinelOn
      ? 'Paused'
      : summary.daysLearned == 0
          ? 'Watching · learning your routine'
          : 'Watching · ${summary.daysLearned} days learned';

  /// Re-reads the last 14 days of samples into [summary]. Called when the
  /// Sentinel screen opens (and after demo data loads).
  /// ponytail: reads every sample in the window (~4k docs at 5-min
  /// sampling), throttled to once per 10 min — move to a summary doc the
  /// background service maintains if read costs ever matter.
  Future<void> refreshSummary({bool force = false}) async {
    final uid = _uid;
    if (uid == null) return;
    final loadedAt = _summaryLoadedAt;
    if (!force && loadedAt != null && DateTime.now().difference(loadedAt) < const Duration(minutes: 10)) return;
    _summaryLoadedAt = DateTime.now();
    final since = DateTime.now().subtract(const Duration(days: 14));
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sentinelSamples')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();
    if (uid != _uid) return;
    summary = summarizeRoutine([
      for (final d in snap.docs)
        if (d.data()['timestamp'] is Timestamp)
          (
            (d['timestamp'] as Timestamp).toDate(),
            SentinelSample(
              weekday: d['weekday'] as int,
              minuteOfDay: d['minuteOfDay'] as int,
              lat: (d['lat'] as num).toDouble(),
              lng: (d['lng'] as num).toDouble(),
              speed: (d['speed'] as num).toDouble(),
            ),
          ),
    ]);
    notifyListeners();
  }

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

    _eventsSub?.cancel();
    _eventsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sentinelEvents')
        .orderBy('when', descending: true)
        .limit(3)
        .snapshots()
        .listen((snap) {
      anomalies = [
        for (final d in snap.docs)
          AnomalyEntry(
            what: d.data()['what'] as String? ?? '',
            when: formatWhen((d.data()['when'] as Timestamp?)?.toDate()),
            how: d.data()['how'] as String? ?? '',
          ),
      ];
      notifyListeners();
    });
    unawaited(refreshSummary(force: true));

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
    if (sentinelOn) await ensurePermission(Permission.notification);
    await pushBackgroundConfig(
      {'uid': _uid, 'sentinelOn': sentinelOn, 'sensitivity': sensitivity},
      needed: sentinelOn,
    );
  }

  void unbindUser() {
    _prefsSub?.cancel();
    _prefsSub = null;
    _eventsSub?.cancel();
    _eventsSub = null;
    summary = RoutineSummary.empty;
    anomalies = const [];
    _summaryLoadedAt = null;
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
    _eventsSub?.cancel();
    _startedSub?.cancel();
    _tickSub?.cancel();
    _endedSub?.cancel();
    super.dispose();
  }
}
