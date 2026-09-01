import 'package:flutter/material.dart';

/// The She Secure shield mark. The source file
/// (`assets/images/logo.jpg`) is a flat graphic on a white background —
/// shown on a small white badge rather than directly against the app's
/// dark theme, so that white background reads as a deliberate mark rather
/// than a stray box. Used on the splash screen and the auth screen.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.14),
        child: Image.asset('assets/images/logo.jpg', fit: BoxFit.contain),
      ),
    );
  }
}
