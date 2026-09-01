// Unit tests for the Smart Sentinel anomaly heuristic — pure logic, no
// platform channels, so plain `test()` rather than `testWidgets()`.

import 'package:flutter_test/flutter_test.dart';
import 'package:she_secure/utils/sentinel_heuristic.dart';

List<SentinelSample> _walkingBaseline({int count = 10}) => List.generate(
      count,
      (_) => const SentinelSample(weekday: 1, minuteOfDay: 1050, lat: 24.8600, lng: 67.0010, speed: 1.3),
    );

void main() {
  test('too little history: never flags, regardless of how far off', () {
    final result = checkAnomaly(
      current: const SentinelSample(weekday: 1, minuteOfDay: 1050, lat: 25.2, lng: 67.5, speed: 4),
      baseline: _walkingBaseline(count: 3),
      sensitivity: 'Balanced',
    );
    expect(result.isAnomaly, false);
  });

  test('on route, normal pace: never flags', () {
    final result = checkAnomaly(
      current: const SentinelSample(weekday: 1, minuteOfDay: 1050, lat: 24.8601, lng: 67.0011, speed: 1.4),
      baseline: _walkingBaseline(),
      sensitivity: 'Balanced',
    );
    expect(result.isAnomaly, false);
    expect(result.signalPresent, false);
  });

  test('Balanced: off-route alone does not flag (needs both signals)', () {
    final result = checkAnomaly(
      current: const SentinelSample(weekday: 1, minuteOfDay: 1050, lat: 24.8700, lng: 67.0010, speed: 1.3),
      baseline: _walkingBaseline(),
      sensitivity: 'Balanced',
    );
    expect(result.isAnomaly, false);
  });

  test('Balanced: off-route AND running pace together flags immediately', () {
    final result = checkAnomaly(
      current: const SentinelSample(weekday: 1, minuteOfDay: 1050, lat: 24.8700, lng: 67.0010, speed: 4.5),
      baseline: _walkingBaseline(),
      sensitivity: 'Balanced',
    );
    expect(result.isAnomaly, true);
    expect(result.reason, contains('running pace'));
  });

  test('Balanced: off-route AND stopped (usually moving) also flags', () {
    final result = checkAnomaly(
      current: const SentinelSample(weekday: 1, minuteOfDay: 1050, lat: 24.8700, lng: 67.0010, speed: 0.0),
      baseline: _walkingBaseline(),
      sensitivity: 'Balanced',
    );
    expect(result.isAnomaly, true);
    expect(result.reason, contains('stopped'));
  });

  test('Alert: off-route alone is enough to flag', () {
    final result = checkAnomaly(
      current: const SentinelSample(weekday: 1, minuteOfDay: 1050, lat: 24.8700, lng: 67.0010, speed: 1.3),
      baseline: _walkingBaseline(),
      sensitivity: 'Alert',
    );
    expect(result.isAnomaly, true);
  });

  test('Relaxed: first anomalous tick is held back, second (sustained) fires', () {
    const sample = SentinelSample(weekday: 1, minuteOfDay: 1050, lat: 24.8700, lng: 67.0010, speed: 4.5);
    final first = checkAnomaly(current: sample, baseline: _walkingBaseline(), sensitivity: 'Relaxed');
    expect(first.isAnomaly, false);
    expect(first.signalPresent, true, reason: 'raw signal must still be reported so the caller can track the streak');

    final second = checkAnomaly(
      current: sample,
      baseline: _walkingBaseline(),
      sensitivity: 'Relaxed',
      recentAnomalyStreak: 1,
    );
    expect(second.isAnomaly, true);
  });

  test('Relaxed: needs a bigger deviation than Alert to ever raise the raw signal', () {
    // A distance that Alert would already flag as off-route on its own,
    // but is inside Relaxed's much wider distance threshold.
    final result = checkAnomaly(
      current: const SentinelSample(weekday: 1, minuteOfDay: 1050, lat: 24.8640, lng: 67.0010, speed: 4.5),
      baseline: _walkingBaseline(),
      sensitivity: 'Relaxed',
    );
    expect(result.signalPresent, false);
  });
}
