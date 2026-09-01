import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// The app's own profile-photo copy — deterministic per-install path, so
/// both the Profile screen and the Home drawer can just check whether the
/// file exists rather than needing a Firestore round-trip to find it.
class ProfilePhotoService {
  ProfilePhotoService._();

  static Future<String> path() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/profile');
    if (!await dir.exists()) await dir.create(recursive: true);
    return '${dir.path}/photo.jpg';
  }
}
