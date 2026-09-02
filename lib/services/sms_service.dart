import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

/// Real silent SMS send via Android's SmsManager — no compose sheet, no
/// user tap. Only safe to do without Play Store's Permissions Declaration
/// Form because this app is APK-sideload only (see CLAUDE.md).
class SmsService {
  static final _telephony = Telephony.instance;

  /// Sends [message] to every number in [numbers]. Returns false if SMS
  /// permission was denied; otherwise attempts every contact and returns
  /// true. Each send is wrapped individually — `sendSms` throws a
  /// `PlatformException` for a single malformed/unreachable number (a
  /// contact saved without a country code, for example), and an uncaught
  /// throw here would abort the loop and silently skip every contact after
  /// the bad one. One contact failing to send must never stop the rest.
  static Future<bool> sendToAll(List<String> numbers, String message) async {
    if (numbers.isEmpty) return true;
    final status = await Permission.sms.request();
    if (!status.isGranted) return false;
    for (final number in numbers) {
      try {
        await _telephony.sendSms(to: number, message: message);
      } catch (_) {
        // Best-effort per contact — keep going so one bad number doesn't
        // take the rest of the broadcast down with it.
      }
    }
    return true;
  }
}
