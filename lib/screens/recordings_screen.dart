import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/recordings_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/status_pill.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RecordingsProvider>().initCamera();
  }

  @override
  void dispose() {
    context.read<RecordingsProvider>().disposeCamera();
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
                            if (recordings.cameraReady && recordings.cameraController != null)
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SAVED ON THIS PHONE', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                        Text('30 MB used', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.4))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        for (final clip in recordings.clips)
                          Container(
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
                                  child: Icon(clip.icon, size: 16, color: AppColors.textMuted(0.4)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(clip.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                      Text(clip.meta, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => showNotBuiltSnack(context),
                                  icon: Icon(Icons.more_vert_rounded, size: 17, color: AppColors.textMuted(0.4)),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Nothing is uploaded. Files stay on the phone until you share them yourself.',
                              style: TextStyle(fontSize: 11.5, height: 1.55, color: AppColors.textMuted(0.4)),
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
