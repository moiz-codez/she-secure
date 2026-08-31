import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/status_pill.dart';

class _Lesson {
  const _Lesson({required this.n, required this.title, required this.body});

  final String n;
  final String title;
  final String body;
}

class _Video {
  const _Video({required this.title, required this.dur, required this.src});

  final String title;
  final String dur;
  final String src;
}

const _lessons = [
  _Lesson(n: '01', title: 'Add your trusted contacts first', body: 'Nothing else works until at least one person is on the list.'),
  _Lesson(n: '02', title: 'Practise the hold once', body: 'Use the test alert so your hand knows the button in the dark.'),
  _Lesson(
    n: '03',
    title: 'Keep location permission on',
    body: 'Set it to "Allow all the time" so an alert works with the screen locked.',
  ),
  _Lesson(n: '04', title: 'Know your two shortcuts', body: 'A hard shake, or the power button three times, fires the same alert.'),
];

const _videos = [
  _Video(title: 'Wrist release and escape', dur: '6:12', src: 'youtube.com/watch?v=…'),
  _Video(title: 'Using your bag and dupatta', dur: '4:48', src: 'youtube.com/watch?v=…'),
  _Video(title: 'Safe travel on a rickshaw', dur: '8:03', src: 'youtube.com/watch?v=…'),
];

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Text('Tutorial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 26),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Four minutes now saves you later', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46)),
                        SizedBox(height: 8),
                        Text(
                          'Set the app up once, then practise the hold so your hand remembers it.',
                          style: TextStyle(fontSize: 13.5, height: 1.6, color: Color.fromRGBO(233, 233, 237, 0.55)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                    child: Column(
                      children: [
                        for (final l in _lessons)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.07)))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(l.n, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.accentLight)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 3),
                                      Text(l.body, style: TextStyle(fontSize: 12.5, height: 1.55, color: AppColors.textMuted(0.5))),
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
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 6),
                    child: Text('SELF-DEFENCE VIDEOS', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    child: Column(
                      children: [
                        for (final v in _videos)
                          Container(
                            margin: const EdgeInsets.only(bottom: 11),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => showNotBuiltSnack(context),
                              child: Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.textMuted(0.08)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 76,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceDim,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.textMuted(0.08)),
                                      ),
                                      child: const Icon(Icons.play_arrow_rounded, size: 19, color: AppColors.accent),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(v.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 3),
                                          Text('${v.dur} · ${v.src}', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45))),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textMuted(0.35)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Videos open in YouTube. Give me the real links and I will drop them in.',
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
