import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/weather_models.dart';
import '../logic/farm_decisions.dart';

/// Local notifications. Fires alerts when a fresh forecast meets a trigger.
///
/// Note: this evaluates on foreground refresh. For always-on background
/// delivery when the app is closed, wrap [evaluateAndNotify] in a
/// WorkManager periodic task (see README "Background alerts").
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Android 13+ runtime permission.
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> _show(int id, String title, String body) async {
    if (!_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'agri_alerts',
        'Farm Alerts',
        channelDescription: 'Rain, storm and spray-window alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  /// Evaluate the bundle and push notifications for active triggers.
  Future<void> evaluateAndNotify(WeatherBundle w) async {
    final next3 = w.nextHours(3);
    final rainSoon = next3.any((h) => h.precipProb >= 60 || h.precipMm >= 1);
    if (rainSoon) {
      await _show(1, 'Rain likely soon',
          'Rain expected within 3 hours at ${w.placeName}. Plan field work.');
    }

    final capeTonight = w.capeTonightMax;
    if (capeTonight >= FarmDecisions.capeHigh) {
      await _show(
          2,
          'Storm risk tonight',
          'CAPE ${capeTonight.toStringAsFixed(0)} J/kg. Possible flash runoff '
              'in low-lying fields — take precautions.');
    }

    final fd = FarmDecisions(w);
    final openWindow =
        fd.sprayWindows().where((s) => s.status == 'safe').toList();
    if (openWindow.isNotEmpty) {
      await _show(3, 'Spray window open',
          'Safe spray window ${openWindow.first.time}. Low rain risk and wind.');
    }
  }
}
