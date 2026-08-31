import 'package:flutter/foundation.dart';

class SettingRow {
  const SettingRow({required this.key, required this.label, required this.sub});

  final String key;
  final String label;
  final String sub;
}

class PermissionRow {
  const PermissionRow({required this.label, required this.sub, required this.granted});

  final String label;
  final String sub;
  final bool granted;
}

/// Feature on/off toggles shown on the Settings screen. Backed by
/// Firestore from Phase 2 onward; local-only for now.
class SettingsProvider extends ChangeNotifier {
  final Map<String, bool> features = {
    'sos': true,
    'shake': true,
    'power': true,
    'location': true,
    'record': true,
    'fake': true,
    'sentinel': true,
    'listen': true,
  };

  static const rows = [
    SettingRow(key: 'sos', label: 'SOS button', sub: 'The main emergency alert'),
    SettingRow(key: 'shake', label: 'Shake to alert', sub: 'A hard shake fires SOS'),
    SettingRow(key: 'power', label: 'Power button ×3', sub: 'Works with the screen locked'),
    SettingRow(key: 'location', label: 'Share live location', sub: 'Updates every ten seconds'),
    SettingRow(key: 'record', label: 'Auto-record on SOS', sub: 'Starts audio when an alert fires'),
    SettingRow(key: 'fake', label: 'Fake call', sub: 'Show it on the home screen'),
    SettingRow(key: 'sentinel', label: 'Smart Sentinel', sub: 'Learns your routine and checks on you'),
    SettingRow(key: 'listen', label: 'Distress listening', sub: 'Fires an alert on a scream'),
  ];

  static const permissions = [
    PermissionRow(label: 'Location', sub: 'Allow all the time', granted: true),
    PermissionRow(label: 'Contacts', sub: 'Allowed', granted: true),
    PermissionRow(label: 'Microphone and camera', sub: 'Allowed', granted: true),
    PermissionRow(label: 'SMS', sub: 'Not allowed yet', granted: false),
  ];

  bool isOn(String key) => features[key] ?? false;

  void toggle(String key) {
    features[key] = !(features[key] ?? false);
    notifyListeners();
  }
}
