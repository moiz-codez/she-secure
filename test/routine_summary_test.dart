import 'package:flutter_test/flutter_test.dart';
import 'package:she_secure/utils/routine_summary.dart';
import 'package:she_secure/utils/sentinel_heuristic.dart';

/// One weekday: still at home until 8:00, walking 8:00–8:30, still at
/// work until 17:00, walking home 17:00–17:30, still after.
List<(DateTime, SentinelSample)> _day(DateTime date) {
  final out = <(DateTime, SentinelSample)>[];
  for (var m = 7 * 60; m < 18 * 60; m += 15) {
    final moving = (m >= 480 && m < 510) || (m >= 1020 && m < 1050);
    final atWork = m >= 510 && m < 1020;
    out.add((
      date.add(Duration(minutes: m)),
      SentinelSample(
        weekday: date.weekday,
        minuteOfDay: m,
        lat: atWork ? 31.53 : 31.50,
        lng: atWork ? 74.36 : 74.33,
        speed: moving ? 1.4 : 0,
      ),
    ));
  }
  return out;
}

void main() {
  test('no samples: empty summary', () {
    final s = summarizeRoutine([]);
    expect(s.daysLearned, 0);
    expect(s.movingSlots, isEmpty);
  });

  test('two weekdays of a commute: pattern, pace, arrival, places', () {
    final samples = [..._day(DateTime(2026, 10, 5)), ..._day(DateTime(2026, 10, 6))]; // Mon, Tue
    final s = summarizeRoutine(samples);

    expect(s.daysLearned, 2);
    expect(s.movingSlots.length, routineSlotCount);
    // 8:00–8:30 is slot 2, 17:00–17:30 is slot 20; nothing else moves.
    expect([for (var i = 0; i < routineSlotCount; i++) if (s.movingSlots[i]) i], [2, 20]);
    expect(s.typicalSpeed, 1.4);
    expect(s.settledByMinute, 17 * 60 + 15); // last moving sample at 17:15
    expect(s.familiarPlaces, 2); // home + work, each seen on both days
  });

  test('weekend samples count as learned days but not the weekday pattern', () {
    final saturday = DateTime(2026, 10, 10);
    final s = summarizeRoutine(_day(saturday));
    expect(s.daysLearned, 1);
    expect(s.movingSlots.every((m) => !m), isTrue);
    expect(s.typicalSpeed, isNull);
  });
}
