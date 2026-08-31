import 'package:flutter/material.dart';

import '../app.dart';
import '../theme/app_colors.dart';
import '../widgets/status_pill.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                        const Text('Ayesha Siddiqui', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('With She Secure since March 2026', style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.45))),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileField(label: 'Full name', value: 'Ayesha Siddiqui'),
                        const SizedBox(height: 15),
                        _ProfileField(label: 'Email', value: 'ayesha@example.com'),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(child: _ProfileField(label: 'Age (optional)', value: '22')),
                            const SizedBox(width: 11),
                            Expanded(flex: 2, child: _ProfileField(label: 'City (optional)', value: 'Karachi')),
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
                            onPressed: () => showNotBuiltSnack(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => showNotBuiltSnack(context),
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
                        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.auth, (route) => false),
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
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
        const SizedBox(height: 6),
        TextFormField(initialValue: value),
      ],
    );
  }
}
