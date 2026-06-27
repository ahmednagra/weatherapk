import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';

/// Fetches and parses weather from Open-Meteo (free, no API key).
///
/// Two calls:
///   A) best_match single series -> rich agricultural fields (display)
///   B) multi-model precipitation -> 4-model comparison + agreement
class WeatherService {
  static const String _forecastBase = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherBundle> fetch({
    required double lat,
    required double lon,
    required String placeName,
  }) async {
    final richUri = Uri.parse('$_forecastBase'
        '?latitude=$lat&longitude=$lon&timezone=Asia%2FKarachi&forecast_days=7'
        '&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,'
        'precipitation,rain,cape,soil_moisture_0_to_1cm,'
        'et0_fao_evapotranspiration,vapour_pressure_deficit,'
        'wind_speed_10m,wind_direction_10m,weather_code'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
        'precipitation_sum,precipitation_probability_max');

    final modelUri = Uri.parse('$_forecastBase'
        '?latitude=$lat&longitude=$lon&timezone=Asia%2FKarachi&forecast_days=7'
        '&hourly=precipitation&daily=precipitation_sum'
        '&models=ecmwf_ifs025,gfs_seamless,icon_seamless,gem_seamless');

    final responses = await Future.wait([
      http.get(richUri).timeout(const Duration(seconds: 20)),
      http.get(modelUri).timeout(const Duration(seconds: 20)),
    ]);

    if (responses[0].statusCode != 200) {
      throw Exception('Forecast API error ${responses[0].statusCode}');
    }

    final rich = jsonDecode(responses[0].body) as Map<String, dynamic>;
    final hours = _parseHours(rich);
    final days = _parseDays(rich);

    List<ModelPrecip> models = [];
    double agreement = 0.7;
    if (responses[1].statusCode == 200) {
      final mj = jsonDecode(responses[1].body) as Map<String, dynamic>;
      models = _parseModels(mj);
      agreement = _computeAgreement(models);
    }

    return WeatherBundle(
      hours: hours,
      days: days,
      models: models,
      fetchedAt: DateTime.now(),
      agreement: agreement,
      placeName: placeName,
      lat: lat,
      lon: lon,
    );
  }

  List<HourPoint> _parseHours(Map<String, dynamic> j) {
    final h = j['hourly'] as Map<String, dynamic>;
    final times = (h['time'] as List).cast<String>();
    List<double> col(String k) {
      final l = h[k];
      if (l is List) {
        return l.map((e) => (e == null ? 0.0 : (e as num).toDouble())).toList();
      }
      return List<double>.filled(times.length, 0.0);
    }

    final t = col('temperature_2m');
    final rh = col('relative_humidity_2m');
    final pp = col('precipitation_probability');
    final pm = col('precipitation');
    final cape = col('cape');
    final sm = col('soil_moisture_0_to_1cm');
    final e0 = col('et0_fao_evapotranspiration');
    final vpd = col('vapour_pressure_deficit');
    final wk = col('wind_speed_10m');
    final wd = col('wind_direction_10m');
    final wcRaw = h['weather_code'];
    final wc = (wcRaw is List)
        ? wcRaw.map((e) => (e == null ? 0 : (e as num).toInt())).toList()
        : List<int>.filled(times.length, 0);

    final out = <HourPoint>[];
    for (var i = 0; i < times.length; i++) {
      out.add(HourPoint(
        time: DateTime.parse(times[i]),
        tempC: t[i],
        rh: rh[i],
        precipProb: pp[i],
        precipMm: pm[i],
        cape: cape[i],
        soilMoisture: sm[i],
        et0: e0[i],
        vpd: vpd[i],
        windKmh: wk[i],
        windDir: wd[i],
        weatherCode: wc[i],
      ));
    }
    return out;
  }

  List<DayPoint> _parseDays(Map<String, dynamic> j) {
    final d = j['daily'] as Map<String, dynamic>;
    final dates = (d['time'] as List).cast<String>();
    List<double> col(String k) {
      final l = d[k];
      if (l is List) {
        return l.map((e) => (e == null ? 0.0 : (e as num).toDouble())).toList();
      }
      return List<double>.filled(dates.length, 0.0);
    }

    final wcRaw = d['weather_code'];
    final wc = (wcRaw is List)
        ? wcRaw.map((e) => (e == null ? 0 : (e as num).toInt())).toList()
        : List<int>.filled(dates.length, 0);
    final mx = col('temperature_2m_max');
    final mn = col('temperature_2m_min');
    final ps = col('precipitation_sum');
    final ppm = col('precipitation_probability_max');

    final out = <DayPoint>[];
    for (var i = 0; i < dates.length; i++) {
      out.add(DayPoint(
        date: DateTime.parse(dates[i]),
        weatherCode: wc[i],
        tMax: mx[i],
        tMin: mn[i],
        precipSum: ps[i],
        precipProbMax: ppm[i],
      ));
    }
    return out;
  }

  List<ModelPrecip> _parseModels(Map<String, dynamic> j) {
    final h = j['hourly'] as Map<String, dynamic>;
    final d = j['daily'] as Map<String, dynamic>;
    final times = (h['time'] as List).cast<String>();
    final now = DateTime.now();

    final defs = {
      'ECMWF': 'ecmwf_ifs025',
      'GFS': 'gfs_seamless',
      'ICON': 'icon_seamless',
      'GEM': 'gem_seamless',
    };

    final out = <ModelPrecip>[];
    defs.forEach((label, suffix) {
      final hourly = h['precipitation_$suffix'];
      final daily = d['precipitation_sum_$suffix'];

      double next24 = 0;
      if (hourly is List) {
        for (var i = 0; i < times.length; i++) {
          final t = DateTime.parse(times[i]);
          if (t.isAfter(now) &&
              t.isBefore(now.add(const Duration(hours: 24)))) {
            final v = hourly[i];
            if (v != null) next24 += (v as num).toDouble();
          }
        }
      }

      final dailySums = <double>[];
      if (daily is List) {
        for (final v in daily) {
          dailySums.add(v == null ? 0.0 : (v as num).toDouble());
        }
      }

      out.add(ModelPrecip(
        key: label,
        next24hSum: next24,
        dailySums: dailySums,
      ));
    });
    return out;
  }

  /// Agreement = 1 - normalized spread of the 4 models' 24h totals.
  double _computeAgreement(List<ModelPrecip> models) {
    if (models.isEmpty) return 0.7;
    final vals = models.map((m) => m.next24hSum).toList();
    final maxV = vals.reduce((a, b) => a > b ? a : b);
    final minV = vals.reduce((a, b) => a < b ? a : b);
    final mean = vals.reduce((a, b) => a + b) / vals.length;
    if (mean < 0.5) return 0.9; // all near-dry => high agreement
    final spread = (maxV - minV) / (mean + 1);
    final agree = (1 - spread).clamp(0.2, 0.98);
    return agree.toDouble();
  }
}
