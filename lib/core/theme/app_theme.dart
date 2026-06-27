import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Builds the Material 3 dark theme. Type helpers live in [AppTypography];
/// this only assembles [ThemeData].
class AppTheme {
  AppTheme._();

  static ThemeData dark({bool urdu = false}) {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = (urdu
            ? GoogleFonts.notoNaskhArabicTextTheme(base.textTheme)
            : GoogleFonts.spaceGroteskTextTheme(base.textTheme))
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.rainCyan,
        surface: AppColors.bg,
      ),
      textTheme: textTheme,
    );
  }
}
