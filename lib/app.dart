import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'l10n/strings.dart';
import 'models/weather_models.dart';
import 'services/weather_service.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';
import 'screens/home_shell.dart';

/// Global app state shared down the tree via InheritedNotifier-free approach:
/// a single ChangeNotifier passed through constructor + ValueListenableBuilder
/// for locale.
class AppController extends ChangeNotifier {
  final WeatherService _weather = WeatherService();
  final CacheService cache = CacheService();
  final NotificationService notifications = NotificationService();

  WeatherBundle? bundle;
  bool loading = true;
  bool fromCache = false;
  String? error;

  // Default farm location.
  double lat = 32.145;
  double lon = 74.526;
  String placeName = 'Changi Village · Daska · Sialkot';

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  Future<void> boot() async {
    await notifications.init();
    final lang = await cache.loadLang();
    locale.value = Locale(lang);

    // Show cache instantly.
    final cached = await cache.loadBundle();
    if (cached != null) {
      bundle = cached;
      fromCache = true;
      loading = false;
      notifyListeners();
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      error = null;
      if (bundle == null) {
        loading = true;
        notifyListeners();
      }
      final fresh = await _weather.fetch(
        lat: lat,
        lon: lon,
        placeName: placeName,
      );
      bundle = fresh;
      fromCache = false;
      loading = false;
      await cache.saveBundle(fresh);
      await notifications.evaluateAndNotify(fresh);
      notifyListeners();
    } catch (e) {
      loading = false;
      if (bundle == null) error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    locale.value = Locale(code);
    await cache.saveLang(code);
    notifyListeners();
  }
}

class AgriWeatherApp extends StatelessWidget {
  final AppController controller;
  const AgriWeatherApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: controller.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Changi AgriWeather',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ur')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HomeShell(controller: controller),
        );
      },
    );
  }
}
