import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../services/recording_service.dart';

enum RecordingTab { video, audio, photo }

class RecordingClip {
  const RecordingClip({required this.name, required this.meta, required this.icon});

  final String name;
  final String meta;
  final IconData icon;
}

/// Real local capture — video/audio/photo files are saved on-device under
/// an `evidence/` folder (never uploaded), with only a lightweight
/// reference doc (type, local path, timestamp, duration/size) kept in
/// Firestore. See CLAUDE.md's evidence-storage decision.
class RecordingsProvider extends ChangeNotifier {
  RecordingTab tab = RecordingTab.video;
  bool isRecording = false;
  int seconds = 0;
  Timer? _timer;

  CameraController? cameraController;
  bool cameraReady = false;
  final _audioRecorder = AudioRecorder();

  CollectionReference<Map<String, dynamic>>? _evidenceCollection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _evidenceSub;
  List<RecordingClip> clips = const [];

  void bindUser(String uid) {
    _evidenceSub?.cancel();
    _evidenceCollection = FirebaseFirestore.instance.collection('users').doc(uid).collection('evidence');
    _evidenceSub = _evidenceCollection!.orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      clips = snapshot.docs.map((d) {
        final data = d.data();
        final type = data['type'] as String? ?? 'video';
        return RecordingClip(
          name: '${type[0].toUpperCase()}${type.substring(1)} · ${_formatWhen((data['timestamp'] as Timestamp?)?.toDate())}',
          meta: data['durationOrSize'] as String? ?? '',
          icon: switch (type) {
            'audio' => Icons.mic_none_rounded,
            'photo' => Icons.image_outlined,
            _ => Icons.videocam_outlined,
          },
        );
      }).toList();
      notifyListeners();
    });
  }

  void unbind() {
    _evidenceSub?.cancel();
    _evidenceSub = null;
    _evidenceCollection = null;
    clips = const [];
    disposeCamera();
  }

  /// Scoped to the Recordings screen's own lifecycle (called from its
  /// initState/dispose), not sign-in — holding a camera open app-wide
  /// just because a user is signed in would be wasteful and, worse, would
  /// prompt for camera permission before they ever open this screen.
  Future<void> initCamera() async {
    if (!await Permission.camera.request().isGranted) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final controller = CameraController(cameras.first, ResolutionPreset.medium);
      await controller.initialize();
      cameraController = controller;
      cameraReady = true;
      notifyListeners();
    } catch (_) {
      // No usable camera (emulator without one, permission race, etc.) —
      // the preview just stays on its placeholder; capture buttons for
      // video/photo are disabled below rather than crashing on tap.
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
    if (controller == null || !controller.value.isInitialized) return;
    final shot = await controller.takePicture();
    final dir = await RecordingService.evidenceDirectory();
    final dest = '${dir.path}/${RecordingService.filePath('photo', 'jpg')}';
    await File(shot.path).copy(dest);
    final sizeBytes = await File(dest).length();
    await _saveReference(type: 'photo', localPath: dest, durationOrSize: RecordingService.formatBytes(sizeBytes));
  }

  Future<void> _startVideo() async {
    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.startVideoRecording();
    isRecording = true;
    seconds = 0;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds += 1;
      notifyListeners();
    });
  }

  Future<void> _stopVideo() async {
    _timer?.cancel();
    final controller = cameraController;
    final elapsed = seconds;
    isRecording = false;
    seconds = 0;
    notifyListeners();
    if (controller == null) return;
    final captured = await controller.stopVideoRecording();
    final dir = await RecordingService.evidenceDirectory();
    final dest = '${dir.path}/${RecordingService.filePath('video', 'mp4')}';
    await File(captured.path).copy(dest);
    final sizeBytes = await File(dest).length();
    await _saveReference(
      type: 'video',
      localPath: dest,
      durationOrSize: '${_formatDuration(elapsed)} · ${RecordingService.formatBytes(sizeBytes)}',
    );
  }

  Future<void> _startAudio() async {
    if (!await _audioRecorder.hasPermission()) return;
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
  }

  Future<void> _stopAudio() async {
    _timer?.cancel();
    final elapsed = seconds;
    isRecording = false;
    seconds = 0;
    notifyListeners();
    final path = await _audioRecorder.stop();
    if (path == null) return;
    final sizeBytes = await File(path).length();
    await _saveReference(
      type: 'audio',
      localPath: path,
      durationOrSize: '${_formatDuration(elapsed)} · ${RecordingService.formatBytes(sizeBytes)}',
    );
  }

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

  @override
  void dispose() {
    _timer?.cancel();
    _evidenceSub?.cancel();
    cameraController?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
