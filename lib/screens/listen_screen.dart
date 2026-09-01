import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/listen_provider.dart';
import '../theme/app_colors.dart';

const _earOptions = ['Relaxed', 'Balanced', 'Alert'];

class ListenScreen extends StatefulWidget {
  const ListenScreen({super.key});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  @override
  void initState() {
    super.initState();
    final listen = context.read<ListenProvider>();
    listen.onDetectionEscalated = () {
      if (mounted) Navigator.of(context).pushReplacementNamed(Routes.sos);
    };
  }

  @override
  void dispose() {
    context.read<ListenProvider>().onDetectionEscalated = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listen = context.watch<ListenProvider>();

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
                  const Text('Distress listening', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.accentTint(0.07),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.accentTint(0.28)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.graphic_eq_rounded, size: 24, color: AppColors.accentLight),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(listen.statusLabel, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                                Text('On device · nothing leaves your phone', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.5))),
                              ],
                            ),
                          ),
                          Switch(value: listen.listenOn, onChanged: (_) => listen.toggle()),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Container(
                        height: 132,
                        decoration: BoxDecoration(color: AppColors.surfaceDim, border: Border.all(color: AppColors.textMuted(0.08))),
                        alignment: Alignment.center,
                        child: listen.detected ? const _DetectedIndicator() : const _WaveformIndicator(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('For when you cannot reach the button', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.44)),
                        const SizedBox(height: 8),
                        Text(
                          'The microphone listens for a scream or sustained crying. It fires the alert '
                          'straight away, without asking, because in that moment nobody can tap anything.',
                          style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted(0.55)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: const [
                        _Tag(icon: Icons.campaign_outlined, label: 'Screams'),
                        _Tag(icon: Icons.water_drop_outlined, label: 'Sustained crying'),
                        _Tag(icon: Icons.front_hand_outlined, label: 'Calls for help'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SENSITIVITY', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                        const SizedBox(height: 10),
                        SegmentedButton<String>(
                          segments: [for (final o in _earOptions) ButtonSegment(value: o, label: Text(o))],
                          selected: {listen.earSensitivity},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => listen.setSensitivity(s.first),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(listen.sensitivityNote, style: TextStyle(fontSize: 11.5, height: 1.55, color: AppColors.textMuted(0.48))),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted(0.035),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.textMuted(0.07)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.accentLight),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nothing is recorded while it listens', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(
                                  'Sound is matched on the phone and thrown away. Audio is only saved once an '
                                  'alert fires, and only on your phone.',
                                  style: TextStyle(fontSize: 11.5, height: 1.55, color: AppColors.textMuted(0.5)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHAT IT HEARD', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                        for (final h in ListenProvider.heard)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.07)))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(Icons.hearing_rounded, size: 17, color: AppColors.accentLight),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h.what, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                                      Text('${h.when} · ${h.how}', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: listen.simulate,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted(0.78),
                          side: BorderSide(color: AppColors.textMuted(0.24)),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.play_circle_outline_rounded, size: 17),
                        label: const Text('Simulate a detected scream', style: TextStyle(fontSize: 13.5)),
                      ),
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

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: AppColors.textMuted(0.06), borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accentLight),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.75))),
        ],
      ),
    );
  }
}

class _WaveformIndicator extends StatefulWidget {
  const _WaveformIndicator();

  @override
  State<_WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<_WaveformIndicator> with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(14, (i) {
            final phase = _controller.value + i * (0.09 / 1.3);
            final wave = (math.sin(2 * math.pi * phase) + 1) / 2;
            final scaleY = 0.22 + wave * 0.78;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox(
                width: 4,
                height: 62,
                child: Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    heightFactor: scaleY,
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.accentTint(0.75), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _DetectedIndicator extends StatelessWidget {
  const _DetectedIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.campaign_rounded, size: 32, color: AppColors.accent),
        const SizedBox(height: 9),
        Text('Scream detected', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.accentPale)),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text('Sending the alert — no confirmation needed', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.5))),
        ),
      ],
    );
  }
}
