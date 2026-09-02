import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../services/recording_service.dart';

enum RecordingTab { video, audio, photo }

class RecordingClip {
  const RecordingClip({required this.name, required this.meta, required this.icon, required this.localPath});

  final String name;
  final String meta;
  final IconData icon;
  final String localPath;
}

/// Real local capture — video/audio/photo files are saved on-device under
/// an `evidence/` folder (never uploaded), with only a lightweight
/// reference doc (type, local path, timestamp, duration/size) kept in
/// Firestore. See CLAUDE.md's evidence-storage decision. Every capture is
/// also indexed into the phone's shared media collections so it's easy to
/// find outside the app too — photos/videos via `gal` (Gallery), audio via
/// `media_store_plus` into Music/She Secure (Android's Gallery app itself
/// only indexes images/video, so a recording/music app is the audio
/// equivalent of "shows up in the phone's own app for that media type").
class RecordingsProvider extends ChangeNotifier {
  RecordingTab tab = RecordingTab.video;
  bool isRecording = false;
  int seconds = 0;
  Timer? _timer;

  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  CameraController? cameraController;
  bool cameraReady = false;
  final _audioRecorder = AudioRecorder();

  /// Set by the Recordings screen while mounted, so a capture failure
  /// (permission denied, no camera, disk error) surfaces as a SnackBar
  /// instead of silently doing nothing.
  void Function(String message)? onError;

  CollectionReference<Map<String, dynamic>>? _evidenceCollection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _evidenceSub;
  List<String> _docIds = const [];
  List<RecordingClip> clips = const [];

  bool get canSwitchCamera => _cameras.length > 1;

  void bindUser(String uid) {
    _evidenceSub?.cancel();
    _evidenceCollection = FirebaseFirestore.instance.collection('users').doc(uid).collection('evidence');
    _evidenceSub = _evidenceCollection!.orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      _docIds = snapshot.docs.map((d) => d.id).toList();
      clips = snapshot.docs.map((d) {
        final data = d.data();
        final type = data['type'] as String? ?? 'video';
        return RecordingClip(
          name: '${type[0].toUpperCase()}${type.substring(1)} · ${_formatWhen((data['timestamp'] as Timestamp?)?.toDate())}',
          meta: data['durationOrSize'] as String? ?? '',
          localPath: data['localPath'] as String? ?? '',
          icon: switch (type) {
            'audio' => Icons.mic_none_rounded,
            'photo' => Icons.image_outlined,
            _ => Icons.videocam_outlined,
          },
        );
      }).toList();
      notifyListeners();
    }, onError: (_) {});
  }

  void unbind() {
    _evidenceSub?.cancel();
    _evidenceSub = null;
    _evidenceCollection = null;
    _docIds = const [];
    clips = const [];
    disposeCamera();
  }

  /// Scoped to the Recordings screen's own lifecycle (called from its
  /// initState/dispose), not sign-in — holding a camera open app-wide
  /// just because a user is signed in would be wasteful and, worse, would
  /// prompt for camera permission before they ever open this screen.
  Future<void> initCamera() async {
    if (!await Permission.camera.request().isGranted) {
      onError?.call('Camera permission is off — turn it on in Settings to record video or take photos.');
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        onError?.call('No usable camera found on this device.');
        return;
      }
      _cameras = cameras;
      _cameraIndex = 0;
      await _openCamera();
    } catch (e) {
      onError?.call('Could not start the camera: $e');
    }
  }

  Future<void> _openCamera() async {
    final controller = CameraController(_cameras[_cameraIndex], ResolutionPreset.medium);
    await controller.initialize();
    cameraController = controller;
    cameraReady = true;
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (!canSwitchCamera || isRecording) return;
    cameraReady = false;
    notifyListeners();
    await cameraController?.dispose();
    cameraController = null;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    try {
      await _openCamera();
    } catch (e) {
      onError?.call('Could not switch camera: $e');
    }
  }

  void disposeCamera() {
    _timer?.cancel();
    isRecording = false;
    seconds = 0;
    cameraController?.dispose();
    cameraController = null;
    cameraReady = false;
    notifyListeners();
  }

  static String _formatWhen(DateTime? dt) {
    if (dt == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'pm' : 'am';
    return '${dt.day} ${months[dt.month - 1]}, $hour12:$minute $period';
  }

  static String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return minutes > 0 ? '$minutes min ${secs.toString().padLeft(2, '0')} s' : '$secs s';
  }

  void setTab(RecordingTab value) {
    tab = value;
    notifyListeners();
  }

  Future<void> toggleRecording() async {
    switch (tab) {
      case RecordingTab.photo:
        await _takePhoto();
      case RecordingTab.video:
        if (isRecording) {
          await _stopVideo();
        } else {
          await _startVideo();
        }
      case RecordingTab.audio:
        if (isRecording) {
          await _stopAudio();
        } else {
          await _startAudio();
        }
    }
  }

  Future<void> _takePhoto() async {
    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) {
      onError?.call('Camera isn\'t ready yet — try again in a moment.');
      return;
    }
    try {
      final shot = await controller.takePicture();
      final dir = await RecordingService.evidenceDirectory();
      final dest = '${dir.path}/${RecordingService.filePath('photo', 'jpg')}';
      await File(shot.path).copy(dest);
      final sizeBytes = await File(dest).length();
      await _bestEffort(() => _indexToMediaStore(dest, dirType: DirType.photo, dirName: DirName.pictures));
      await _saveReference(type: 'photo', localPath: dest, durationOrSize: RecordingService.formatBytes(sizeBytes));
    } catch (e) {
      onError?.call('Couldn\'t save the photo: $e');
    }
  }

  Future<void> _startVideo() async {
    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) {
      onError?.call('Camera isn\'t ready yet — try again in a moment.');
      return;
    }
    try {
      await controller.startVideoRecording();
      isRecording = true;
      seconds = 0;
      notifyListeners();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        seconds += 1;
        notifyListeners();
      });
    } catch (e) {
      onError?.call('Couldn\'t start recording: $e');
    }
  }

  Future<void> _stopVideo() async {
    _timer?.cancel();
    final controller = cameraController;
    final elapsed = seconds;
    isRecording = false;
    seconds = 0;
    notifyListeners();
    if (controller == null) return;
    try {
      final captured = await controller.stopVideoRecording();
      final dir = await RecordingService.evidenceDirectory();
      final dest = '${dir.path}/${RecordingService.filePath('video', 'mp4')}';
      await File(captured.path).copy(dest);
      final sizeBytes = await File(dest).length();
      await _bestEffort(() => _indexToMediaStore(dest, dirType: DirType.video, dirName: DirName.movies));
      await _saveReference(
        type: 'video',
        localPath: dest,
        durationOrSize: '${_formatDuration(elapsed)} · ${RecordingService.formatBytes(sizeBytes)}',
      );
    } catch (e) {
      onError?.call('Couldn\'t save the recording: $e');
    }
  }

  Future<void> _startAudio() async {
    if (!await _audioRecorder.hasPermission()) {
      onError?.call('Microphone permission is off — turn it on in Settings to record audio.');
      return;
    }
    try {
      final dir = await RecordingService.evidenceDirectory();
      final path = '${dir.path}/${RecordingService.filePath('audio', 'm4a')}';
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      isRecording = true;
      seconds = 0;
      notifyListeners();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        seconds += 1;
        notifyListeners();
      });
    } catch (e) {
      onError?.call('Couldn\'t start recording: $e');
    }
  }

  Future<void> _stopAudio() async {
    _timer?.cancel();
    final elapsed = seconds;
    isRecording = false;
    seconds = 0;
    notifyListeners();
    try {
      final path = await _audioRecorder.stop();
      if (path == null) return;
      final sizeBytes = await File(path).length();
      await _bestEffort(() => _indexToMediaStore(path, dirType: DirType.audio, dirName: DirName.music));
      await _saveReference(
        type: 'audio',
        localPath: path,
        durationOrSize: '${_formatDuration(elapsed)} · ${RecordingService.formatBytes(sizeBytes)}',
      );
    } catch (e) {
      onError?.call('Couldn\'t save the recording: $e');
    }
  }

  /// Best-effort — a Gallery-save failure (permission denied, no Gallery
  /// app, etc.) shouldn't block the app's own private copy from saving.
  Future<void> _bestEffort(Future<void> Function() save) async {
    try {
      await save();
    } catch (_) {}
  }

  /// Indexes a capture into the phone's shared Gallery/Music collections
  /// via `media_store_plus`, so it shows up outside the app too (photos in
  /// the Gallery app, video the same, audio in the phone's recordings/
  /// music app) — and, unlike `gal` (which has no delete API at all), can
  /// later be removed from there by [deleteClip].
  ///
  /// `MediaStore().saveFile` copies from `tempFilePath` and then *deletes*
  /// it (that's the whole point of the "temp" in the name) — so this
  /// always hands it a throwaway copy, never [localPath] itself. Passing
  /// the app's own evidence-folder file directly used to work for
  /// photo/video by accident (nothing else needed that path again) but
  /// broke audio outright: the file `RecordingClip.localPath` pointed at,
  /// and that "Open" used, was gone the moment this call returned.
  Future<void> _indexToMediaStore(String localPath, {required DirType dirType, required DirName dirName}) async {
    final tempDir = await getTemporaryDirectory();
    final tempCopy = '${tempDir.path}/${localPath.split('/').last}';
    await File(localPath).copy(tempCopy);
    await MediaStore().saveFile(tempFilePath: tempCopy, dirType: dirType, dirName: dirName);
  }

  static DirType _dirTypeFor(String type) => switch (type) {
        'photo' => DirType.photo,
        'video' => DirType.video,
        _ => DirType.audio,
      };

  static DirName _dirNameFor(String type) => switch (type) {
        'photo' => DirName.pictures,
        'video' => DirName.movies,
        _ => DirName.music,
      };

  Future<void> _saveReference({required String type, required String localPath, required String durationOrSize}) {
    final collection = _evidenceCollection;
    if (collection == null) return Future.value();
    return collection.add({
      'type': type,
      'localPath': localPath,
      'timestamp': FieldValue.serverTimestamp(),
      'durationOrSize': durationOrSize,
    });
  }

  /// Deletes the app's own private copy, its indexed copy in the shared
  /// Gallery/Music collection (best-effort — already-missing there is
  /// fine), and its Firestore reference.
  Future<void> deleteClip(int index) async {
    final collection = _evidenceCollection;
    if (collection == null || index >= _docIds.length) return;
    try {
      final doc = await collection.doc(_docIds[index]).get();
      final data = doc.data();
      final localPath = data?['localPath'] as String?;
      final type = data?['type'] as String? ?? 'video';
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) await file.delete();
        await _bestEffort(() => MediaStore().deleteFile(
              fileName: localPath.split('/').last,
              dirType: _dirTypeFor(type),
              dirName: _dirNameFor(type),
            ));
      }
      await collection.doc(_docIds[index]).delete();
    } catch (e) {
      onError?.call('Couldn\'t delete that file: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _evidenceSub?.cancel();
    cameraController?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
