import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/sos_event.dart';
import '../services/location_service.dart';
import '../services/sms_service.dart';
import '../utils/formatters.dart';
import 'contacts_provider.dart';

enum SosState { idle, counting, armed }

/// Drives the SOS alert lifecycle: idle -> counting (5s, cancellable) ->
/// armed (live until stopped). Ports the design canvas's `sos`/`count`/
/// `elapsed` state 1:1; the press-and-hold *progress* itself is
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

  Timer? _countdownTimer;
  Timer? _elapsedTimer;

  List<SosHistoryEntry> history = const [];
  CollectionReference<Map<String, dynamic>>? _historyCollection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySub;
  StreamSubscription<Map<String, dynamic>?>? _shortcutSub;

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
    // Shake / power-button ×3 fire directly from the background service
    // (no dedicated foreground screen owns them) — this just reflects the
    // resulting armed state here if the app happens to be open, same as
    // Sentinel/Listen's own escalation events.
    _shortcutSub ??= FlutterBackgroundService().on('shortcutFired').listen((_) => markArmedExternally());
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

  /// Reflects an alert that was already sent elsewhere — Smart Sentinel's
  /// background service fires its own real location+SMS send directly
  /// (it runs in a separate isolate with no access to this instance), then
  /// calls this just so the SOS screen shows "armed" if the app happens to
  /// be open. Unlike [arm], this never re-sends anything.
  void markArmedExternally() {
    _countdownTimer?.cancel();
    state = SosState.armed;
    elapsed = 0;
    notifyListeners();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed += 1;
      notifyListeners();
    });
  }

  /// Arms the alert immediately, skipping the hold+countdown — used by
  /// Smart Sentinel's auto-escalation and Distress Listening's
  /// no-confirmation trigger.
  Future<void> arm() async {
    _countdownTimer?.cancel();
    state = SosState.armed;
    elapsed = 0;
    notifyListeners();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed += 1;
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
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _elapsedTimer?.cancel();
    _historySub?.cancel();
    _shortcutSub?.cancel();
    super.dispose();
  }
}
