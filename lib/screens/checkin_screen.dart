import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/sentinel_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/hold_to_confirm_button.dart';

/// A silent, full-screen "are you safe?" prompt raised by Smart Sentinel.
/// No back button, no dismiss gesture — the design is deliberately a
/// forced choice between the two actions below (matching a real duress
/// scenario, where an accidental system-back shouldn't quietly cancel it).
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  @override
  void initState() {
    super.initState();
    final sentinel = context.read<SentinelProvider>();
    sentinel.onEscalated = () {
      if (mounted) Navigator.of(context).pushReplacementNamed(Routes.sos);
    };
    sentinel.onConfirmedSafe = () {
      if (mounted) Navigator.of(context).pushReplacementNamed(Routes.sentinel);
    };
  }

  @override
  void dispose() {
    final sentinel = context.read<SentinelProvider>();
    sentinel.onEscalated = null;
    sentinel.onConfirmedSafe = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sentinel = context.watch<SentinelProvider>();

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1),
              radius: 1.3,
              colors: [Color(0xFF3A1C2C), Color(0xFF1E1A26), Color(0xFF171927)],
              stops: [0, 0.5, 1],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 34),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        Icon(Icons.vibration_rounded, size: 18, color: AppColors.accentLight),
                        const SizedBox(width: 9),
                        Text(
                          'SILENT CHECK · PHONE VIBRATING ONLY',
                          style: TextStyle(fontSize: 11.5, letterSpacing: 0.6, color: AppColors.textMuted(0.45)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SMART SENTINEL',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.5, color: AppColors.accentLight),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Are you safe?',
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w500, letterSpacing: -0.85, height: 1.1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 26),
                          child: Text(
                            sentinel.checkInReason,
                            style: TextStyle(fontSize: 14.5, height: 1.6, color: AppColors.textMuted(0.62)),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${sentinel.checkInSecondsLeft}',
                              style: const TextStyle(fontSize: 76, height: 1, fontWeight: FontWeight.w500, letterSpacing: -3),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'seconds until an alert goes out on its own',
                                  style: TextStyle(fontSize: 13.5, color: AppColors.textMuted(0.5)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      HoldToConfirmButton(
                        holdDuration: const Duration(milliseconds: 1400),
                        onConfirmed: sentinel.escalateNow,
                        onReleasedEarly: sentinel.confirmSafe,
                        builder: (context, progress) {
                          return Container(
                            width: double.infinity,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: AppColors.textMuted(0.24)),
                            ),
                            child: const Text('I am safe', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: sentinel.escalateNow,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentPale,
                            backgroundColor: AppColors.accentTint(0.16),
                            side: const BorderSide(color: AppColors.accent),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          child: const Text('Send the alert now', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'No sound and no notification banner. Nobody near you sees this.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, height: 1.5, color: AppColors.textMuted(0.4)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
