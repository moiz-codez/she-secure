import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/status_pill.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SettingsProvider>().refreshPermissions());
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

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
                  const Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 26),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                    child: Text('FEATURES', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        for (final row in SettingsProvider.rows)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.07)))),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(row.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      Text(row.sub, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45))),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: settings.isOn(row.key),
                                  onChanged: (_) => settings.toggle(row.key),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 6),
                    child: Text('DEVICE PERMISSIONS', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        for (final p in settings.permissions)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.07)))),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      Text(p.sub, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45))),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: p.granted ? null : () => settings.requestPermission(p.key),
                                  style: TextButton.styleFrom(
                                    backgroundColor: p.granted ? AppColors.successBg : Colors.transparent,
                                    foregroundColor: p.granted ? AppColors.successText : AppColors.accent,
                                    side: p.granted ? BorderSide.none : const BorderSide(color: AppColors.accent),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  ),
                                  child: Text(p.granted ? 'Granted' : 'Allow', style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 6),
                    child: Text('RESET', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => showNotBuiltSnack(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text,
                              side: BorderSide(color: AppColors.textMuted(0.16)),
                              padding: const EdgeInsets.all(14),
                              alignment: Alignment.centerLeft,
                            ),
                            icon: Icon(Icons.restore_rounded, size: 18, color: AppColors.textMuted(0.55)),
                            label: const Text('Restore factory defaults', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => showNotBuiltSnack(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: BorderSide(color: AppColors.accentTint(0.45)),
                              padding: const EdgeInsets.all(14),
                              alignment: Alignment.centerLeft,
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text('Delete all recordings and history', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Restoring defaults keeps your account and your trusted contacts.',
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
