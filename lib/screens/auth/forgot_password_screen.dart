import 'package:flutter/material.dart';

import '../../app.dart';
import '../../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  bool _resent = false;

  void _next() => setState(() {
        _step = (_step + 1).clamp(0, 2);
        _resent = false;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted(0.6),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to sign in', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 26),
                child: Row(
                  children: List.generate(3, (i) {
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
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (_step) {
                  0 => _StepOne(key: const ValueKey(0), onNext: _next),
                  1 => _StepTwo(
                      key: const ValueKey(1),
                      resent: _resent,
                      onResend: () => setState(() => _resent = true),
                      onNext: _next,
                    ),
                  _ => _StepThree(
                      key: const ValueKey(2),
                      onDone: () =>
                          Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (route) => false),
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepOne extends StatelessWidget {
  const _StepOne({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset your password',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46),
        ),
        const SizedBox(height: 7),
        Text(
          'Enter the email or mobile number on your account. We will send a six-digit code.',
          style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted(0.55)),
        ),
        const SizedBox(height: 24),
        Text('Email or mobile', style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
        const SizedBox(height: 6),
        const TextField(decoration: InputDecoration(hintText: 'ayesha@example.com')),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onNext,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Send code', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E2C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.textMuted(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, size: 17, color: AppColors.accentLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your trusted contacts and SOS settings stay active while you reset. Nothing is switched off.',
                  style: TextStyle(fontSize: 11.5, height: 1.6, color: AppColors.textMuted(0.55)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepTwo extends StatelessWidget {
  const _StepTwo({super.key, required this.resent, required this.onResend, required this.onNext});

  final bool resent;
  final VoidCallback onResend;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter the code',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46),
        ),
        const SizedBox(height: 7),
        Text(
          'Sent to ayesha@example.com. It expires in ten minutes.',
          style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted(0.55)),
        ),
        const SizedBox(height: 24),
        Row(
          children: List.generate(6, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 5 ? 0 : 8),
                child: TextField(
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onNext,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Did not get it?', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted(0.45))),
            TextButton(
              onPressed: onResend,
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: const Text('Send again', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
        if (resent)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentTint(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentTint(0.24)),
            ),
            child: Text(
              'A new code is on its way.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.accentLight),
            ),
          ),
      ],
    );
  }
}

class _StepThree extends StatelessWidget {
  const _StepThree({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a new password',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46),
        ),
        const SizedBox(height: 7),
        Text(
          'At least eight characters. You will stay signed in on this phone.',
          style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted(0.55)),
        ),
        const SizedBox(height: 24),
        Text('New password', style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
        const SizedBox(height: 6),
        const TextField(obscureText: true, decoration: InputDecoration(hintText: 'At least 8 characters')),
        const SizedBox(height: 15),
        Text('Confirm password', style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
        const SizedBox(height: 6),
        const TextField(obscureText: true, decoration: InputDecoration(hintText: 'Type it once more')),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onDone,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Save and sign in', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
