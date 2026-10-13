/// Decides whether one classifier window counts as a "hit", and whether
/// enough consecutive hits have now accumulated to fire — separate from
/// the actual on-device YAMNet inference so this stays unit-testable.
class ListenDecision {
  const ListenDecision({required this.isHit, required this.shouldFire});

  final bool isHit;
  final bool shouldFire;
}

/// [consecutiveHits] is the count going into this tick (before it).
/// Higher sensitivity needs a lower confidence and fewer consecutive
/// windows before firing — matches the screen's own copy ('Alert': a
/// raised voice or crying is enough; 'Relaxed': only a clear, sustained
/// scream fires).
ListenDecision checkScreamConfidence({
  required double confidence,
  required String sensitivity,
  required int consecutiveHits,
}) {
  // Windows overlap by half, so 2 consecutive = ~1.5 s of sound, 3 = ~2 s.
  // Tuned against real clips (CLAUDE.md, "YAMNet check"): no
  // non-distress clip scored above 0.33.
  final (threshold, needed) = switch (sensitivity) {
    'Alert' => (0.4, 1),
    'Relaxed' => (0.5, 3),
    _ => (0.4, 2),
  };
  final isHit = confidence >= threshold;
  final newCount = isHit ? consecutiveHits + 1 : 0;
  return ListenDecision(isHit: isHit, shouldFire: newCount >= needed);
}
