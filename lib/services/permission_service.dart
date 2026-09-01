import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Requests every permission the app uses, back-to-back, in one place —
/// rather than each feature asking the first time it's touched, which
/// left users digging through Settings to grant things manually.
class PermissionService {
  PermissionService._();

  /// Returns the SMS permission's final status so the caller can offer
  /// help if it never got granted (see [showSmsRestrictedHelp]).
  static Future<PermissionStatus> requestAll() async {
    await Permission.locationWhenInUse.request();
    await Permission.contacts.request();
    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();
    return Permission.sms.request();
  }
}

/// Android 13+ blocks the SMS permission prompt entirely for apps
/// installed outside the Play Store ("Restricted settings"), until the
/// user manually allows it from the app's own system settings page.
/// Nothing in the app can grant this directly — this just gets the user
/// to the right place.
Future<void> showSmsRestrictedHelp(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A1C29),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SMS permission is blocked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          const Text(
            'Android blocks SMS access for apps installed outside the Play Store until you '
            'manually allow it:',
            style: TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFFB8B9C4)),
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Open Settings → Apps → She Secure\n'
            '2. Tap the ⋮ menu (top right) → "Allow restricted settings"\n'
            '3. Come back here and allow SMS again',
            style: TextStyle(fontSize: 13.5, height: 1.7, color: Color(0xFFB8B9C4)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                launchUrl(
                  Uri.parse('https://support.google.com/android/answer/12623953'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text('More about restricted settings'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
          ),
        ],
      ),
    ),
  );
}
