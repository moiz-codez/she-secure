import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../providers/auth_provider.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_logo.dart';

enum _AuthTab { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthTab _tab = _AuthTab.login;

  Future<void> _enterApp() async {
    final navigator = Navigator.of(context);
    final smsStatus = await PermissionService.requestAll();
    if (!mounted) return;
    if (!smsStatus.isGranted) {
      await showSmsRestrictedHelp(context);
      if (!mounted) return;
    }
    navigator.pushNamedAndRemoveUntil(Routes.home, (route) => false);
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

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = validateEmail(_email.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().signIn(email: _email.text.trim(), password: _password.text);
      if (mounted) widget.onSubmit();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
        _LabeledField(label: 'Email', hint: 'ayesha@example.com', controller: _email, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _LabeledField(label: 'Password', hint: '••••••••', obscure: true, controller: _password),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamed(Routes.forgot),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent, padding: EdgeInsets.zero),
            child: const Text('Forgot password?', style: TextStyle(fontSize: 12.5)),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: TextStyle(fontSize: 12, color: AppColors.danger)),
          ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _submitting ? null : _submit,
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
                : const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
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

class _SignupForm extends StatefulWidget {
  const _SignupForm({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = validateEmail(_email.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    final passwordError = validatePassword(_password.text);
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords don\'t match.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().signUp(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) widget.onSubmit();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
        _LabeledField(label: 'Full name', hint: 'Ayesha Siddiqui', controller: _name),
        const SizedBox(height: 15),
        _LabeledField(label: 'Email', hint: 'ayesha@example.com', controller: _email, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 15),
        _LabeledField(label: 'Password', hint: 'At least 8 characters', obscure: true, controller: _password),
        const SizedBox(height: 15),
        _LabeledField(label: 'Confirm password', hint: 'Type it once more', obscure: true, controller: _confirm),
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
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(_error!, style: TextStyle(fontSize: 12, color: AppColors.danger)),
          ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _submitting ? null : _submit,
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
                : const Text('Create account', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatefulWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.textMuted(0.5),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
