import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sos_event.dart';

enum SosState { idle, counting, armed }

/// Drives the SOS alert lifecycle: idle -> counting (5s, cancellable) ->
/// armed (live until stopped). Ports the design canvas's `sos`/`count`/
/// `elapsed`/`acked` state 1:1; the press-and-hold *progress* itself is
/// owned by [HoldToConfirmButton] instances in the UI, which call
/// [beginCountdown] / [cancel] here on completion.
///
/// Real SMS delivery is wired in during the native-integrations phase —
/// for now [arm] just starts the local "who's been notified" simulation
/// so the rest of the SOS screen is fully exercisable.
class SosProvider extends ChangeNotifier {
  SosState state = SosState.idle;
  int count = 5;
  int elapsed = 0;
  int acked = 0;

  Timer? _countdownTimer;
  Timer? _elapsedTimer;

  final List<SosHistoryEntry> history = const [
    SosHistoryEntry(
      where: 'Near Gulshan-e-Iqbal Block 5',
      when: '12 Aug, 9:41 pm',
      detail: '4 contacts reached · cancelled after 2 min',
    ),
    SosHistoryEntry(
      where: 'Shahrah-e-Faisal, near Nursery',
      when: '28 Jul, 7:12 pm',
      detail: '3 contacts reached · Ammi called back',
    ),
    SosHistoryEntry(where: 'Test alert', when: '14 Jul, 4:03 pm', detail: 'Practice run · no message sent'),
  ];

  void beginCountdown() {
    if (state != SosState.idle) return;
    state = SosState.counting;
    count = 5;
    notifyListeners();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      count -= 1;
      if (count <= 0) {
        timer.cancel();
        arm();
      } else {
        notifyListeners();
      }
    });
  }

  /// Arms the alert immediately, skipping the hold+countdown — used by
  /// Smart Sentinel's auto-escalation and Distress Listening's
  /// no-confirmation trigger.
  void arm() {
    _countdownTimer?.cancel();
    state = SosState.armed;
    elapsed = 0;
    acked = 0;
    notifyListeners();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed += 1;
      if (elapsed == 3) acked = 1;
      if (elapsed == 6) acked = 2;
      if (elapsed == 11) acked = 3;
      notifyListeners();
    });
  }

  void cancel() {
    _countdownTimer?.cancel();
    _elapsedTimer?.cancel();
    state = SosState.idle;
    count = 5;
    elapsed = 0;
    acked = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }
}
