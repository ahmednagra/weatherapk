import 'package:changi_agriweather/features/farm/domain/entities/farm_models.dart';
import 'package:changi_agriweather/features/farm/domain/farm_decisions.dart';
import 'package:changi_agriweather/features/weather/domain/entities/day_point.dart';
import 'package:changi_agriweather/features/weather/domain/entities/hour_point.dart';
import 'package:changi_agriweather/features/weather/domain/entities/weather_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

WeatherBundle _bundle({required double tMin}) {
  final now = DateTime(2024, 1, 1, 12);
  final hours = [
    HourPoint(
      time: now,
      tempC: 18,
      rh: 50,
      precipProb: 0,
      precipMm: 0,
      cape: 0,
      soilMoisture: 0.2,
      et0: 1,
      vpd: 1,
      windKmh: 5,
      windDir: 0,
      weatherCode: 0,
    ),
  ];
  final days = [
    for (var i = 0; i < 7; i++)
      DayPoint(
        date: now.add(Duration(days: i)),
        weatherCode: 0,
        tMax: 25,
        tMin: tMin,
        precipSum: 0,
        precipProbMax: 0,
      ),
  ];
  return WeatherBundle(
    hours: hours,
    days: days,
    models: const [],
    fetchedAt: now,
    agreement: null,
    placeName: 'test',
    lat: 0,
    lon: 0,
  );
}

void main() {
  group('crop profiles', () {
    test('thresholds come from the active profile', () {
      final w = _bundle(tMin: 5);
      expect(FarmDecisions(w, profile: CropProfile.wheat).frostThreshold, 2);
      expect(FarmDecisions(w, profile: CropProfile.rice).frostThreshold, 8);
      expect(FarmDecisions(w, profile: CropProfile.wheat).gddBase, 0);
      expect(FarmDecisions(w, profile: CropProfile.rice).gddBase, 10);
    });

    test('frost advisory respects the crop (tMin=5°C)', () {
      final w = _bundle(tMin: 5);
      bool hasFrost(CropProfile p) => FarmDecisions(w, profile: p)
          .actions()
          .any((a) => a.title.toLowerCase().contains('frost'));
      expect(hasFrost(CropProfile.wheat), isFalse); // 5 > 2
      expect(hasFrost(CropProfile.rice), isTrue); // 5 ≤ 8
    });

    test('byId falls back to wheat', () {
      expect(CropProfile.byId('nope').id, 'wheat');
      expect(CropProfile.byId('rice').id, 'rice');
    });
  });
}
