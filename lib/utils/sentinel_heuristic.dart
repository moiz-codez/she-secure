import 'dart:math';

/// One periodic location+motion reading, tagged with when in the week it
/// happened so it can be matched against the same time next week.
class SentinelSample {
  const SentinelSample({
    required this.weekday,
    required this.minuteOfDay,
    required this.lat,
    required this.lng,
    required this.speed,
  });

  /// 1 (Monday) - 7 (Sunday), matching [DateTime.weekday].
  final int weekday;

  /// Minutes since midnight, 0-1439.
  final int minuteOfDay;

  final double lat;
  final double lng;

  /// Metres per second.
  final double speed;
}

class AnomalyResult {
  const AnomalyResult({required this.isAnomaly, this.reason = '', this.signalPresent = false});

  final bool isAnomaly;
  final String reason;

  /// True whenever off-route-and-off-pace held this tick, regardless of
  /// whether [sensitivity] was strict enough to actually flag it — the
  /// caller uses this (not [isAnomaly]) to track how many consecutive
  /// ticks the raw signal has held, which 'Relaxed' sensitivity needs to
  /// decide "sustained" on the *next* tick.
  final bool signalPresent;
}

/// Haversine distance in metres — no plugin dependency, so this stays a
/// pure, unit-testable function (geolocator's own version needs a platform
/// channel).
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// ponytail: a centroid + speed-range heuristic, not real route-corridor
/// matching — real (built from actual samples, not a fake trigger) but
/// deliberately simple. Upgrade to proper path matching (e.g. DTW against
/// a stored route polyline) if the false-positive rate proves too high
/// once there's real usage data to tune against.
///
/// [baseline] should already be filtered to samples from the same
/// [SentinelSample.weekday] within a similar time-of-day window as
/// [current] — that filtering doubles as the "arrival-time window" signal
/// from the design, rather than it being a separate third check.
///
/// [recentAnomalyStreak] is how many consecutive prior ticks were already
/// flagged anomalous; 'Relaxed' sensitivity only fires once that streak
/// shows the deviation is sustained, not a single noisy reading.
AnomalyResult checkAnomaly({
  required SentinelSample current,
  required List<SentinelSample> baseline,
  required String sensitivity,
  int recentAnomalyStreak = 0,
}) {
  // Not enough history at this time slot yet to know what's "usual" — the
  // ~2-week baseline-building window from the design.
  if (baseline.length < 5) {
    return const AnomalyResult(isAnomaly: false);
  }

  final avgLat = baseline.map((s) => s.lat).reduce((a, b) => a + b) / baseline.length;
  final avgLng = baseline.map((s) => s.lng).reduce((a, b) => a + b) / baseline.length;
  final distance = distanceMeters(avgLat, avgLng, current.lat, current.lng);

  final speeds = baseline.map((s) => s.speed).toList()..sort();
  final typicalMax = speeds[((speeds.length - 1) * 0.9).round()];
  final typicalMin = speeds.first;

  final distanceThreshold = switch (sensitivity) {
    'Relaxed' => 900.0,
    'Alert' => 300.0,
    _ => 500.0,
  };
  final offRoute = distance > distanceThreshold;

  // Either running when usually walking, or stopped somewhere unfamiliar
  // when usually still moving — both appear as real anomaly examples in
  // the design (running pace; stopped 40 min in an unknown area).
  final running = current.speed > max(typicalMax * 1.8, 2.5);
  final stalled = typicalMin > 0.3 && current.speed < typicalMin * 0.3;
  final offPace = running || stalled;

  final signalPresent = offRoute && offPace;
  final flagged = switch (sensitivity) {
    'Alert' => offRoute || offPace,
    'Relaxed' => signalPresent && recentAnomalyStreak >= 1,
    _ => signalPresent,
  };

  if (!flagged) return AnomalyResult(isAnomaly: false, signalPresent: signalPresent);

  final km = (distance / 1000).toStringAsFixed(1);
  final reason = switch ((offRoute, offPace)) {
    (true, true) when running => 'You are $km km off your usual route and moving at running pace.',
    (true, true) => 'You are $km km off your usual route and have stopped moving.',
    (true, false) => 'You are $km km off your usual route for this time.',
    (false, true) when running => 'You are moving much faster than usual for this time.',
    _ => 'Your movement looks unusual for this time.',
  };
  return AnomalyResult(isAnomaly: true, reason: reason, signalPresent: true);
}
