import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_service.dart';

/// Wraps geolocator behind a single call. Returns null if the user denies
/// location permission or location services are off, rather than throwing.
class LocationService {
  /// The Settings "Share live location" switch — when off, alerts go out
  /// without a location fix or Maps link. Defaults to on if unreadable.
  static Future<bool> sharingOn(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('preferences').get();
      return (doc.data()?['features'] as Map<String, dynamic>?)?['location'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  /// [getCurrentPosition], or null when [uid] has location sharing off.
  static Future<Position?> positionForAlert(String uid) async =>
      await sharingOn(uid) ? getCurrentPosition() : null;

  static Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    if (!await ensurePermission(Permission.locationWhenInUse)) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  /// A continuous fix, not a single snapshot — the Location screen's pin
  /// (and the "accurate to Xm" reading) should track you as you move, the
  /// same way any real map app's live location does. Emits a new [Position]
  /// roughly every 5m of movement; yields nothing if permission is denied
  /// or location services are off.
  static Stream<Position> watchPosition() async* {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    if (!await ensurePermission(Permission.locationWhenInUse)) return;
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    );
  }
}
