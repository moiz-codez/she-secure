import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps geolocator behind a single call. Returns null if the user denies
/// location permission or location services are off, rather than throwing.
class LocationService {
  static Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return null;
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
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return;
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    );
  }
}
