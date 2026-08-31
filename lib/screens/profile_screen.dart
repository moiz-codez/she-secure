import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/status_pill.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _city = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  String get _uid => context.read<AuthProvider>().user!.uid;

  @override
  void initState() {
    super.initState();
    _name.text = context.read<AuthProvider>().user?.displayName ?? '';
    FirebaseFirestore.instance.collection('users').doc(_uid).get().then((doc) {
      if (!mounted) return;
      final data = doc.data();
      setState(() {
        _age.text = data?['age'] as String? ?? '';
        _city.text = data?['city'] as String? ?? '';
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>().user!;
    await auth.updateDisplayName(_name.text.trim());
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      'name': _name.text.trim(),
      'age': _age.text.trim(),
      'city': _city.text.trim(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Saved.')));
  }

  Future<void> _sendPasswordReset() async {
    final email = context.read<AuthProvider>().user?.email;
    if (email == null) return;
    await context.read<AuthProvider>().sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Password reset link sent to $email.')));
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().signOut();
    navigator.pushNamedAndRemoveUntil(Routes.auth, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

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
                  const Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 26),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.textMuted(0.1)),
                              ),
                              child: Icon(Icons.person_outline_rounded, size: 40, color: AppColors.textMuted(0.35)),
                            ),
                            Positioned(
                              right: -3,
                              bottom: -3,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => showNotBuiltSnack(context),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.background, width: 3),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user?.displayName?.isNotEmpty == true ? user!.displayName! : 'She Secure user',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.45))),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileField(label: 'Full name', controller: _name),
                        const SizedBox(height: 15),
                        Text('Email', style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
                        const SizedBox(height: 6),
                        TextFormField(initialValue: user?.email ?? '', enabled: false),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(child: _ProfileField(label: 'Age (optional)', controller: _age)),
                            const SizedBox(width: 11),
                            Expanded(flex: 2, child: _ProfileField(label: 'City (optional)', controller: _city)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: !_loaded || _saving ? null : _save,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                                  )
                                : const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _sendPasswordReset,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text,
                              side: BorderSide(color: AppColors.textMuted(0.16)),
                              padding: const EdgeInsets.all(13),
                              alignment: Alignment.centerLeft,
                            ),
                            icon: Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted(0.55)),
                            label: const Text('Change password', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 40, 22, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _logout,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted(0.55),
                          padding: const EdgeInsets.all(13),
                          alignment: Alignment.centerLeft,
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Log out', style: TextStyle(fontSize: 14)),
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
        const SizedBox(height: 6),
        TextField(controller: controller),
      ],
    );
  }
}
