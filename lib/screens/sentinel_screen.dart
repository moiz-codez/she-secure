import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/sentinel_provider.dart';
import '../theme/app_colors.dart';

const _sensOptions = ['Relaxed', 'Balanced', 'Alert'];

class SentinelScreen extends StatelessWidget {
  const SentinelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sentinel = context.watch<SentinelProvider>();

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
                  const Text('Smart Sentinel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16)),
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
                          Icon(Icons.psychology_alt_rounded, size: 24, color: AppColors.accentLight),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sentinel.statusLabel, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                                Text('Runs in the background. You do nothing.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.5))),
                              ],
                            ),
                          ),
                          Switch(value: sentinel.sentinelOn, onChanged: (_) => sentinel.toggle()),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('It learns your ordinary day', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.44)),
                        const SizedBox(height: 8),
                        Text(
                          'After two weeks it knows your route, your arrival time and your walking pace. When '
                          'those break at the same time, it asks whether you are alright.',
                          style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted(0.55)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YOUR WEEKDAY PATTERN', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 34,
                            child: Row(
                              children: [
                                for (var i = 0; i < SentinelProvider.routine.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 3),
                                  Expanded(
                                    flex: SentinelProvider.routine[i].flex,
                                    child: Container(color: SentinelProvider.routine[i].color),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('7 am', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted(0.4))),
                              Text('1 pm', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted(0.4))),
                              Text('6 pm', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted(0.4))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHAT IT WATCHES', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                          childAspectRatio: 1.55,
                          children: [
                            for (final w in SentinelProvider.watches)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted(0.04),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(color: AppColors.textMuted(0.07)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(w.icon, size: 18, color: AppColors.accentLight),
                                    const SizedBox(height: 6),
                                    Text(w.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                                    Text(w.sub, style: TextStyle(fontSize: 10.5, height: 1.4, color: AppColors.textMuted(0.48))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HOW QUICK TO ASK', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                        const SizedBox(height: 10),
                        SegmentedButton<String>(
                          segments: [for (final o in _sensOptions) ButtonSegment(value: o, label: Text(o))],
                          selected: {sentinel.sensitivity},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => sentinel.setSensitivity(s.first),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(sentinel.sensitivityNote, style: TextStyle(fontSize: 11.5, height: 1.55, color: AppColors.textMuted(0.48))),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHAT IT NOTICED', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                        for (final a in SentinelProvider.anomalies)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.07)))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(Icons.warning_amber_rounded, size: 17, color: AppColors.accentLight),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.what, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                                      Text('${a.when} · ${a.how}', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45))),
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
                            child: Icon(Icons.pan_tool_outlined, size: 17, color: AppColors.accentLight),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('If you are forced to say you are fine', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(
                                  'Holding "I am safe" instead of tapping it sends the alert silently. The screen '
                                  'looks the same either way.',
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
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          sentinel.simulate();
                          Navigator.of(context).pushNamed(Routes.checkin);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted(0.78),
                          side: BorderSide(color: AppColors.textMuted(0.24), style: BorderStyle.solid),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.play_circle_outline_rounded, size: 17),
                        label: const Text('Show me the are-you-safe check', style: TextStyle(fontSize: 13.5)),
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
