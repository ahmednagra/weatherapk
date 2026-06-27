import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Two type families: Space Grotesk for UI text, JetBrains Mono for numerics.
/// For Urdu the UI family switches to Noto Naskh Arabic (Space Grotesk has no
/// Urdu glyphs). Centralised so font sizes/weights are never hardcoded at call
/// sites. [urdu] is set from the active locale in `AgriWeatherApp.build`.
class AppTypography {
  AppTypography._();

  /// Toggled by the app when the locale is Urdu — drives the UI font family.
  static bool urdu = false;

  /// Locale-aware UI font (Naskh for Urdu, Space Grotesk otherwise).
  static TextStyle _ui({
    required double size,
    required FontWeight weight,
    double? letterSpacing,
    Color? color,
  }) {
    final c = color ?? AppColors.textPrimary;
    return urdu
        ? GoogleFonts.notoNaskhArabic(
            fontSize: size, fontWeight: weight, color: c)
        : GoogleFonts.spaceGrotesk(
            fontSize: size,
            fontWeight: weight,
            letterSpacing: letterSpacing,
            color: c,
          );
  }

  /// Monospaced numeric style (digits are script-agnostic).
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
  static TextStyle label({double size = 9, Color? color}) => _ui(
        size: size,
        weight: FontWeight.w500,
        letterSpacing: 0.6,
        color: color ?? AppColors.textMuted,
      );

  /// Standard title style.
  static TextStyle title({double size = 14, Color? color}) =>
      _ui(size: size, weight: FontWeight.w500, color: color);
}
