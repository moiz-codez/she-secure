import 'package:flutter/material.dart';

/// The She Secure shield mark. `assets/images/logo.png` has a real
/// transparent background, so it can sit directly on the app's dark
/// theme without any badge behind it. Used on the splash screen and the
/// auth screen.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/logo.png', width: size, height: size, fit: BoxFit.contain);
  }
}
