import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/listen_provider.dart';
import '../providers/sentinel_provider.dart';
import '../providers/sos_provider.dart';
import '../services/profile_photo_service.dart';
import '../theme/app_colors.dart';
import '../widgets/hold_to_confirm_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const _HomeDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.52),
            radius: 1.15,
            colors: [Color(0xFF221A2B), Color(0xFF171927), Color(0xFF14151F)],
            stops: [0, 0.52, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      icon: const Icon(Icons.menu_rounded, size: 22, color: AppColors.text),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
                      icon: Icon(Icons.settings_outlined, size: 21, color: AppColors.textMuted(0.7)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GOOD EVENING',
                      style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: AppColors.textMuted(0.35)),
                    ),
                    const SizedBox(height: 5),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) => Text(
                        auth.profileName?.isNotEmpty == true ? auth.profileName! : 'there',
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 26),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted(0.05),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.textMuted(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Consumer<ContactsProvider>(
                          builder: (context, contacts, _) => Text(
                            '${contacts.contacts.length} contacts ready',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.72)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Consumer<SentinelProvider>(
                        builder: (context, sentinel, _) => _AiCard(
                          icon: Icons.psychology_alt_rounded,
                          label: 'Smart Sentinel',
                          state: sentinel.statusLabel,
                          onTap: () => Navigator.of(context).pushNamed(Routes.sentinel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Consumer<ListenProvider>(
                        builder: (context, listen, _) => _AiCard(
                          icon: Icons.graphic_eq_rounded,
                          label: 'Distress listening',
                          state: listen.statusLabel,
                          onTap: () => Navigator.of(context).pushNamed(Routes.listen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) => _PulseRing(progress: _pulseController.value),
                      ),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) =>
                            _PulseRing(progress: (_pulseController.value + 0.5) % 1.0),
                      ),
                      Consumer<SosProvider>(
                        builder: (context, sos, _) => HoldToConfirmButton(
                          holdDuration: const Duration(milliseconds: 1100),
                          onConfirmed: () {
                            sos.beginCountdown();
                            Navigator.of(context).pushNamed(Routes.sos);
                          },
                          builder: (context, progress) => Container(
                            width: 196,
                            height: 196,
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
                                BoxShadow(
                                  color: AppColors.accentTint(0.42),
                                  blurRadius: 46,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.campaign_rounded, size: 38, color: Colors.white),
                                const SizedBox(height: 5),
                                const Text(
                                  'SOS',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  progress > 0 ? 'keep holding…' : 'press and hold',
                                  style: const TextStyle(fontSize: 11.5, color: Colors.white70, letterSpacing: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: 0.86,
                  children: [
                    _HomeTile(
                      icon: Icons.groups_rounded,
                      label: 'Contacts',
                      onTap: () => Navigator.of(context).pushNamed(Routes.contacts),
                    ),
                    _HomeTile(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      onTap: () => Navigator.of(context).pushNamed(Routes.location),
                    ),
                    _HomeTile(
                      icon: Icons.videocam_outlined,
                      label: 'Record',
                      onTap: () => Navigator.of(context).pushNamed(Routes.recordings),
                    ),
                    _HomeTile(
                      icon: Icons.phone_callback_outlined,
                      label: 'Fake call',
                      onTap: () => Navigator.of(context).pushNamed(Routes.fakeCall),
                    ),
                    _HomeTile(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Tutorial',
                      dim: true,
                      onTap: () => Navigator.of(context).pushNamed(Routes.tutorial),
                    ),
                    _HomeTile(
                      icon: Icons.account_circle_outlined,
                      label: 'Profile',
                      dim: true,
                      onTap: () => Navigator.of(context).pushNamed(Routes.profile),
                    ),
                    _HomeTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      dim: true,
                      onTap: () => Navigator.of(context).pushNamed(Routes.settings),
                    ),
                    _HomeTile(
                      icon: Icons.more_horiz_rounded,
                      label: 'All',
                      dashed: true,
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scale = 1 + progress * 0.5;
    final opacity = (1 - progress).clamp(0.0, 1.0) * 0.55;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 196,
        height: 196,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentTint(0.16 * opacity / 0.55),
        ),
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.icon, required this.label, required this.state, required this.onTap});

  final IconData icon;
  final String label;
  final String state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.accentTint(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentTint(0.28)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.accentLight),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(state, style: TextStyle(fontSize: 10.5, color: AppColors.textMuted(0.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dim = false,
    this.dashed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dim;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.textMuted(0.045),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textMuted(dashed ? 0.16 : 0.07)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: dim ? AppColors.textMuted(0.6) : AppColors.accentLight),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, height: 1.25, color: AppColors.textMuted(0.82)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.psychology_alt_rounded, 'Smart Sentinel', Routes.sentinel),
      (Icons.graphic_eq_rounded, 'Distress listening', Routes.listen),
      (Icons.groups_rounded, 'Trusted contacts', Routes.contacts),
      (Icons.location_on_outlined, 'Live location', Routes.location),
      (Icons.videocam_outlined, 'Recordings', Routes.recordings),
      (Icons.phone_callback_outlined, 'Fake call', Routes.fakeCall),
      (Icons.play_circle_outline_rounded, 'Tutorial', Routes.tutorial),
      (Icons.settings_outlined, 'Settings', Routes.settings),
      (Icons.account_circle_outlined, 'Profile', Routes.profile),
    ];

    return Drawer(
      backgroundColor: const Color(0xFF1A1C29),
      width: 302,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
              child: Row(
                children: [
                  FutureBuilder<String>(
                    future: ProfilePhotoService.path(),
                    builder: (context, snapshot) {
                      final path = snapshot.data;
                      final hasPhoto = path != null && File(path).existsSync();
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.textMuted(0.1)),
                          image: hasPhoto ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover) : null,
                        ),
                        child: hasPhoto ? null : Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textMuted(0.5)),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Consumer2<AuthProvider, ContactsProvider>(
                    builder: (context, auth, contacts, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.profileName?.isNotEmpty == true ? auth.profileName! : 'She Secure',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${contacts.contacts.length} contacts',
                          style: const TextStyle(fontSize: 11.5, color: Color.fromRGBO(233, 233, 237, 0.45)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.textMuted(0.14)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.campaign_rounded, color: AppColors.accent, size: 19),
                    title: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    tileColor: AppColors.accentTint(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(Routes.sos);
                    },
                  ),
                  for (final item in items)
                    ListTile(
                      leading: Icon(item.$1, size: 19, color: AppColors.textMuted(0.6)),
                      title: Text(
                        item.$2,
                        style: TextStyle(fontSize: 14, color: AppColors.textMuted(0.82)),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted(0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(item.$3);
                      },
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.textMuted(0.14)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: ListTile(
                leading: Icon(Icons.logout_rounded, size: 19, color: AppColors.textMuted(0.7)),
                title: Text('Log out', style: TextStyle(fontSize: 14, color: AppColors.textMuted(0.6))),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await context.read<AuthProvider>().signOut();
                  navigator.pushNamedAndRemoveUntil(Routes.auth, (route) => false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
