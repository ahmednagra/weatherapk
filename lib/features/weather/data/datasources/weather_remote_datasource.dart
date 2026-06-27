import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/day_point.dart';
import '../../domain/entities/hour_point.dart';
import '../../domain/entities/model_precip.dart';
import '../../domain/entities/weather_bundle.dart';

/// Open-Meteo forecast source. Two calls: a rich best-match series for the
/// agricultural fields, and a multi-model call whose temperature is blended
/// (equal weight) over the best-match temperature. No API key.
abstract class WeatherRemoteDataSource {
  Future<WeatherBundle> fetchForecast({
    required double lat,
    required double lon,
    required String placeName,
  });
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final Dio _dio;
  const WeatherRemoteDataSourceImpl(this._dio);

  @override
  Future<WeatherBundle> fetchForecast({
    required double lat,
    required double lon,
    required String placeName,
  }) async {
    final richUri = '${ApiConstants.openMeteoForecast}'
        '?latitude=$lat&longitude=$lon&timezone=Asia%2FKarachi'
        '&forecast_days=${ApiConstants.forecastDays}'
        '&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,'
        'precipitation,rain,cape,soil_moisture_0_to_1cm,'
        'et0_fao_evapotranspiration,vapour_pressure_deficit,'
        'wind_speed_10m,wind_direction_10m,weather_code'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
        'precipitation_sum,precipitation_probability_max';

    final modelUri = '${ApiConstants.openMeteoForecast}'
        '?latitude=$lat&longitude=$lon&timezone=Asia%2FKarachi'
        '&forecast_days=${ApiConstants.forecastDays}'
        '&hourly=precipitation,temperature_2m&daily=precipitation_sum'
        '&models=${ApiConstants.forecastModels}';

    final Map<String, dynamic> rich;
    try {
      final res = await _dio.get(richUri);
      rich = _asMap(res.data);
    } on DioException catch (e) {
      throw ServerException('Forecast request failed',
          statusCode: e.response?.statusCode);
    }

    var hours = _parseHours(rich);
    final days = _parseDays(rich);

    List<ModelPrecip> models = [];
    double? agreement; // null until a real multi-model spread is computed
    try {
      final res = await _dio.get(modelUri);
      final mj = _asMap(res.data);
      models = _parseModels(mj);
      agreement = _computeAgreement(models);
      final blend = _blendModelTemps(mj);
      if (blend.isNotEmpty) {
        hours = [
          for (final h in hours) h.copyWith(tempC: blend[h.time] ?? h.tempC)
        ];
      }
    } catch (_) {
      // Multi-model call is optional — degrade to best-match cleanly.
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

  static Map<String, dynamic> _asMap(dynamic data) => data is String
      ? Map<String, dynamic>.from(jsonDecode(data) as Map)
      : data as Map<String, dynamic>;

  List<HourPoint> _parseHours(Map<String, dynamic> j) {
    final h = j['hourly'] as Map<String, dynamic>;
    final times = (h['time'] as List).cast<String>();
    List<double> col(String k) {
      final l = h[k];
      return l is List
          ? l.map((e) => e == null ? 0.0 : (e as num).toDouble()).toList()
          : List<double>.filled(times.length, 0.0);
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
    final wc = wcRaw is List
        ? wcRaw.map((e) => e == null ? 0 : (e as num).toInt()).toList()
        : List<int>.filled(times.length, 0);

    return [
      for (var i = 0; i < times.length; i++)
        HourPoint(
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
        ),
    ];
  }

  List<DayPoint> _parseDays(Map<String, dynamic> j) {
    final d = j['daily'] as Map<String, dynamic>;
    final dates = (d['time'] as List).cast<String>();
    List<double> col(String k) {
      final l = d[k];
      return l is List
          ? l.map((e) => e == null ? 0.0 : (e as num).toDouble()).toList()
          : List<double>.filled(dates.length, 0.0);
    }

    final wcRaw = d['weather_code'];
    final wc = wcRaw is List
        ? wcRaw.map((e) => e == null ? 0 : (e as num).toInt()).toList()
        : List<int>.filled(dates.length, 0);
    final mx = col('temperature_2m_max');
    final mn = col('temperature_2m_min');
    final ps = col('precipitation_sum');
    final ppm = col('precipitation_probability_max');

    return [
      for (var i = 0; i < dates.length; i++)
        DayPoint(
          date: DateTime.parse(dates[i]),
          weatherCode: wc[i],
          tMax: mx[i],
          tMin: mn[i],
          precipSum: ps[i],
          precipProbMax: ppm[i],
        ),
    ];
  }

  List<ModelPrecip> _parseModels(Map<String, dynamic> j) {
    final h = j['hourly'] as Map<String, dynamic>;
    final d = j['daily'] as Map<String, dynamic>;
    final times = (h['time'] as List).cast<String>();
    final now = DateTime.now();
    const labels = {
      'ECMWF': 'ecmwf_ifs025',
      'GFS': 'gfs_seamless',
      'ICON': 'icon_seamless',
      'GEM': 'gem_seamless',
    };

    final out = <ModelPrecip>[];
    labels.forEach((label, suffix) {
      final hourly = h['precipitation_$suffix'];
      final daily = d['precipitation_sum_$suffix'];
      double next24 = 0;
      if (hourly is List) {
        for (var i = 0; i < times.length; i++) {
          final tt = DateTime.parse(times[i]);
          if (tt.isAfter(now) &&
              tt.isBefore(now.add(const Duration(hours: 24))) &&
              hourly[i] != null) {
            next24 += (hourly[i] as num).toDouble();
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
          key: label, next24hSum: next24, dailySums: dailySums));
    });
    return out;
  }

  Map<DateTime, double> _blendModelTemps(Map<String, dynamic> j) {
    final h = j['hourly'];
    if (h is! Map<String, dynamic>) return {};
    final times = (h['time'] as List?)?.cast<String>() ?? [];
    final cols = [
      for (final s in ApiConstants.modelSuffixes) h['temperature_2m_$s']
    ];
    final out = <DateTime, double>{};
    for (var i = 0; i < times.length; i++) {
      double sum = 0;
      int n = 0;
      for (final c in cols) {
        if (c is List && i < c.length && c[i] != null) {
          sum += (c[i] as num).toDouble();
          n++;
        }
      }
      if (n > 0) out[DateTime.parse(times[i])] = sum / n;
    }
    return out;
  }

  double _computeAgreement(List<ModelPrecip> models) {
    if (models.isEmpty) return 0.7;
    final vals = models.map((m) => m.next24hSum).toList();
    final maxV = vals.reduce((a, b) => a > b ? a : b);
    final minV = vals.reduce((a, b) => a < b ? a : b);
    final mean = vals.reduce((a, b) => a + b) / vals.length;
    if (mean < 0.5) return 0.9;
    final spread = (maxV - minV) / (mean + 1);
    return (1 - spread).clamp(0.2, 0.98).toDouble();
  }
}
