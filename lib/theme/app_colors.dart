import 'package:flutter/material.dart';

/// Central design tokens for the dark premium meteorological console look.
class AppColors {
  static const Color bg = Color(0xFF050D1F); // deep navy base
  static const Color navSurface = Color(0xFF07111E); // nav / secondary surface
  static const Color cardSurface = Color(0x0AFFFFFF); // white @ ~4%
  static const Color cardBorder = Color(0x14FFFFFF); // white @ ~8%

  static const Color textPrimary = Color(0xFFE8F4FF);
  static Color textMuted = const Color(0xFFE8F4FF).withOpacity(0.45);
  static Color textFaint = const Color(0xFFE8F4FF).withOpacity(0.30);

  static const Color rainCyan = Color(0xFF00D4FF); // primary accent
  static const Color stormAmber = Color(0xFFFFB800); // caution
  static const Color dangerCoral = Color(0xFFFF4444); // alert
  static const Color growthGreen = Color(0xFF00FF87); // safe / live

  // Soft accent fills
  static Color cyanFill = rainCyan.withOpacity(0.08);
  static Color amberFill = stormAmber.withOpacity(0.08);
  static Color greenFill = growthGreen.withOpacity(0.08);
  static Color coralFill = dangerCoral.withOpacity(0.08);
}
