import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Two type families: Space Grotesk for UI text, JetBrains Mono for numerics.
/// Centralised so font sizes/weights are never hardcoded at call sites.
class AppTypography {
  AppTypography._();

  /// Monospaced numeric style.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: 1.0,
      );

  /// Uppercase small label style.
  static TextStyle label({double size = 9, Color? color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: color ?? AppColors.textMuted,
      );

  /// Standard title style.
  static TextStyle title({double size = 14, Color? color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );
}
