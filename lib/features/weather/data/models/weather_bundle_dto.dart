import '../../domain/entities/day_point.dart';
import '../../domain/entities/hour_point.dart';
import '../../domain/entities/metar_obs.dart';
import '../../domain/entities/model_precip.dart';
import '../../domain/entities/weather_bundle.dart';

/// Serialisation boundary between the domain entities (JSON-free) and the cache.
/// Keeps the entities clean while persisting a compact JSON shape to Hive.
class WeatherBundleDto {
  WeatherBundleDto._();

  static Map<String, dynamic> toJson(WeatherBundle b) => {
        'hours': b.hours.map(_hourToJson).toList(),
        'days': b.days.map(_dayToJson).toList(),
        'models': b.models.map(_modelToJson).toList(),
        'fetchedAt': b.fetchedAt.toIso8601String(),
        'agreement': b.agreement,
        'placeName': b.placeName,
        'lat': b.lat,
        'lon': b.lon,
        'observed': b.observed == null ? null : _metarToJson(b.observed!),
      };

  static WeatherBundle fromJson(Map<String, dynamic> j) => WeatherBundle(
        hours: (j['hours'] as List).map((e) => _hourFromJson(e)).toList(),
        days: (j['days'] as List).map((e) => _dayFromJson(e)).toList(),
        models: (j['models'] as List).map((e) => _modelFromJson(e)).toList(),
        fetchedAt: DateTime.parse(j['fetchedAt']),
        agreement: (j['agreement'] as num?)?.toDouble(),
        placeName: j['placeName'] ?? 'Changi Village',
        lat: (j['lat'] ?? 32.145).toDouble(),
        lon: (j['lon'] ?? 74.526).toDouble(),
        observed: j['observed'] == null
            ? null
            : _metarFromJson(j['observed'] as Map<String, dynamic>),
      );

  static Map<String, dynamic> _hourToJson(HourPoint h) => {
        't': h.time.toIso8601String(),
        'tc': h.tempC,
        'rh': h.rh,
        'pp': h.precipProb,
        'pm': h.precipMm,
        'cp': h.cape,
        'sm': h.soilMoisture,
        'e0': h.et0,
        'vp': h.vpd,
        'wk': h.windKmh,
        'wd': h.windDir,
        'wc': h.weatherCode,
      };

  static HourPoint _hourFromJson(Map<String, dynamic> j) => HourPoint(
        time: DateTime.parse(j['t']),
        tempC: (j['tc'] ?? 0).toDouble(),
        rh: (j['rh'] ?? 0).toDouble(),
        precipProb: (j['pp'] ?? 0).toDouble(),
        precipMm: (j['pm'] ?? 0).toDouble(),
        cape: (j['cp'] ?? 0).toDouble(),
        soilMoisture: (j['sm'] ?? 0).toDouble(),
        et0: (j['e0'] ?? 0).toDouble(),
        vpd: (j['vp'] ?? 0).toDouble(),
        windKmh: (j['wk'] ?? 0).toDouble(),
        windDir: (j['wd'] ?? 0).toDouble(),
        weatherCode: (j['wc'] ?? 0).toInt(),
      );

  static Map<String, dynamic> _dayToJson(DayPoint d) => {
        'd': d.date.toIso8601String(),
        'wc': d.weatherCode,
        'mx': d.tMax,
        'mn': d.tMin,
        'ps': d.precipSum,
        'pp': d.precipProbMax,
      };

  static DayPoint _dayFromJson(Map<String, dynamic> j) => DayPoint(
        date: DateTime.parse(j['d']),
        weatherCode: (j['wc'] ?? 0).toInt(),
        tMax: (j['mx'] ?? 0).toDouble(),
        tMin: (j['mn'] ?? 0).toDouble(),
        precipSum: (j['ps'] ?? 0).toDouble(),
        precipProbMax: (j['pp'] ?? 0).toDouble(),
      );

  static Map<String, dynamic> _modelToJson(ModelPrecip m) =>
      {'k': m.key, 'n': m.next24hSum, 'd': m.dailySums};

  static ModelPrecip _modelFromJson(Map<String, dynamic> j) => ModelPrecip(
        key: j['k'],
        next24hSum: (j['n'] ?? 0).toDouble(),
        dailySums:
            (j['d'] as List).map((e) => (e ?? 0).toDouble()).cast<double>().toList(),
      );

  static Map<String, dynamic> _metarToJson(MetarObs m) => {
        'st': m.station,
        'tc': m.tempC,
        'dp': m.dewpC,
        'wk': m.windKmh,
        't': m.time.toIso8601String(),
      };

  static MetarObs _metarFromJson(Map<String, dynamic> j) => MetarObs(
        station: j['st'] ?? 'OPST',
        tempC: (j['tc'] ?? 0).toDouble(),
        dewpC: (j['dp'] ?? 0).toDouble(),
        windKmh: (j['wk'] ?? 0).toDouble(),
        time: DateTime.parse(j['t']),
      );
}
