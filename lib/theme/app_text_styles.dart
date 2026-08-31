import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text style helpers ported from the design canvas's inline `font:` /
/// `font-size` declarations. Kept as small factory functions rather than a
/// full named TextTheme because the canvas used one-off sizes per element
/// rather than a fixed type scale.
class AppText {
  AppText._();

  static TextStyle _inter({
    required double size,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    Color color = AppColors.text,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle heading({
    required double size,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = -0.02,
    double? height,
    Color color = AppColors.text,
  }) =>
      _inter(
        size: size,
        weight: weight,
        letterSpacing: letterSpacing * size,
        height: height,
        color: color,
      );

  static TextStyle body({
    double size = 14.5,
    FontWeight weight = FontWeight.w400,
    double? height,
    Color color = AppColors.text,
  }) =>
      _inter(size: size, weight: weight, height: height, color: color);

  static TextStyle label({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    Color color = AppColors.text,
  }) =>
      _inter(size: size, weight: weight, letterSpacing: letterSpacing, color: color);

  static TextStyle eyebrow({
    double size = 9.5,
    Color color = const Color.fromRGBO(233, 233, 237, 0.35),
  }) =>
      _inter(
        size: size,
        weight: FontWeight.w400,
        letterSpacing: size * 0.12,
        color: color,
      );
}
