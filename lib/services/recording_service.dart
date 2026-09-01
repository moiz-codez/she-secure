import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Local-only evidence storage — captured files never leave the phone
/// (see CLAUDE.md's evidence-storage decision). Firestore only ever holds
/// a lightweight reference doc alongside them, written by whichever
/// provider does the capturing.
class RecordingService {
  static Directory? _evidenceDir;

  static Future<Directory> evidenceDirectory() async {
    final cached = _evidenceDir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/evidence');
    if (!await dir.exists()) await dir.create(recursive: true);
    _evidenceDir = dir;
    return dir;
  }

  static String filePath(String prefix, String extension) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$stamp.$extension';
  }

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}
