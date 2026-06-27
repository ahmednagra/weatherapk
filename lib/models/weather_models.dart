/// Parsed weather structures used across all screens.

class HourPoint {
  final DateTime time;
  final double tempC;
  final double rh;
  final double precipProb;
  final double precipMm;
  final double cape;
  final double soilMoisture;
  final double et0;
  final double vpd;
  final double windKmh;
  final double windDir;
  final int weatherCode;

  HourPoint({
    required this.time,
    required this.tempC,
    required this.rh,
    required this.precipProb,
    required this.precipMm,
    required this.cape,
    required this.soilMoisture,
    required this.et0,
    required this.vpd,
    required this.windKmh,
    required this.windDir,
    required this.weatherCode,
  });

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'tc': tempC,
        'rh': rh,
        'pp': precipProb,
        'pm': precipMm,
        'cp': cape,
        'sm': soilMoisture,
        'e0': et0,
        'vp': vpd,
        'wk': windKmh,
        'wd': windDir,
        'wc': weatherCode,
      };

  factory HourPoint.fromJson(Map<String, dynamic> j) => HourPoint(
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
}

class DayPoint {
  final DateTime date;
  final int weatherCode;
  final double tMax;
  final double tMin;
  final double precipSum;
  final double precipProbMax;

  DayPoint({
    required this.date,
    required this.weatherCode,
    required this.tMax,
    required this.tMin,
    required this.precipSum,
    required this.precipProbMax,
  });

  Map<String, dynamic> toJson() => {
        'd': date.toIso8601String(),
        'wc': weatherCode,
        'mx': tMax,
        'mn': tMin,
        'ps': precipSum,
        'pp': precipProbMax,
      };

  factory DayPoint.fromJson(Map<String, dynamic> j) => DayPoint(
        date: DateTime.parse(j['d']),
        weatherCode: (j['wc'] ?? 0).toInt(),
        tMax: (j['mx'] ?? 0).toDouble(),
        tMin: (j['mn'] ?? 0).toDouble(),
        precipSum: (j['ps'] ?? 0).toDouble(),
        precipProbMax: (j['pp'] ?? 0).toDouble(),
      );
}

class ModelPrecip {
  final String key; // 'ECMWF', 'ICON', 'GFS', 'GEM'
  final double next24hSum;
  final List<double> dailySums; // up to 7

  ModelPrecip({
    required this.key,
    required this.next24hSum,
    required this.dailySums,
  });

  Map<String, dynamic> toJson() =>
      {'k': key, 'n': next24hSum, 'd': dailySums};

  factory ModelPrecip.fromJson(Map<String, dynamic> j) => ModelPrecip(
        key: j['k'],
        next24hSum: (j['n'] ?? 0).toDouble(),
        dailySums:
            (j['d'] as List).map((e) => (e ?? 0).toDouble()).toList(),
      );
}

class WeatherBundle {
  final List<HourPoint> hours;
  final List<DayPoint> days;
  final List<ModelPrecip> models;
  final DateTime fetchedAt;
  final double agreement; // 0..1, model convergence
  final String placeName;
  final double lat;
  final double lon;

  WeatherBundle({
    required this.hours,
    required this.days,
    required this.models,
    required this.fetchedAt,
    required this.agreement,
    required this.placeName,
    required this.lat,
    required this.lon,
  });

  /// Hour nearest to "now".
  HourPoint get current {
    final now = DateTime.now();
    HourPoint best = hours.first;
    Duration bestDiff = (hours.first.time.difference(now)).abs();
    for (final h in hours) {
      final d = h.time.difference(now).abs();
      if (d < bestDiff) {
        bestDiff = d;
        best = h;
      }
    }
    return best;
  }

  /// Next N hours from now.
  List<HourPoint> nextHours(int n) {
    final now = DateTime.now();
    final future = hours.where((h) => h.time.isAfter(now)).toList();
    if (future.length >= n) return future.take(n).toList();
    return hours.take(n).toList();
  }

  double get rain24h {
    final next = nextHours(24);
    return next.fold(0.0, (a, h) => a + h.precipMm);
  }

  double get capeTonightMax {
    final now = DateTime.now();
    final tonight = hours.where((h) =>
        h.time.isAfter(now) &&
        h.time.isBefore(now.add(const Duration(hours: 12))));
    double mx = 0;
    for (final h in tonight) {
      if (h.cape > mx) mx = h.cape;
    }
    return mx;
  }

  Map<String, dynamic> toJson() => {
        'hours': hours.map((e) => e.toJson()).toList(),
        'days': days.map((e) => e.toJson()).toList(),
        'models': models.map((e) => e.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
        'agreement': agreement,
        'placeName': placeName,
        'lat': lat,
        'lon': lon,
      };

  factory WeatherBundle.fromJson(Map<String, dynamic> j) => WeatherBundle(
        hours: (j['hours'] as List)
            .map((e) => HourPoint.fromJson(e))
            .toList(),
        days:
            (j['days'] as List).map((e) => DayPoint.fromJson(e)).toList(),
        models: (j['models'] as List)
            .map((e) => ModelPrecip.fromJson(e))
            .toList(),
        fetchedAt: DateTime.parse(j['fetchedAt']),
        agreement: (j['agreement'] ?? 0).toDouble(),
        placeName: j['placeName'] ?? 'Changi Village',
        lat: (j['lat'] ?? 32.145).toDouble(),
        lon: (j['lon'] ?? 74.526).toDouble(),
      );
}
