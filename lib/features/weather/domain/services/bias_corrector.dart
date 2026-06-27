import 'dart:math' as math;

import '../entities/hour_point.dart';
import '../entities/temp_bias.dart';
import '../entities/weather_bundle.dart';

/// Pure ground-truth corrections — the single home for all forecast-adjustment
/// maths (DRY). The repository owns load/save of [TempBias]; everything here is
/// stateless.
///
///   bias  = (1-w)*bias + w*(forecast - observed)   →   shown = forecast - bias
///   skill = inverse of each model's decaying mean-absolute error
///   cal   = remap forecast probability through its observed hit-rate
class BiasCorrector {
  BiasCorrector._();

  static const double w = 0.1; // ~19-observation memory
  static const double clamp = 10.0; // reject obviously-bad temp pairs (°C)
  static const double rhClamp = 40.0; // reject obviously-bad humidity pairs (%)

  static bool isDay(DateTime t) => t.hour >= 6 && t.hour < 18;

  // ── Nearest-hour helpers ────────────────────────────────────────────────

  /// The hour nearest [obsTime] within 2h, or null.
  static HourPoint? _nearestHour(WeatherBundle b, DateTime obsTime) {
    if (b.hours.isEmpty) return null;
    HourPoint near = b.hours.first;
    Duration best = near.time.difference(obsTime).abs();
    for (final h in b.hours) {
      final d = h.time.difference(obsTime).abs();
      if (d < best) {
        best = d;
        near = h;
      }
    }
    return best > const Duration(hours: 2) ? null : near;
  }

  /// Temp error of the raw forecast vs an observation, at the nearest hour.
  static double? errorAt(WeatherBundle raw, double observedTemp, DateTime obsTime) {
    final h = _nearestHour(raw, obsTime);
    return h == null ? null : h.tempC - observedTemp;
  }

  /// Forecast precipitation probability at the hour nearest [obsTime].
  static double? precipProbAt(WeatherBundle b, DateTime obsTime) {
    final h = _nearestHour(b, obsTime);
    return h?.precipProb;
  }

  // ── Temperature bias ────────────────────────────────────────────────────

  /// Fold one temp error into the running bias for the day/night bucket.
  static TempBias update(TempBias b, double error, DateTime obsTime) {
    final e = error.clamp(-clamp, clamp).toDouble();
    if (isDay(obsTime)) {
      return b.copyWith(day: b.seeded ? (1 - w) * b.day + w * e : e, seeded: true);
    }
    return b.copyWith(night: b.seeded ? (1 - w) * b.night + w * e : e, seeded: true);
  }

  /// Subtract the learned temperature bias from all temps.
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

  // ── Humidity bias ───────────────────────────────────────────────────────

  /// Relative humidity (%) from temperature and dew point (Magnus formula).
  static double rhFromDewpoint(double tC, double tdC) {
    const a = 17.625, b = 243.04;
    final num = math.exp((a * tdC) / (b + tdC));
    final den = math.exp((a * tC) / (b + tC));
    return (100 * num / den).clamp(0, 100).toDouble();
  }

  /// RH error of the raw forecast vs an observation, at the nearest hour.
  static double? rhErrorAt(WeatherBundle raw, double observedRh, DateTime obsTime) {
    final h = _nearestHour(raw, obsTime);
    return h == null ? null : h.rh - observedRh;
  }

  /// Fold one RH error into the running humidity bias.
  static TempBias updateRh(TempBias b, double error, DateTime obsTime) {
    final e = error.clamp(-rhClamp, rhClamp).toDouble();
    if (isDay(obsTime)) {
      return b.copyWith(
          rhDay: b.rhSeeded ? (1 - w) * b.rhDay + w * e : e, rhSeeded: true);
    }
    return b.copyWith(
        rhNight: b.rhSeeded ? (1 - w) * b.rhNight + w * e : e, rhSeeded: true);
  }

  /// Subtract the learned humidity bias from all hourly RH values.
  static WeatherBundle applyRh(WeatherBundle bundle, TempBias b) {
    if (!b.rhActive) return bundle;
    final hours = bundle.hours
        .map((h) => h.copyWith(
            rh: (h.rh - (isDay(h.time) ? b.rhDay : b.rhNight)).clamp(0, 100).toDouble()))
        .toList();
    return bundle.copyWith(hours: hours);
  }

  // ── Skill-weighted ensemble ─────────────────────────────────────────────

  /// Fold each model's |forecast − observed| (at the nearest hour ≤2h) into its
  /// decaying mean-absolute error.
  static TempBias learnModelErr(
    TempBias b,
    Map<String, Map<DateTime, double>> modelTemps,
    double obsTemp,
    DateTime obsTime,
  ) {
    final next = Map<String, double>.from(b.modelMae);
    modelTemps.forEach((key, series) {
      final t = _nearestInSeries(series, obsTime);
      if (t == null) return;
      final err = (t - obsTemp).abs();
      next[key] = next.containsKey(key) ? (1 - w) * next[key]! + w * err : err;
    });
    return b.copyWith(modelMae: next);
  }

  /// Inverse-error weights for [keys], normalised to sum 1. Equal-weight when a
  /// model has no learned error yet.
  static Map<String, double> weights(TempBias b, Iterable<String> keys) {
    final ks = keys.toList();
    if (ks.isEmpty) return const {};
    final raw = <String, double>{};
    double total = 0;
    for (final k in ks) {
      final mae = b.modelMae[k];
      final wv = mae == null ? 1.0 : 1.0 / (mae + 0.5);
      raw[k] = wv;
      total += wv;
    }
    if (total <= 0) {
      final eq = 1.0 / ks.length;
      return {for (final k in ks) k: eq};
    }
    return {for (final k in ks) k: raw[k]! / total};
  }

  /// Weighted-mean blend of per-model temperatures over the best-match temps.
  static WeatherBundle blendTempsWeighted(
    WeatherBundle bundle,
    Map<String, Map<DateTime, double>> modelTemps,
    Map<String, double> weights,
  ) {
    if (modelTemps.isEmpty || weights.isEmpty) return bundle;
    final hours = bundle.hours.map((h) {
      double sum = 0, wsum = 0;
      modelTemps.forEach((key, series) {
        final t = series[h.time];
        final wv = weights[key];
        if (t != null && wv != null) {
          sum += t * wv;
          wsum += wv;
        }
      });
      return wsum > 0 ? h.copyWith(tempC: sum / wsum) : h;
    }).toList();
    return bundle.copyWith(hours: hours);
  }

  static double? _nearestInSeries(Map<DateTime, double> series, DateTime t) {
    double? best;
    Duration bestDiff = const Duration(hours: 3);
    series.forEach((time, v) {
      final d = time.difference(t).abs();
      if (d <= const Duration(hours: 2) && d < bestDiff) {
        bestDiff = d;
        best = v;
      }
    });
    return best;
  }

  // ── Precip-probability calibration ──────────────────────────────────────

  /// Fold one (forecast probability, rained?) sample into its decile bin.
  static TempBias learnCal(TempBias b, double forecastProb, bool rainedNow) {
    final bin = (forecastProb / 10).floor().clamp(0, 9);
    final obs = rainedNow ? 1.0 : 0.0;
    final d = b.precipDeciles.length == 10
        ? List<double>.from(b.precipDeciles)
        : List<double>.filled(10, -1);
    d[bin] = d[bin] < 0 ? obs : (1 - w) * d[bin] + w * obs;
    return b.copyWith(precipDeciles: d);
  }

  /// Remap hourly/daily precip probabilities through the learned, monotone
  /// reliability curve. No-op until at least one bin is seeded.
  static WeatherBundle applyCal(WeatherBundle bundle, TempBias b) {
    final d = b.precipDeciles;
    if (d.length != 10 || d.every((v) => v < 0)) return bundle;
    final mono = _monoRates(d);
    double cal(double p) {
      final bin = (p / 10).floor().clamp(0, 9);
      return (mono[bin] * 100).clamp(0, 100).toDouble();
    }

    final hours =
        bundle.hours.map((h) => h.copyWith(precipProb: cal(h.precipProb))).toList();
    final days = bundle.days
        .map((day) => day.copyWith(precipProbMax: cal(day.precipProbMax)))
        .toList();
    return bundle.copyWith(hours: hours, days: days);
  }

  /// Non-decreasing rate per decile; unseeded bins fall back to their identity
  /// centre so the mapping never inverts ordering.
  static List<double> _monoRates(List<double> d) {
    final r = List<double>.generate(
        10, (i) => (i < d.length && d[i] >= 0) ? d[i] : ((i * 10) + 5) / 100.0);
    for (var i = 1; i < 10; i++) {
      if (r[i] < r[i - 1]) r[i] = r[i - 1];
    }
    return r;
  }
}
