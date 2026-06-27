import 'package:changi_agriweather/features/weather/domain/entities/hour_point.dart';
import 'package:changi_agriweather/features/weather/domain/entities/temp_bias.dart';
import 'package:changi_agriweather/features/weather/domain/entities/weather_bundle.dart';
import 'package:changi_agriweather/features/weather/domain/services/bias_corrector.dart';
import 'package:flutter_test/flutter_test.dart';

HourPoint _hp(DateTime t,
        {double temp = 20, double rh = 50, double pp = 0, double pm = 0}) =>
    HourPoint(
      time: t,
      tempC: temp,
      rh: rh,
      precipProb: pp,
      precipMm: pm,
      cape: 0,
      soilMoisture: 0,
      et0: 0,
      vpd: 0,
      windKmh: 0,
      windDir: 0,
      weatherCode: 0,
    );

WeatherBundle _wb(List<HourPoint> hours) => WeatherBundle(
      hours: hours,
      days: const [],
      models: const [],
      fetchedAt: DateTime(2024, 1, 1),
      agreement: null,
      placeName: 'test',
      lat: 0,
      lon: 0,
    );

void main() {
  final t = DateTime(2024, 1, 1, 12); // daytime

  group('skill-weighted ensemble', () {
    test('unseeded → equal weights', () {
      final w = BiasCorrector.weights(const TempBias(), ['A', 'B']);
      expect(w['A'], closeTo(0.5, 1e-9));
      expect(w['B'], closeTo(0.5, 1e-9));
    });

    test('accurate model earns the higher weight', () {
      final modelTemps = {
        'A': {t: 20.0}, // matches observation
        'B': {t: 30.0}, // 10° off
      };
      final b = BiasCorrector.learnModelErr(const TempBias(), modelTemps, 20, t);
      final w = BiasCorrector.weights(b, modelTemps.keys);
      expect(w['A']! > w['B']!, isTrue);
    });

    test('weighted blend pulls toward the accurate model', () {
      final modelTemps = {
        'A': {t: 20.0},
        'B': {t: 30.0},
      };
      final b = BiasCorrector.learnModelErr(const TempBias(), modelTemps, 20, t);
      final w = BiasCorrector.weights(b, modelTemps.keys);
      final blended =
          BiasCorrector.blendTempsWeighted(_wb([_hp(t, temp: 25)]), modelTemps, w);
      expect(blended.hours.first.tempC < 25, isTrue); // closer to 20 than 25
    });
  });

  group('temperature bias', () {
    test('learns and subtracts a warm bias', () {
      var b = const TempBias();
      // forecast 22, observed 20 → +2 warm bias
      final err = BiasCorrector.errorAt(_wb([_hp(t, temp: 22)]), 20, t);
      b = BiasCorrector.update(b, err!, t);
      final out = BiasCorrector.apply(_wb([_hp(t, temp: 22)]), b);
      expect(out.hours.first.tempC < 22, isTrue);
    });
  });

  group('humidity', () {
    test('rhFromDewpoint is 100% when temp equals dew point', () {
      expect(BiasCorrector.rhFromDewpoint(20, 20), closeTo(100, 0.5));
    });

    test('learns and subtracts an RH bias, clamped to 0–100', () {
      var b = const TempBias();
      final err = BiasCorrector.rhErrorAt(_wb([_hp(t, rh: 70)]), 50, t); // +20
      b = BiasCorrector.updateRh(b, err!, t);
      final out = BiasCorrector.applyRh(_wb([_hp(t, rh: 70)]), b);
      expect(out.hours.first.rh < 70, isTrue);
      expect(out.hours.first.rh >= 0 && out.hours.first.rh <= 100, isTrue);
    });
  });

  group('precip-probability calibration', () {
    test('mapping stays monotone even with inverted bins', () {
      final b = TempBias(
        // bin0 high, bin9 low → inverted on purpose
        precipDeciles: [0.8, -1, -1, -1, -1, -1, -1, -1, -1, 0.1],
      );
      final out =
          BiasCorrector.applyCal(_wb([_hp(t, pp: 5), _hp(t, pp: 95)]), b);
      expect(out.hours[0].precipProb <= out.hours[1].precipProb, isTrue);
    });

    test('no-op until a bin is seeded', () {
      final out = BiasCorrector.applyCal(_wb([_hp(t, pp: 40)]), const TempBias());
      expect(out.hours.first.precipProb, 40);
    });
  });
}
