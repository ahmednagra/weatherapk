import '../entities/hour_point.dart';
import '../entities/temp_bias.dart';
import '../entities/weather_bundle.dart';

/// Pure decaying-average (constant-gain Kalman) temperature bias correction.
/// No IO — the repository owns load/save of [TempBias]; this is just the maths.
///
///   bias  = (1-w)*bias + w*(forecast - observed)
///   shown = forecast - bias
class BiasCorrector {
  BiasCorrector._();

  static const double w = 0.1; // ~19-observation memory
  static const double clamp = 10.0; // reject obviously-bad pairs

  static bool isDay(DateTime t) => t.hour >= 6 && t.hour < 18;

  /// Error of the raw forecast vs an observation, at the nearest aligned hour.
  /// Returns null when no forecast hour is within 2h of the observation.
  static double? errorAt(WeatherBundle raw, double observedTemp, DateTime obsTime) {
    if (raw.hours.isEmpty) return null;
    HourPoint near = raw.hours.first;
    Duration best = near.time.difference(obsTime).abs();
    for (final h in raw.hours) {
      final d = h.time.difference(obsTime).abs();
      if (d < best) {
        best = d;
        near = h;
      }
    }
    if (best > const Duration(hours: 2)) return null;
    return near.tempC - observedTemp;
  }

  /// Fold one error into the running bias for the relevant day/night bucket.
  static TempBias update(TempBias b, double error, DateTime obsTime) {
    final e = error.clamp(-clamp, clamp).toDouble();
    if (isDay(obsTime)) {
      return b.copyWith(day: b.seeded ? (1 - w) * b.day + w * e : e, seeded: true);
    }
    return b.copyWith(night: b.seeded ? (1 - w) * b.night + w * e : e, seeded: true);
  }

  /// Corrected copy of the bundle (subtract learned bias from all temps).
  static WeatherBundle apply(WeatherBundle bundle, TempBias b) {
    if (!b.active) return bundle;
    final hours = bundle.hours
        .map((h) => h.copyWith(tempC: h.tempC - (isDay(h.time) ? b.day : b.night)))
        .toList();
    final days = bundle.days
        .map((d) => d.copyWith(tMax: d.tMax - b.day, tMin: d.tMin - b.night))
        .toList();
    return bundle.copyWith(hours: hours, days: days);
  }
}
