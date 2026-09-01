import 'package:flutter/material.dart';

import '../app.dart';
import '../theme/app_colors.dart';

class _ObStep {
  const _ObStep({required this.icon, required this.title, required this.body, this.badge = false});

  final IconData icon;
  final String title;
  final String body;
  final bool badge;
}

const _steps = [
  _ObStep(
    icon: Icons.campaign_rounded,
    title: 'One button, and they all know',
    body:
        'Hold the SOS button for one second. Your live location and a short message go to every trusted '
        'contact by SMS.',
  ),
  _ObStep(
    icon: Icons.groups_rounded,
    title: 'Choose who gets the call',
    body:
        'Add up to five people from your phone contacts — family, a flatmate, a colleague on your route. '
        'You can change them any time.',
  ),
  _ObStep(
    icon: Icons.videocam_rounded,
    title: 'Record, quietly',
    body:
        'Audio, video or a photo, saved on your phone only. Nothing is uploaded anywhere and nothing '
        'leaves the device unless you send it.',
  ),
  _ObStep(
    icon: Icons.ring_volume_rounded,
    title: 'A call that gets you out',
    body:
        'Schedule a fake incoming call so you have a reason to leave. Set the name, set the delay, and it '
        'rings like any other call.',
  ),
  _ObStep(
    icon: Icons.psychology_alt_rounded,
    title: 'It notices when your day breaks',
    body:
        'Smart Sentinel learns your route home and the time you get there. Wrong place, wrong hour, '
        'running instead of walking — your phone vibrates and asks if you are safe. No answer in thirty '
        'seconds and the alert goes out by itself. If someone is forcing you to answer, hold the button '
        'instead of tapping it and the alert goes out anyway.',
    badge: true,
  ),
  _ObStep(
    icon: Icons.graphic_eq_rounded,
    title: 'It hears what you cannot say',
    body:
        'When there is no time to reach for the phone, the microphone is already listening for a scream '
        'or crying. It sends the alert straight away, without asking. Sound is matched on the phone and '
        'never uploaded.',
    badge: true,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  void _finish() => Navigator.of(context).pushReplacementNamed(Routes.auth);

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 18, 0),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(foregroundColor: AppColors.textMuted(0.55)),
                  child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 214,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 34),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.textMuted(0.09)),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF22243A), Color(0xFF1B1D2C)],
                        ),
                      ),
                      child: Center(
                        child: Icon(step.icon, size: 88, color: AppColors.accent.withValues(alpha: 0.85)),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Column(
                        key: ValueKey(_step),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (step.badge)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: AppColors.accentTint(0.4)),
                              ),
                              child: Text(
                                'WORKS ON ITS OWN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.1,
                                  color: AppColors.accentLight,
                                ),
                              ),
                            ),
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.5,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            step.body,
                            style: TextStyle(fontSize: 14.5, height: 1.62, color: AppColors.textMuted(0.62)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(_steps.length, (i) {
                          final active = i == _step;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 7),
                            width: active ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: active ? AppColors.accent : AppColors.textMuted(0.2),
                            ),
                          );
                        }),
                      ),
                      Text(
                        'Step ${_step + 1} of ${_steps.length}',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted(0.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Visibility(
                        visible: _step > 0,
                        maintainState: true,
                        maintainAnimation: true,
                        maintainSize: true,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _step = (_step - 1).clamp(0, _steps.length - 1)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textMuted(0.72),
                            side: BorderSide(color: AppColors.textMuted(0.16)),
                            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 15),
                          label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          if (_step == _steps.length - 1) {
                            _finish();
                          } else {
                            setState(() => _step += 1);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _step == _steps.length - 1 ? 'Get started' : 'Next',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.5),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 15),
                          ],
                        ),
                      ),
                    ],
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
