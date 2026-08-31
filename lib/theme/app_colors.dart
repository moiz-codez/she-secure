import 'package:flutter/material.dart';

/// Colors ported from the Claude Design canvas (Nocturne design-system
/// tokens + She Secure's own accent override). Kept as flat constants
/// rather than a ThemeExtension for now — there's exactly one theme
/// (dark), so a swappable-theme abstraction isn't needed yet.
class AppColors {
  AppColors._();

  static const background = Color(0xFF161826);
  static const canvasBackground = Color(0xFF0E0F17);
  static const surface = Color(0xFF232532);
  static const surfaceAlt = Color(0xFF2A2C3C);
  static const surfaceDim = Color(0xFF101119);
  static const text = Color(0xFFE9E9ED);

  static const accent = Color(0xFFE5527E);
  static const accentLight = Color(0xFFF791AE);
  static const accentPale = Color(0xFFFFC0D1);
  static const accentDeep = Color(0xFF6B2439);

  static const success = Color(0xFF5FD39A);
  static const successBg = Color(0xFF1F4636);
  static const successText = Color(0xFFC8F0DD);
  static const danger = Color(0xFFC8384B);
  static const callAccept = Color(0xFF2F9D63);

  static Color textMuted(double opacity) => text.withValues(alpha: opacity);
  static Color divider(double opacity) => text.withValues(alpha: opacity);
  static Color accentTint(double opacity) => accent.withValues(alpha: opacity);
}
