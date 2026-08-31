import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

const _defaultFeatures = {
  'sos': true,
  'shake': true,
  'power': true,
  'location': true,
  'record': true,
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

  void bindUser(String uid) {
    _sub?.cancel();
    _doc = FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('preferences');
    _sub = _doc!.snapshots().listen((snap) {
      final data = snap.data();
      final stored = data?['features'] as Map<String, dynamic>?;
      features = stored == null
          ? Map.of(_defaultFeatures)
          : {for (final k in _defaultFeatures.keys) k: (stored[k] as bool?) ?? _defaultFeatures[k]!};
      notifyListeners();
    });
  }

  void unbind() {
    _sub?.cancel();
    _sub = null;
    _doc = null;
    features = Map.of(_defaultFeatures);
    notifyListeners();
  }

  void toggle(String key) {
    features[key] = !(features[key] ?? false);
    notifyListeners();
    _doc?.set({'features': features}, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
