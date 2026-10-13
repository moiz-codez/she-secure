import 'sentinel_heuristic.dart';

/// The Sentinel screen's 7 am – 6 pm weekday strip: 22 half-hour slots.
const routineStartMinute = 7 * 60;
const routineEndMinute = 18 * 60;
const routineSlotMinutes = 30;
const routineSlotCount = (routineEndMinute - routineStartMinute) ~/ routineSlotMinutes;

/// Above this a sample counts as travelling, not just shifting around a room.
const _movingSpeed = 1.0; // m/s

/// What Smart Sentinel has actually learned, distilled for display. Built
/// from real `sentinelSamples` — nothing here is canned copy.
class RoutineSummary {
  const RoutineSummary({
    required this.daysLearned,
    required this.sampleCount,
    required this.movingSlots,
    required this.typicalSpeed,
    required this.settledByMinute,
    required this.familiarPlaces,
  });

  static const empty = RoutineSummary(
    daysLearned: 0,
    sampleCount: 0,
    movingSlots: [],
    typicalSpeed: null,
    settledByMinute: null,
    familiarPlaces: 0,
  );

  final int daysLearned;
  final int sampleCount;

  /// [routineSlotCount] entries, true where you're usually on the move.
  final List<bool> movingSlots;

  /// Median speed while travelling, m/s — null if it never saw you move.
  final double? typicalSpeed;

  /// Median time of day (minutes) you stop travelling for the last time
  /// before 6 pm — "arrival time".
  final int? settledByMinute;

  /// Spots (~200 m cells) where you were still on at least 2 different days.
  final int familiarPlaces;
}

/// [samples] are (when, sample) pairs; only weekday 7 am – 6 pm ones are
/// used for the pattern, all of them for [RoutineSummary.daysLearned].
RoutineSummary summarizeRoutine(List<(DateTime, SentinelSample)> samples) {
  if (samples.isEmpty) return RoutineSummary.empty;

  final days = samples.map((e) => _dayKey(e.$1)).toSet();
  final weekday = samples
      .where((e) =>
          e.$2.weekday <= 5 && e.$2.minuteOfDay >= routineStartMinute && e.$2.minuteOfDay < routineEndMinute)
      .toList();

  final slotMoving = List.filled(routineSlotCount, 0);
  final slotTotal = List.filled(routineSlotCount, 0);
  final movingSpeeds = <double>[];
  final lastMoveByDay = <int, int>{};
  final stillDaysByCell = <String, Set<int>>{};

  for (final (at, s) in weekday) {
    final slot = (s.minuteOfDay - routineStartMinute) ~/ routineSlotMinutes;
    slotTotal[slot]++;
    final day = _dayKey(at);
    if (s.speed >= _movingSpeed) {
      slotMoving[slot]++;
      movingSpeeds.add(s.speed);
      if (s.minuteOfDay > (lastMoveByDay[day] ?? -1)) lastMoveByDay[day] = s.minuteOfDay;
    } else {
      // ~0.002° ≈ 200 m cells.
      final cell = '${(s.lat / 0.002).round()}:${(s.lng / 0.002).round()}';
      (stillDaysByCell[cell] ??= {}).add(day);
    }
  }

  return RoutineSummary(
    daysLearned: days.length,
    sampleCount: samples.length,
    movingSlots: [
      for (var i = 0; i < routineSlotCount; i++) slotTotal[i] > 0 && slotMoving[i] * 2 >= slotTotal[i],
    ],
    typicalSpeed: movingSpeeds.isEmpty ? null : _median(movingSpeeds),
    settledByMinute: lastMoveByDay.isEmpty
        ? null
        : _median(lastMoveByDay.values.map((m) => m.toDouble()).toList()).round(),
    familiarPlaces: stillDaysByCell.values.where((d) => d.length >= 2).length,
  );
}

int _dayKey(DateTime t) => t.year * 10000 + t.month * 100 + t.day;

double _median(List<double> values) {
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}
