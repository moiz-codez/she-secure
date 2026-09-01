import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/contacts_provider.dart';
import '../providers/sos_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/hold_to_confirm_button.dart';
import '../widgets/status_pill.dart';

Future<void> _callNumber(String num) => launchUrl(Uri(scheme: 'tel', path: num));

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    final armed = sos.state == SosState.armed;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: armed
              ? const RadialGradient(
                  center: Alignment(0, -1),
                  radius: 1.3,
                  colors: [Color(0xFF3A1C2C), Color(0xFF1E1A26), Color(0xFF171927)],
                  stops: [0, 0.48, 1],
                )
              : const RadialGradient(
                  center: Alignment(0, -0.72),
                  radius: 1.25,
                  colors: [Color(0xFF221A2B), Color(0xFF171927), Color(0xFF14151F)],
                  stops: [0, 0.55, 1],
                ),
        ),
        child: SafeArea(
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
                    const Text(
                      'Emergency',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted(0.06),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Consumer<ContactsProvider>(
                        builder: (context, contacts, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.groups_rounded, size: 14, color: AppColors.textMuted(0.55)),
                            const SizedBox(width: 6),
                            Text(
                              '${contacts.contacts.length}',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.7)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (sos.state) {
                  SosState.idle => const _IdleBody(),
                  SosState.counting => const _CountingBody(),
                  SosState.armed => const _ArmedBody(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdleBody extends StatelessWidget {
  const _IdleBody();

  @override
  Widget build(BuildContext context) {
    final sos = context.read<SosProvider>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(26, 20, 26, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hold the button to send for help',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.48),
                ),
                SizedBox(height: 8),
                Text(
                  'A tap will not do it — that way it never fires in your bag.',
                  style: TextStyle(fontSize: 13.5, height: 1.6, color: Color.fromRGBO(233, 233, 237, 0.55)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 26),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  HoldToConfirmButton(
                    holdDuration: const Duration(milliseconds: 1100),
                    onConfirmed: sos.beginCountdown,
                    builder: (context, progress) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          HoldProgressRing(
                            progress: progress,
                            diameter: 230,
                            filledColor: AppColors.accent,
                            emptyColor: AppColors.textMuted(0.1),
                          ),
                          Container(
                            width: 214,
                            height: 214,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF171927)),
                          ),
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                              gradient: const RadialGradient(
                                center: Alignment(-0.36, -0.52),
                                radius: 1.2,
                                colors: [Color(0xFFF0698F), Color(0xFFE5527E), Color(0xFFB93A61)],
                                stops: [0, 0.42, 1],
                              ),
                              boxShadow: [
                                BoxShadow(color: AppColors.accentTint(0.4), blurRadius: 46, offset: const Offset(0, 18)),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.campaign_rounded, size: 36, color: Colors.white),
                                const Text(
                                  'SOS',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3.4,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  progress > 0 ? 'keep holding…' : 'press and hold',
                                  style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.textMuted(0.045),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textMuted(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THEY WILL RECEIVE',
                    style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"I need help, this is my location."',
                    style: TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.textMuted(0.9)),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 7,
                    children: [
                      StatusPill(
                        label: 'SMS',
                        background: AppColors.accentDeep,
                        foreground: const Color(0xFFFFDDE7),
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                      StatusPill(
                        label: 'Live link',
                        background: AppColors.surfaceAlt,
                        foreground: AppColors.textMuted(0.7),
                        icon: Icons.location_on_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: Row(
              children: [
                Expanded(child: _HintChip(icon: Icons.vibration_rounded, label: 'Shake phone hard')),
                const SizedBox(width: 9),
                Expanded(child: _HintChip(icon: Icons.power_settings_new_rounded, label: 'Power button ×3')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT ALERTS',
                      style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35)),
                    ),
                    TextButton(
                      onPressed: () => showNotBuiltSnack(context),
                      style: TextButton.styleFrom(foregroundColor: AppColors.accent, padding: EdgeInsets.zero),
                      child: const Text('See all', style: TextStyle(fontSize: 11.5)),
                    ),
                  ],
                ),
                for (final entry in sos.history)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.07)))),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: AppColors.accentTint(0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.campaign_rounded, size: 15, color: AppColors.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.where, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(
                                '${entry.when} · ${entry.detail}',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textMuted(0.3)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.textMuted(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textMuted(0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.accentLight),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.textMuted(0.68))),
          ),
        ],
      ),
    );
  }
}

class _CountingBody extends StatelessWidget {
  const _CountingBody();

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('SENDING IN', style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: AppColors.accentLight)),
          Text(
            '${sos.count}',
            style: const TextStyle(fontSize: 132, height: 1, fontWeight: FontWeight.w500, letterSpacing: -6.6, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Stay calm. Lift your finger and it still sends — tap cancel if you are safe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textMuted(0.6)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: sos.cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                backgroundColor: AppColors.textMuted(0.07),
                side: BorderSide(color: AppColors.textMuted(0.16)),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArmedBody extends StatelessWidget {
  const _ArmedBody();

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    final contacts = context.watch<ContactsProvider>().contacts;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentTint(0.14),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.accentTint(0.4)),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Alert active · sharing location',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.accentPale),
                    ),
                  ),
                  Text(
                    formatMmSs(sos.elapsed),
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.accentPale),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(26, 22, 26, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your people know where you are',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46),
                ),
                SizedBox(height: 8),
                Text(
                  'Your location keeps updating every ten seconds until you stop it.',
                  style: TextStyle(fontSize: 13.5, height: 1.6, color: Color.fromRGBO(233, 233, 237, 0.55)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.textMuted(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textMuted(0.08)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < contacts.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.06)))),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              contacts[i].initials,
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textMuted(0.7)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(contacts[i].name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                                Text(
                                  '${contacts[i].relation} · ${contacts[i].phone}',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45)),
                                ),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: i < sos.acked ? 'Seen' : 'Sent',
                            background: i < sos.acked ? AppColors.successBg : AppColors.surfaceAlt,
                            foreground: i < sos.acked ? AppColors.successText : AppColors.textMuted(0.55),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callNumber('15'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      backgroundColor: AppColors.textMuted(0.05),
                      side: BorderSide(color: AppColors.textMuted(0.14)),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.phone_rounded, size: 17, color: AppColors.accentLight),
                    label: const Text('Call 15', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.5)),
                  ),
                ),
                const SizedBox(width: 9),
                _SquareIconButton(icon: Icons.mic_none_rounded, onTap: () => showNotBuiltSnack(context)),
                const SizedBox(width: 9),
                _SquareIconButton(icon: Icons.share_rounded, onTap: () => showNotBuiltSnack(context)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
            child: Column(
              children: [
                HoldToConfirmButton(
                  holdDuration: const Duration(milliseconds: 950),
                  onConfirmed: sos.cancel,
                  builder: (context, progress) {
                    return Container(
                      width: double.infinity,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.textMuted(0.2)),
                        gradient: progress > 0
                            ? LinearGradient(
                                colors: [AppColors.accentTint(0.35), AppColors.textMuted(0.07)],
                                stops: [progress, progress],
                              )
                            : null,
                        color: progress > 0 ? null : AppColors.textMuted(0.07),
                      ),
                      child: Text(
                        progress > 0 ? 'Keep holding to stop…' : 'Hold to stop the alert',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16.5),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 11),
                Text(
                  'Your contacts are told you are safe.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.textMuted(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted(0.14)),
      ),
      child: IconButton(onPressed: onTap, icon: Icon(icon, size: 19, color: AppColors.accentLight)),
    );
  }
}
