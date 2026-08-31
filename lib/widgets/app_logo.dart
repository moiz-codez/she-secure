import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Placeholder mark for the She Secure shield logo. The design canvas used
/// a custom clipped-SVG shield shape; the user is supplying the real logo
/// asset separately. Swap the [Icon] below for
/// `Image.asset('assets/images/logo.png')` once that file is dropped into
/// the project (and declared under `flutter.assets` in pubspec.yaml).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.shield_rounded, size: size, color: AppColors.accent);
  }
}
