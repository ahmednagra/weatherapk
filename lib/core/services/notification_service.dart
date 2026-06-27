import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/farm/domain/farm_decisions.dart';
import '../../features/weather/domain/entities/weather_bundle.dart';

/// Local farm-alert notifications. Evaluated when a fresh forecast loads.
/// Fixed notification IDs so each alert replaces (not stacks) on refresh.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
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
        channelDescription: 'Rain, storm, frost and spray-window alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  Future<void> evaluateAndNotify(WeatherBundle w) async {
    final next3 = w.nextHours(3);
    if (next3.any((h) => h.precipProb >= 60 || h.precipMm >= 1)) {
      await _show(1, 'Rain likely soon',
          'Rain expected within 3 hours at ${w.placeName}. Plan field work.');
    }

    final capeTonight = w.capeTonightMax;
    if (capeTonight >= FarmDecisions.capeHigh) {
      await _show(2, 'Storm risk tonight',
          'CAPE ${capeTonight.toStringAsFixed(0)} J/kg. Possible flash runoff '
              'in low-lying fields — take precautions.');
    }

    final fd = FarmDecisions(w);
    final open = fd.sprayWindows().where((s) => s.status == 'safe').toList();
    if (open.isNotEmpty) {
      await _show(3, 'Spray window open',
          'Safe spray window ${open.first.time}. Low rain risk and wind.');
    }

    for (final d in w.days.take(7)) {
      if (d.tMin <= FarmDecisions.frostThreshold) {
        await _show(4, 'Frost risk ahead',
            'Forecast low ${d.tMin.toStringAsFixed(0)}°C. Protect sensitive '
                'crops; canopy can run colder than the screen reading.');
        break;
      }
    }
  }
}
