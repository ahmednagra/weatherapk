import 'package:equatable/equatable.dart';
import 'day_point.dart';
import 'hour_point.dart';
import 'metar_obs.dart';
import 'model_precip.dart';

/// The full forecast snapshot the whole app renders. Business getters live here
/// (current hour, next-N windows, sums); parsing/serialisation is in the DTO.
class WeatherBundle extends Equatable {
  final List<HourPoint> hours;
  final List<DayPoint> days;
  final List<ModelPrecip> models;
  final DateTime fetchedAt;
  final double? agreement; // 0..1 model convergence; null = not available
  final String placeName;
  final double lat;
  final double lon;
  final MetarObs? observed; // live ground truth, if any
  final List<HourPoint> minutely; // 15-min precip nowcast (next ~2h)

  const WeatherBundle({
    required this.hours,
    required this.days,
    required this.models,
    required this.fetchedAt,
    required this.agreement,
    required this.placeName,
    required this.lat,
    required this.lon,
    this.observed,
    this.minutely = const [],
  });

  WeatherBundle copyWith({
    List<HourPoint>? hours,
    List<DayPoint>? days,
    MetarObs? observed,
    List<HourPoint>? minutely,
  }) =>
      WeatherBundle(
        hours: hours ?? this.hours,
        days: days ?? this.days,
        models: models,
        fetchedAt: fetchedAt,
        agreement: agreement,
        placeName: placeName,
        lat: lat,
        lon: lon,
        observed: observed ?? this.observed,
        minutely: minutely ?? this.minutely,
      );

  /// Minutes until precipitation begins (≥0.1 mm in a 15-min step), or null if
  /// it's already raining / no rain in the nowcast window.
  int? get rainStartsInMin {
    if (minutely.isEmpty) return null;
    final now = DateTime.now();
    final future = minutely.where((s) => s.time.isAfter(now)).toList();
    if (future.isEmpty || future.first.precipMm >= 0.1) return null;
    for (final s in future) {
      if (s.precipMm >= 0.1) {
        final m = s.time.difference(now).inMinutes;
        return m < 0 ? 0 : m;
      }
    }
    return null;
  }

  /// Minutes until precipitation stops, only meaningful when raining now.
  int? get rainStopsInMin {
    if (minutely.isEmpty) return null;
    final now = DateTime.now();
    final future = minutely.where((s) => !s.time.isBefore(now)).toList();
    if (future.isEmpty || future.first.precipMm < 0.1) return null;
    for (final s in future) {
      if (s.precipMm < 0.1) {
        final m = s.time.difference(now).inMinutes;
        return m < 0 ? 0 : m;
      }
    }
    return null;
  }

  /// Temperature to show for "now": live station reading when fresh, otherwise
  /// the (bias-corrected) nearest forecast hour.
  double get displayCurrentTempC =>
      (observed != null && observed!.isFresh) ? observed!.tempC : current.tempC;

  /// Hour nearest to "now" (safe stub if the series is somehow empty).
  HourPoint get current {
    if (hours.isEmpty) {
      return HourPoint(
        time: DateTime.now(),
        tempC: 0,
        rh: 0,
        precipProb: 0,
        precipMm: 0,
        cape: 0,
        soilMoisture: 0,
        et0: 0,
        vpd: 0,
        windKmh: 0,
        windDir: 0,
        weatherCode: 3,
      );
    }
    final now = DateTime.now();
    HourPoint best = hours.first;
    Duration bestDiff = hours.first.time.difference(now).abs();
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

  double get rain24h => nextHours(24).fold(0.0, (a, h) => a + h.precipMm);

  double get capeTonightMax {
    final now = DateTime.now();
    double mx = 0;
    for (final h in hours) {
      if (h.time.isAfter(now) &&
          h.time.isBefore(now.add(const Duration(hours: 12))) &&
          h.cape > mx) {
        mx = h.cape;
      }
    }
    return mx;
  }

  @override
  List<Object?> get props => [
        hours,
        days,
        models,
        fetchedAt,
        agreement,
        placeName,
        lat,
        lon,
        observed,
        minutely,
      ];
}
