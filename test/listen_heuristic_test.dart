// Unit tests for the Distress Listening confidence/streak decision — pure
// logic, no interpreter or mic involved.

import 'package:flutter_test/flutter_test.dart';
import 'package:she_secure/utils/listen_heuristic.dart';

void main() {
  test('Balanced: below threshold is never a hit', () {
    final result = checkScreamConfidence(confidence: 0.3, sensitivity: 'Balanced', consecutiveHits: 0);
    expect(result.isHit, false);
    expect(result.shouldFire, false);
  });

  test('Balanced: a single hit is not enough (needs 2 consecutive)', () {
    final result = checkScreamConfidence(confidence: 0.7, sensitivity: 'Balanced', consecutiveHits: 0);
    expect(result.isHit, true);
    expect(result.shouldFire, false);
  });

  test('Balanced: second consecutive hit fires', () {
    final result = checkScreamConfidence(confidence: 0.7, sensitivity: 'Balanced', consecutiveHits: 1);
    expect(result.isHit, true);
    expect(result.shouldFire, true);
  });

  test('Alert: a single hit is enough', () {
    final result = checkScreamConfidence(confidence: 0.45, sensitivity: 'Alert', consecutiveHits: 0);
    expect(result.shouldFire, true);
  });

  test('Relaxed: two consecutive hits are not enough (needs 3)', () {
    final result = checkScreamConfidence(confidence: 0.7, sensitivity: 'Relaxed', consecutiveHits: 1);
    expect(result.isHit, true);
    expect(result.shouldFire, false);
  });

  test('Relaxed: third consecutive hit fires', () {
    final result = checkScreamConfidence(confidence: 0.7, sensitivity: 'Relaxed', consecutiveHits: 2);
    expect(result.shouldFire, true);
  });

  test('Relaxed: a miss resets the streak, even at high confidence next tick', () {
    final miss = checkScreamConfidence(confidence: 0.5, sensitivity: 'Relaxed', consecutiveHits: 2);
    expect(miss.isHit, false, reason: '0.5 is below Relaxed\'s 0.65 threshold');
    final recovered = checkScreamConfidence(confidence: 0.9, sensitivity: 'Relaxed', consecutiveHits: 0);
    expect(recovered.shouldFire, false, reason: 'streak restarts from zero after the miss');
  });
}
