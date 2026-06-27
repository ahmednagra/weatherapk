import 'package:changi_agriweather/features/weather/domain/entities/hour_point.dart';
import 'package:changi_agriweather/features/weather/domain/entities/weather_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

HourPoint _step(DateTime t, double mm) => HourPoint(
      time: t,
      tempC: 0,
      rh: 0,
      precipProb: 0,
      precipMm: mm,
      cape: 0,
      soilMoisture: 0,
      et0: 0,
      vpd: 0,
      windKmh: 0,
      windDir: 0,
      weatherCode: 0,
    );

WeatherBundle _wb(List<HourPoint> minutely) => WeatherBundle(
      hours: const [],
      days: const [],
      models: const [],
      fetchedAt: DateTime(2024, 1, 1),
      agreement: null,
      placeName: 'test',
      lat: 0,
      lon: 0,
      minutely: minutely,
    );

void main() {
  group('nowcast getters', () {
    test('rainStartsInMin reports onset when currently dry', () {
      final now = DateTime.now();
      final b = _wb([
        _step(now.add(const Duration(minutes: 15)), 0.0),
        _step(now.add(const Duration(minutes: 30)), 0.0),
        _step(now.add(const Duration(minutes: 45)), 0.5),
      ]);
      final m = b.rainStartsInMin;
      expect(m, isNotNull);
      expect(m! >= 40 && m <= 50, isTrue);
      expect(b.rainStopsInMin, isNull); // not raining now
    });

    test('rainStopsInMin reports end when currently raining', () {
      final now = DateTime.now();
      final b = _wb([
        _step(now.add(const Duration(minutes: 5)), 0.6),
        _step(now.add(const Duration(minutes: 20)), 0.4),
        _step(now.add(const Duration(minutes: 35)), 0.0),
      ]);
      final m = b.rainStopsInMin;
      expect(m, isNotNull);
      expect(m! >= 30 && m <= 40, isTrue);
      expect(b.rainStartsInMin, isNull); // already raining
    });

    test('empty nowcast → both null', () {
      final b = _wb(const []);
      expect(b.rainStartsInMin, isNull);
      expect(b.rainStopsInMin, isNull);
    });
  });
}
