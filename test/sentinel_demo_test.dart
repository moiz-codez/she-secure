// End-to-end Smart Sentinel logic on the demo routine: the same 14 days
// "Load demo data" writes, the same baseline selection the background
// service queries (same weekday, ±90 min, past days only), and the real
// anomaly check — everything except Firestore and GPS.

import 'package:flutter_test/flutter_test.dart';
import 'package:she_secure/services/user_data_service.dart';
import 'package:she_secure/utils/routine_summary.dart';
import 'package:she_secure/utils/sentinel_heuristic.dart';

const home = (31.5204, 74.3587);
final today = DateTime(2026, 10, 14); // a Wednesday

List<(DateTime, SentinelSample)> _demoSamples() => [
      for (var dayBack = 14; dayBack >= 1; dayBack--)
        for (var minute = 0; minute < 24 * 60; minute += 15)
          () {
            final day = today.subtract(Duration(days: dayBack));
            final (lat, lng, speed) = UserDataService.demoRoutineAt(minute, weekend: day.weekday >= 6, home: home);
            return (
              day.add(Duration(minutes: minute)),
              SentinelSample(weekday: day.weekday, minuteOfDay: minute, lat: lat, lng: lng, speed: speed),
            );
          }(),
    ];

/// Mirrors the background service's Firestore query + filter.
List<SentinelSample> _baselineFor(SentinelSample current, List<(DateTime, SentinelSample)> all) => [
      for (final (at, s) in all)
        if (s.weekday == current.weekday && (s.minuteOfDay - current.minuteOfDay).abs() <= 90 && at.isBefore(today)) s,
    ];

AnomalyResult _check(int minute, (double, double, double) where, String sensitivity, List<(DateTime, SentinelSample)> all) {
  final current = SentinelSample(
    weekday: today.weekday,
    minuteOfDay: minute,
    lat: where.$1,
    lng: where.$2,
    speed: where.$3,
  );
  return checkAnomaly(current: current, baseline: _baselineFor(current, all), sensitivity: sensitivity);
}

void main() {
  final all = _demoSamples();
  final atWork = UserDataService.demoRoutineAt(600, weekend: false, home: home);

  test('demo data gives the Sentinel screen a full learned routine', () {
    final s = summarizeRoutine(all);
    expect(s.daysLearned, 14);
    expect(s.movingSlots[2], isTrue, reason: '8:00–8:30 commute');
    expect(s.movingSlots[20], isTrue, reason: '17:00–17:30 commute');
    expect(s.movingSlots.where((m) => m).length, 2);
    expect(s.settledByMinute, 17 * 60 + 15);
    expect(s.familiarPlaces, greaterThanOrEqualTo(2), reason: 'home + work');
  });

  test('following the usual routine never asks, at any sensitivity', () {
    for (final sens in ['Relaxed', 'Balanced', 'Alert']) {
      expect(_check(600, atWork, sens, all).isAnomaly, isFalse, reason: '$sens at work, 10:00');
      final commuting = UserDataService.demoRoutineAt(495, weekend: false, home: home);
      expect(_check(495, commuting, sens, all).isAnomaly, isFalse, reason: '$sens on the usual walk, 8:15');
    }
  });

  test('home at 10:00 on a workday (≈2 km off): Alert asks, Balanced waits for a 2nd signal', () {
    final stillAtHome = (home.$1, home.$2, 0.0);
    final alert = _check(600, stillAtHome, 'Alert', all);
    expect(alert.isAnomaly, isTrue);
    expect(alert.reason, contains('off your usual route'));
    expect(_check(600, stillAtHome, 'Balanced', all).isAnomaly, isFalse);
  });

  test('running somewhere unfamiliar mid-commute: Balanced asks', () {
    final farAndRunning = (home.$1 - 0.02, home.$2 - 0.02, 4.0); // ~3 km SW, running pace
    final r = _check(495, farAndRunning, 'Balanced', all);
    expect(r.isAnomaly, isTrue);
    expect(r.reason, contains('running pace'));
  });
}
