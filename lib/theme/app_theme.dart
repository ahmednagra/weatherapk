import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Builds the dark ThemeData and exposes the two type families:
/// Space Grotesk for UI, JetBrains Mono for all numerics.
class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.rainCyan,
        surface: AppColors.bg,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  /// Monospaced numeric style helper.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: 1.0,
    );
  }

  /// Uppercase small label style.
  static TextStyle label({double size = 9, Color? color}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6,
      color: color ?? AppColors.textMuted,
    );
  }

  static TextStyle title({double size = 14, Color? color}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.textPrimary,
    );
  }
}
