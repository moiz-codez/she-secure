import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

/// Firebase Auth's password reset is link-based (an email with a secure
/// link to a Firebase-hosted page), not an in-app 6-digit code the design
/// canvas mocked up. Building a real in-app OTP flow instead would need a
/// custom backend (Cloud Function issuing/verifying codes) — out of scope
/// for wiring up "real" auth, and a fake code screen that doesn't actually
/// verify anything would be worse than not having it. This keeps the same
/// visual language but only claims what actually happens: request the
/// email, confirm it was sent.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().sendPasswordReset(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
                style: TextButton.styleFrom(foregroundColor: AppColors.textMuted(0.6), padding: EdgeInsets.zero),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to sign in', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _sent ? const _SentConfirmation(key: ValueKey('sent')) : _buildRequestForm(const ValueKey('request')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm(Key key) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset your password',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46),
        ),
        const SizedBox(height: 7),
        Text(
          'Enter the email on your account. We will send a link to reset your password.',
          style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted(0.55)),
        ),
        const SizedBox(height: 24),
        Text('Email', style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
        const SizedBox(height: 6),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'ayesha@example.com'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!, style: TextStyle(fontSize: 12, color: AppColors.danger)),
          ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _submitting ? null : _sendResetEmail,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  )
                : const Text('Send reset link', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
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

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: AppColors.accentTint(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, size: 28, color: AppColors.accentLight),
        ),
        const Text(
          'Check your email',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46),
        ),
        const SizedBox(height: 7),
        Text(
          'We sent a link to reset your password. Open it on this phone to set a new one, then '
          'come back and sign in.',
          style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted(0.55)),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Back to sign in', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
