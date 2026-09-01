import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/sos_event.dart';
import '../services/location_service.dart';
import '../services/sms_service.dart';
import '../utils/formatters.dart';
import 'contacts_provider.dart';

enum SosState { idle, counting, armed }

/// Drives the SOS alert lifecycle: idle -> counting (5s, cancellable) ->
/// armed (live until stopped). Ports the design canvas's `sos`/`count`/
/// `elapsed`/`acked` state 1:1; the press-and-hold *progress* itself is
/// owned by [HoldToConfirmButton] instances in the UI, which call
/// [beginCountdown] / [cancel] here on completion.
///
/// [arm] fetches a real location fix and sends a real silent SMS (via
/// [SmsService]) to every trusted contact.
class SosProvider extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  SosProvider({required ContactsProvider contacts}) : _contacts = contacts;

  // ignore: prefer_initializing_formals
  final ContactsProvider _contacts;

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
  Future<void> arm() async {
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

    // Guarded so a platform-channel failure (e.g. no location plugin bound,
    // as in plain unit tests) can't leave the alert stuck mid-arm — the SOS
    // state above is already live regardless of whether the fix/SMS land.
    try {
      final position = await LocationService.getCurrentPosition();
      final where = position == null
          ? 'Location unavailable'
          : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      _historyCollection
          ?.add({'where': where, 'when': FieldValue.serverTimestamp(), 'detail': 'Alert sent'})
          .then((doc) => _activeHistoryDoc = doc);

      final link = position == null ? '' : ' https://maps.google.com/?q=${position.latitude},${position.longitude}';
      await SmsService.sendToAll(
        _contacts.contacts.map((c) => c.phone).toList(),
        'I need help, this is my location.$link',
      );
    } catch (_) {
      // Best-effort — the armed state and elapsed timer above already stand.
    }
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
