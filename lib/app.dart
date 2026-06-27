import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'features/weather/presentation/controllers/locale_controller.dart';

/// Root widget: Material 3 dark theme, router, and locale driven by Riverpod.
class AgriWeatherApp extends ConsumerWidget {
  const AgriWeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final isUrdu = locale.languageCode == 'ur';
    AppTypography.urdu = isUrdu; // drives the UI font family app-wide
    return MaterialApp.router(
      title: 'Changi AgriWeather',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(urdu: isUrdu),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
    );
  }
}
