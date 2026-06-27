/// Design-token catalog — never hardcode layout values; reference these tokens.
/// Exhaustive on purpose (spacing, radius, elevation, icon, opacity, border,
/// duration, breakpoints) so screens stay magic-number-free.
class AppSpacing {
  AppSpacing._();

  // --- Spacing ---
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 16;
  static const double xxxl = 24;
  static const double huge = 32;

  // --- Radius ---
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusXl = 12;
  static const double radiusXxl = 16;
  static const double radiusPill = 100;

  // --- Elevation ---
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMed = 4;
  static const double elevationHigh = 8;

  // --- Icon sizes ---
  static const double iconXs = 12;
  static const double iconSm = 15;
  static const double iconMd = 19;
  static const double iconLg = 24;
  static const double iconXl = 32;

  // --- Opacity ---
  static const double opacityFaint = 0.04;
  static const double opacityLight = 0.08;
  static const double opacityMuted = 0.30;
  static const double opacityStrong = 0.60;

  // --- Border width ---
  static const double borderThin = 0.5;
  static const double borderMed = 1;
  static const double borderThick = 2;

  // --- Animation durations ---
  static const Duration durFast = Duration(milliseconds: 150);
  static const Duration durMed = Duration(milliseconds: 250);
  static const Duration durSlow = Duration(milliseconds: 300);

  // --- Responsive breakpoints / max widths ---
  static const double breakpointTablet = 600;
  static const double maxContentWidth = 1200;
}
