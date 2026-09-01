import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _barController;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))
      ..repeat(reverse: true);
    _navTimer = Timer(const Duration(milliseconds: 2300), () {
      if (!mounted) return;
      final signedIn = context.read<AuthProvider>().isSignedIn;
      Navigator.of(context).pushReplacementNamed(signedIn ? Routes.home : Routes.onboarding);
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.36),
            radius: 1.1,
            colors: [Color(0xFF22192B), Color(0xFF161826), Color(0xFF12131F)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color.fromRGBO(229, 82, 126, 0.28), Colors.transparent],
                            stops: [0, 0.68],
                          ),
                        ),
                      ),
                      const AppLogo(size: 92),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'She Secure',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.6,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Help is one hold away',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted(0.5), letterSpacing: 0.1),
                  ),
                  const SizedBox(height: 38),
                  SizedBox(
                    width: 104,
                    height: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        color: AppColors.textMuted(0.12),
                        child: AnimatedBuilder(
                          animation: _barController,
                          builder: (context, _) {
                            return Align(
                              alignment: Alignment(_barController.value * 2 - 1, 0),
                              child: FractionallySizedBox(
                                widthFactor: 0.45,
                                child: Container(color: AppColors.accent),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Text(
                  'MADE IN PAKISTAN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.05,
                    color: AppColors.textMuted(0.28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
