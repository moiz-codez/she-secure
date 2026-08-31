import 'package:flutter/material.dart';

import '../../app.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

enum _AuthTab { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthTab _tab = _AuthTab.login;

  void _enterApp() {
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  AppLogo(size: 26),
                  SizedBox(width: 11),
                  Text(
                    'She Secure',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: -0.17),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  _AuthTabButton(
                    label: 'Sign in',
                    active: _tab == _AuthTab.login,
                    onTap: () => setState(() => _tab = _AuthTab.login),
                  ),
                  const SizedBox(width: 22),
                  _AuthTabButton(
                    label: 'Create account',
                    active: _tab == _AuthTab.signup,
                    onTap: () => setState(() => _tab = _AuthTab.signup),
                  ),
                ],
              ),
              Container(height: 1, color: AppColors.textMuted(0.1)),
              const SizedBox(height: 26),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _tab == _AuthTab.login ? _LoginForm(onSubmit: _enterApp) : _SignupForm(onSubmit: _enterApp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? AppColors.accent : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
            color: active ? AppColors.text : AppColors.textMuted(0.45),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46),
        ),
        const SizedBox(height: 7),
        Text(
          'Your contacts and settings are where you left them.',
          style: TextStyle(fontSize: 13.5, color: AppColors.textMuted(0.55)),
        ),
        const SizedBox(height: 26),
        const _LabeledField(label: 'Email', hint: 'ayesha@example.com'),
        const SizedBox(height: 16),
        const _LabeledField(label: 'Password', hint: '••••••••', obscure: true),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamed(Routes.forgot),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent, padding: EdgeInsets.zero),
            child: const Text('Forgot password?', style: TextStyle(fontSize: 12.5)),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onSubmit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'By signing in you allow She Secure to use your location during an SOS.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.6, color: AppColors.textMuted(0.4)),
        ),
      ],
    );
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('signup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Four things and you are in',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46),
        ),
        const SizedBox(height: 7),
        Text(
          'Photo, age and city can wait — add them later from your profile.',
          style: TextStyle(fontSize: 13.5, color: AppColors.textMuted(0.55)),
        ),
        const SizedBox(height: 24),
        const _LabeledField(label: 'Full name', hint: 'Ayesha Siddiqui'),
        const SizedBox(height: 15),
        const _LabeledField(label: 'Email', hint: 'ayesha@example.com'),
        const SizedBox(height: 15),
        const _LabeledField(label: 'Password', hint: 'At least 8 characters', obscure: true),
        const SizedBox(height: 15),
        const _LabeledField(label: 'Confirm password', hint: 'Type it once more', obscure: true),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E2C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.textMuted(0.14), style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                child: Icon(Icons.camera_alt_outlined, size: 17, color: AppColors.textMuted(0.45)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile photo, age, city', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      'Optional · add from Profile later',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onSubmit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.hint, this.obscure = false});

  final String label;
  final String hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
        const SizedBox(height: 6),
        TextField(obscureText: obscure, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}
