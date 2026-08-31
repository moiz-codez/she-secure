import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/sos_event.dart';
import '../utils/formatters.dart';

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

  List<SosHistoryEntry> history = const [];
  CollectionReference<Map<String, dynamic>>? _historyCollection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySub;

  void bindUser(String uid) {
    _historySub?.cancel();
    _historyCollection = FirebaseFirestore.instance.collection('users').doc(uid).collection('sosHistory');
    _historySub = _historyCollection!.orderBy('when', descending: true).snapshots().listen((snapshot) {
      history = snapshot.docs.map((d) {
        final data = d.data();
        return SosHistoryEntry(
          where: data['where'] as String? ?? 'Unknown location',
          when: _formatWhen((data['when'] as Timestamp?)?.toDate()),
          detail: data['detail'] as String? ?? '',
        );
      }).toList();
      notifyListeners();
    });
  }

  void unbind() {
    _historySub?.cancel();
    _historySub = null;
    _historyCollection = null;
    history = const [];
    notifyListeners();
  }

  static String _formatWhen(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'pm' : 'am';
    return '${dt.day} ${months[dt.month - 1]}, $hour12:$minute $period';
  }

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

  DocumentReference<Map<String, dynamic>>? _activeHistoryDoc;

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

    // Real location (instead of this placeholder) and actual SMS delivery
    // land in the native-integrations phase; the history record itself is
    // real starting now.
    _historyCollection
        ?.add({'where': 'Location pending (native integration not wired up yet)', 'when': FieldValue.serverTimestamp(), 'detail': 'Alert sent'})
        .then((doc) => _activeHistoryDoc = doc);
  }

  void cancel() {
    _countdownTimer?.cancel();
    _elapsedTimer?.cancel();
    if (_activeHistoryDoc != null) {
      final wasArmed = state == SosState.armed;
      _activeHistoryDoc!.update({
        'detail': wasArmed ? 'Cancelled after ${formatMmSs(elapsed)}' : 'Cancelled before sending',
      });
      _activeHistoryDoc = null;
    }
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
    _historySub?.cancel();
    super.dispose();
  }
}
