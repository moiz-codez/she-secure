import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/recordings_provider.dart';
import '../providers/sentinel_provider.dart';
import '../providers/settings_provider.dart';
import '../services/permission_service.dart';
import '../services/user_data_service.dart';
import '../theme/app_colors.dart';

Future<void> _requestPermission(BuildContext context, SettingsProvider settings, String key) async {
  await settings.requestPermission(key);
  if (!context.mounted) return;
  final row = settings.permissions.firstWhere((p) => p.key == key);
  if (key == 'sms' && !row.granted) {
    await showSmsRestrictedHelp(context);
  }
}

Future<bool> _confirm(BuildContext context, String title, String body, String action) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ),
  );
  return ok ?? false;
}

void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Runs [action] with [busy] set, then shows its returned message or the
/// error.
Future<void> _run(BuildContext context, ValueNotifier<bool> busy, Future<String> Function() action) async {
  busy.value = true;
  try {
    final done = await action();
    if (context.mounted) _snack(context, done);
  } catch (e) {
    if (context.mounted) _snack(context, "That didn't work: $e");
  } finally {
    busy.value = false;
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _busy = ValueNotifier(false);

  @override
  void dispose() {
    _busy.dispose();
    super.dispose();
  }

  Future<void> _restoreDefaults() async {
    if (!await _confirm(context, 'Restore factory defaults?', 'Every switch and sensitivity goes back to its default.', 'Restore')) {
      return;
    }
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    await _run(context, _busy, () async {
      await settings.restoreDefaults();
      return 'Defaults restored.';
    });
  }

  Future<void> _deleteRecordingsAndHistory() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    if (!await _confirm(
      context,
      'Delete recordings and history?',
      'Every recording (and its Gallery copy), your SOS history and Sentinel/Listen logs are deleted for good.',
      'Delete',
    )) {
      return;
    }
    if (!mounted) return;
    final recordings = context.read<RecordingsProvider>();
    await _run(context, _busy, () async {
      await recordings.deleteAll();
      await UserDataService.clearHistory(uid);
      return 'Recordings and history deleted.';
    });
  }

  Future<void> _loadDemoData() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    final sentinel = context.read<SentinelProvider>();
    await _run(context, _busy, () async {
      final count = await UserDataService.loadDemoData(uid);
      await sentinel.refreshSummary(force: true);
      return 'Loaded $count demo readings — open Smart Sentinel to see them.';
    });
  }

  Future<void> _clearDemoData() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    final sentinel = context.read<SentinelProvider>();
    await _run(context, _busy, () async {
      await UserDataService.clearDemoData(uid);
      await sentinel.refreshSummary(force: true);
      return 'Demo data removed.';
    });
  }

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
                                  onPressed: p.granted ? null : () => _requestPermission(context, settings, p.key),
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
                    child: Text('DEMO DATA', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                    child: ValueListenableBuilder(
                      valueListenable: _busy,
                      builder: (context, busy, _) => Column(
                        children: [
                          _ActionButton(
                            icon: Icons.auto_awesome_outlined,
                            label: 'Load 2 weeks of demo routine',
                            onPressed: busy ? null : _loadDemoData,
                          ),
                          const SizedBox(height: 10),
                          _ActionButton(
                            icon: Icons.layers_clear_outlined,
                            label: 'Remove demo data',
                            onPressed: busy ? null : _clearDemoData,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Gives Smart Sentinel a learned routine around where you are now, plus a few past '
                                'events, so the AI screens have something to show. Never touches contacts or SOS history.',
                                style: TextStyle(fontSize: 11.5, height: 1.55, color: AppColors.textMuted(0.4)),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                            onPressed: _restoreDefaults,
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
                            onPressed: _deleteRecordingsAndHistory,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.textMuted(0.16)),
          padding: const EdgeInsets.all(14),
          alignment: Alignment.centerLeft,
        ),
        icon: Icon(icon, size: 18, color: AppColors.accentLight),
        label: Text(label, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
