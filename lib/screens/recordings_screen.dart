import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../providers/recordings_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

Future<void> _openClip(BuildContext context, RecordingClip clip) async {
  if (clip.localPath.isEmpty) return;
  final result = await OpenFilex.open(clip.localPath);
  if (result.type != ResultType.done && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
  }
}

Future<void> _confirmDelete(BuildContext context, RecordingsProvider recordings, int index) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Delete this file?'),
      content: const Text('This removes it from She Secure and your phone. This can\'t be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Delete', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  if (confirmed == true) await recordings.deleteClip(index);
}

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  @override
  void initState() {
    super.initState();
    final recordings = context.read<RecordingsProvider>();
    recordings.onError = (message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    };
    recordings.initCamera();
  }

  @override
  void dispose() {
    final recordings = context.read<RecordingsProvider>();
    recordings.onError = null;
    recordings.disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordings = context.watch<RecordingsProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 21, color: AppColors.text),
                  ),
                  const Text('Recordings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 26),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.textMuted(0.05), borderRadius: BorderRadius.circular(11)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'Video',
                              active: recordings.tab == RecordingTab.video,
                              onTap: () => recordings.setTab(RecordingTab.video),
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              label: 'Audio',
                              active: recordings.tab == RecordingTab.audio,
                              onTap: () => recordings.setTab(RecordingTab.audio),
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              label: 'Photo',
                              active: recordings.tab == RecordingTab.photo,
                              onTap: () => recordings.setTab(RecordingTab.photo),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 216,
                        decoration: BoxDecoration(color: AppColors.surfaceDim, border: Border.all(color: AppColors.textMuted(0.09))),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (recordings.tab == RecordingTab.audio)
                              Center(
                                child: _AudioIndicator(active: recordings.isRecording),
                              )
                            else if (recordings.cameraReady && recordings.cameraController != null)
                              Positioned.fill(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: recordings.cameraController!.value.previewSize?.height ?? 1,
                                    height: recordings.cameraController!.value.previewSize?.width ?? 1,
                                    child: CameraPreview(recordings.cameraController!),
                                  ),
                                ),
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cameraswitch_outlined, size: 34, color: AppColors.textMuted(0.22)),
                                  const SizedBox(height: 9),
                                  Text(
                                    'CAMERA PREVIEW',
                                    style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: AppColors.textMuted(0.26)),
                                  ),
                                ],
                              ),
                            if (recordings.isRecording)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTint(0.2),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppColors.accentTint(0.45)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                                      const SizedBox(width: 7),
                                      Text(
                                        formatMmSs(recordings.seconds),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.accentPale),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (recordings.tab != RecordingTab.audio && recordings.canSwitchCamera && !recordings.isRecording)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: recordings.switchCamera,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                                    child: const Icon(Icons.cameraswitch_outlined, size: 17, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: recordings.toggleRecording,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.textMuted(0.22), width: 3)),
                            alignment: Alignment.center,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: recordings.isRecording ? 34 : 62,
                              height: recordings.isRecording ? 34 : 62,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(recordings.isRecording ? 7 : 31),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        Text(
                          recordings.isRecording
                              ? 'Tap to stop and save'
                              : recordings.tab == RecordingTab.photo
                                  ? 'Tap to take a photo'
                                  : 'Tap to start recording',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.5)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 6),
                    child: Text('SAVED ON THIS PHONE', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        for (var i = 0; i < recordings.clips.length; i++)
                          InkWell(
                            onTap: () => _openClip(context, recordings.clips[i]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.07)))),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.textMuted(0.08)),
                                    ),
                                    child: Icon(recordings.clips[i].icon, size: 16, color: AppColors.textMuted(0.4)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(recordings.clips[i].name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        Text(recordings.clips[i].meta, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45))),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _confirmDelete(context, recordings, i),
                                    icon: Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.textMuted(0.4)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioIndicator extends StatefulWidget {
  const _AudioIndicator({required this.active});

  final bool active;

  @override
  State<_AudioIndicator> createState() => _AudioIndicatorState();
}

class _AudioIndicatorState extends State<_AudioIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.active ? Icons.mic_rounded : Icons.mic_none_rounded,
          size: 34,
          color: widget.active ? AppColors.accentLight : AppColors.textMuted(0.3),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(16, (i) {
                final phase = _controller.value + i * (0.09 / 1.3);
                final wave = widget.active ? (math.sin(2 * math.pi * phase) + 1) / 2 : 0.15;
                final scaleY = 0.15 + wave * 0.85;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: SizedBox(
                    width: 4,
                    height: 46,
                    child: Align(
                      alignment: Alignment.center,
                      child: FractionallySizedBox(
                        heightFactor: scaleY,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.active ? AppColors.accentTint(0.75) : AppColors.textMuted(0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active ? AppColors.accentTint(0.14) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
            color: active ? AppColors.accentPale : AppColors.textMuted(0.55),
          ),
        ),
      ),
    );
  }
}
