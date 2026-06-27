import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final controller = AppController();
  runApp(AgriWeatherApp(controller: controller));
  // Kick off boot after first frame so cached UI shows immediately.
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.boot());
}
