import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

/// Real silent SMS send via Android's SmsManager — no compose sheet, no
/// user tap. Only safe to do without Play Store's Permissions Declaration
/// Form because this app is APK-sideload only (see CLAUDE.md).
class SmsService {
  static final _telephony = Telephony.instance;

  /// Sends [message] to every number in [numbers]. Returns false if SMS
  /// permission was denied; otherwise fires each send and returns true
  /// (individual per-number failures aren't awaited/reported — this is a
  /// best-effort broadcast, matching the SOS button's own semantics).
  static Future<bool> sendToAll(List<String> numbers, String message) async {
    if (numbers.isEmpty) return true;
    final status = await Permission.sms.request();
    if (!status.isGranted) return false;
    for (final number in numbers) {
      await _telephony.sendSms(to: number, message: message);
    }
    return true;
  }
}
