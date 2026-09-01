import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/sentinel_service.dart';

class SettingRow {
  const SettingRow({required this.key, required this.label, required this.sub});

  final String key;
  final String label;
  final String sub;
}

class PermissionRow {
  const PermissionRow({required this.key, required this.label, required this.sub, required this.granted});

  final String key;
  final String label;
  final String sub;
  final bool granted;
}

/// The one OS permission checked for each row — "Microphone and camera" is
/// reported via microphone alone since both gate on the same status once
/// Recordings/Distress Listening add their own manifest entries (phases 5-6).
const _permissionChecks = {
  'location': Permission.locationWhenInUse,
  'contacts': Permission.contacts,
  'mic_camera': Permission.microphone,
  'sms': Permission.sms,
  'battery': Permission.ignoreBatteryOptimizations,
};

const _defaultFeatures = {
  'sos': true,
  'shake': true,
  'power': true,
  'location': true,
  'fake': true,
  'sentinel': true,
  'listen': true,
};

/// Feature on/off toggles shown on the Settings screen, backed by the
/// `features` map on `users/{uid}/settings`. [SentinelProvider] and
/// [ListenProvider] read/write their own fields on that same document
/// independently — see their `bindUser`.
class SettingsProvider extends ChangeNotifier {
  Map<String, bool> features = Map.of(_defaultFeatures);
  DocumentReference<Map<String, dynamic>>? _doc;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;

  static const rows = [
    SettingRow(key: 'sos', label: 'SOS button', sub: 'The main emergency alert'),
    SettingRow(key: 'shake', label: 'Shake to alert', sub: 'A hard shake fires SOS'),
    SettingRow(key: 'power', label: 'Power button ×3', sub: 'Works with the screen locked'),
    SettingRow(key: 'location', label: 'Share live location', sub: 'Updates every ten seconds'),
    SettingRow(key: 'fake', label: 'Fake call', sub: 'Show it on the home screen'),
    SettingRow(key: 'sentinel', label: 'Smart Sentinel', sub: 'Learns your routine and checks on you'),
    SettingRow(key: 'listen', label: 'Distress listening', sub: 'Fires an alert on a scream'),
  ];

  static const _permissionLabels = {
    'location': ('Location', 'Needed to share where you are'),
    'contacts': ('Contacts', 'Needed to pick trusted contacts'),
    'mic_camera': ('Microphone and camera', 'Needed for recordings and distress listening'),
    'sms': ('SMS', 'Needed to alert your contacts'),
    'battery': ('Battery optimization', 'Needed so the OS doesn\'t stop Sentinel/Listen in the background'),
  };

  Map<String, bool> _permGranted = {for (final k in _permissionChecks.keys) k: false};

  List<PermissionRow> get permissions => [
        for (final k in _permissionChecks.keys)
          PermissionRow(
            key: k,
            label: _permissionLabels[k]!.$1,
            sub: (_permGranted[k] ?? false) ? 'Allowed' : _permissionLabels[k]!.$2,
            granted: _permGranted[k] ?? false,
          ),
      ];

  Future<void> refreshPermissions() async {
    final result = <String, bool>{};
    for (final entry in _permissionChecks.entries) {
      result[entry.key] = await entry.value.status.isGranted;
    }
    _permGranted = result;
    notifyListeners();
  }

  Future<void> requestPermission(String key) async {
    final permission = _permissionChecks[key];
    if (permission == null) return;
    await permission.request();
    await refreshPermissions();
  }

  bool isOn(String key) => features[key] ?? false;

  void bindUser(String uid) {
    _uid = uid;
    _sub?.cancel();
    _doc = FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('preferences');
    _sub = _doc!.snapshots().listen((snap) {
      final data = snap.data();
      final stored = data?['features'] as Map<String, dynamic>?;
      features = stored == null
          ? Map.of(_defaultFeatures)
          : {for (final k in _defaultFeatures.keys) k: (stored[k] as bool?) ?? _defaultFeatures[k]!};
      notifyListeners();
      _pushShortcutConfig();
    });
  }

  void unbind() {
    _sub?.cancel();
    _sub = null;
    _doc = null;
    _uid = null;
    features = Map.of(_defaultFeatures);
    notifyListeners();
  }

  void toggle(String key) {
    features[key] = !(features[key] ?? false);
    notifyListeners();
    _doc?.set({'features': features}, SetOptions(merge: true));
  }

  /// Shake-to-alert and Power button ×3 run in the shared background
  /// service (like Sentinel/Listen) so they still work with the screen
  /// locked — pushed here, from whichever settings change touches them,
  /// rather than needing a dedicated screen/provider of their own.
  Future<void> _pushShortcutConfig() async {
    if (_uid == null) return;
    final shakeOn = isOn('shake');
    final powerOn = isOn('power');
    await pushBackgroundConfig(
      {'uid': _uid, 'shakeOn': shakeOn, 'powerButtonOn': powerOn},
      needed: shakeOn || powerOn,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
