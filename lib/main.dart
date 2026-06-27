import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/weather/data/datasources/weather_local_datasource.dart';
import 'features/weather/presentation/providers/di_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Open the single Hive cache box up front so synchronous reads (language,
  // bias) are available the moment providers build.
  await Hive.initFlutter();
  final box = await Hive.openBox(WeatherLocalDataSourceImpl.boxName);

  runApp(
    ProviderScope(
      overrides: [hiveBoxProvider.overrideWithValue(box)],
      child: const AgriWeatherApp(),
    ),
  );
}
