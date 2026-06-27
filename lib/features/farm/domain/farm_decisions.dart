import 'dart:math';
import '../../weather/domain/entities/weather_bundle.dart';
import 'entities/farm_models.dart';

/// Pure rule-based farm decisions. Every output exposes the numbers behind it.
/// Tune the thresholds at the top.
class FarmDecisions {
  final WeatherBundle w;
  final CropProfile profile;
  const FarmDecisions(this.w, {this.profile = CropProfile.wheat});

  // Universal/operational thresholds (not crop-specific).
  static const double capeHigh = 2500; // J/kg
  static const double sprayWindMax = 20; // km/h
  static const double rainProbUnsafe = 60; // %
  static const double rainProbMarginal = 35;
  static const double thiAlert = 72.0; // livestock heat-stress index

  // Crop-specific thresholds come from the active [profile].
  double get soilHealthy => profile.soilHealthy;
  double get frostThreshold => profile.frostThreshold;
  double get heatThreshold => profile.heatThreshold;
  double get gddBase => profile.gddBase;

  double get soilPct => w.current.soilMoisture * 100;

  IrrigationVerdict irrigation() {
    final rain = w.rain24h;
    final et0 = _et0Today();
    final soil = w.current.soilMoisture;
    final hold = rain >= et0 && soil >= soilHealthy;
    final rationale = hold
        ? 'Forecast ${rain.toStringAsFixed(0)}mm over next 24h covers today’s '
            '${et0.toStringAsFixed(1)}mm ET₀ demand, and soil is at '
            '${(soil * 100).toStringAsFixed(0)}% (healthy). Skip the tubewell and '
            're-check at 06:00 tomorrow.'
        : 'Forecast rain ${rain.toStringAsFixed(0)}mm is below the '
            '${et0.toStringAsFixed(1)}mm ET₀ demand or soil is dry '
            '(${(soil * 100).toStringAsFixed(0)}%). Irrigation recommended.';
    return IrrigationVerdict(rain, soil * 100, et0, hold, rationale);
  }

  double _et0Today() {
    final next = w.nextHours(24);
    if (next.isEmpty) return w.current.et0;
    return next.fold(0.0, (a, h) => a + h.et0);
  }

  List<FarmAction> actions() {
    final out = <FarmAction>[];
    final irr = irrigation();
    final capeTonight = w.capeTonightMax;
    final next6 = w.nextHours(6);
    final maxProb6 = next6.isEmpty
        ? 0.0
        : next6.map((h) => h.precipProb).reduce((a, b) => a > b ? a : b);

    out.add(FarmAction(
      irr.hold ? ActionLevel.hold : ActionLevel.go,
      'water',
      irr.hold ? 'Hold irrigation — rain expected' : 'Irrigate today',
      irr.hold ? 'Hold' : 'Go',
      irr.rationale,
    ));

    // Spray — safe only when both rain risk AND wind are below their limits.
    final windNow = w.current.windKmh;
    final spraySafe = maxProb6 < rainProbMarginal && windNow < sprayWindMax;
    final sprayBlocker = maxProb6 >= rainProbMarginal
        ? 'rain risk ${maxProb6.toStringAsFixed(0)}%'
        : 'wind ${windNow.toStringAsFixed(0)} km/h';
    out.add(FarmAction(
      spraySafe ? ActionLevel.go : ActionLevel.hold,
      'spray',
      spraySafe ? 'Spray window is open' : 'Delay pesticide spray',
      spraySafe ? 'Go' : 'Wait',
      'Max rain probability in the next 6h is ${maxProb6.toStringAsFixed(0)}%. '
          'Wind ${windNow.toStringAsFixed(0)} km/h, '
          'VPD ${w.current.vpd.toStringAsFixed(1)} kPa. '
          '${spraySafe ? "Conditions acceptable now." : "Hold — $sprayBlocker risks wash-off/drift."}',
    ));

    if (capeTonight >= capeHigh) {
      out.add(FarmAction(
        ActionLevel.alert,
        'bolt',
        'Storm risk tonight — CAPE ${capeTonight.toStringAsFixed(0)}',
        'Alert',
        'High convective instability (${capeTonight.toStringAsFixed(0)} J/kg) tonight. '
            'Flash runoff possible in low-lying fields. Secure loose inputs and '
            'clear field drainage channels.',
      ));
    }

    final dryRun = _harvestWindow();
    if (dryRun != null) {
      out.add(FarmAction(
        ActionLevel.go,
        'sun',
        'Harvest window: $dryRun',
        'Go',
        'Consecutive dry days (<2mm) forecast. Best window this week for '
            'cutting and threshing.',
      ));
    }

    if (irr.forecast24h >= 5) {
      out.add(FarmAction(
        ActionLevel.go,
        'plant',
        'Apply urea before the rain',
        'Go',
        'Forecast ${irr.forecast24h.toStringAsFixed(0)}mm will incorporate '
            'surface-applied urea for better nitrogen uptake. Avoid low spots '
            'to limit runoff.',
      ));
    }

    final frost = _firstDayBelow(frostThreshold);
    if (frost != null) {
      out.add(FarmAction(
        ActionLevel.alert,
        'frost',
        'Frost risk $frost',
        'Alert',
        'Forecast low near or below ${frostThreshold.toStringAsFixed(0)}°C. '
            'Canopy can run 2–5°C colder than the screen reading on a clear, '
            'calm night. Light irrigation before dusk buffers wheat at heading.',
      ));
    }

    final hot = _firstDayAbove(heatThreshold);
    if (hot != null) {
      out.add(FarmAction(
        ActionLevel.alert,
        'heat',
        'Extreme heat $hot',
        'Alert',
        'Forecast high ≥${heatThreshold.toStringAsFixed(0)}°C. Irrigate to cool '
            'the canopy, shift labour and spraying to early morning, and watch '
            'for heat stress at grain-fill.',
      ));
    }

    final thi = _thi(w.current.tempC, w.current.rh);
    if (thi >= thiAlert) {
      out.add(FarmAction(
        ActionLevel.alert,
        'cow',
        'Livestock heat stress — THI ${thi.toStringAsFixed(0)}',
        'Alert',
        'Temperature-humidity index ${thi.toStringAsFixed(0)} (≥72). Provide '
            'shade and water for cattle/buffalo; milk yield drops above this.',
      ));
    }

    final gdd = _gddWeek();
    out.add(FarmAction(
      ActionLevel.go,
      'plant',
      'Heat units this week: ${gdd.toStringAsFixed(0)} GDD',
      'Info',
      'Growing degree days (base ${gddBase.toStringAsFixed(0)}°C) summed over '
          'the 7-day forecast. Tracks crop development toward the next stage '
          '— fertiliser splits, irrigation and harvest readiness.',
    ));

    return out;
  }

  double _gddWeek() {
    double sum = 0;
    for (final d in w.days.take(7)) {
      sum += max(0.0, (d.tMax + d.tMin) / 2 - gddBase);
    }
    return sum;
  }

  String? _firstDayBelow(double t) {
    for (final d in w.days.take(7)) {
      if (d.tMin <= t) return _weekday(d.date);
    }
    return null;
  }

  String? _firstDayAbove(double t) {
    for (final d in w.days.take(7)) {
      if (d.tMax >= t) return _weekday(d.date);
    }
    return null;
  }

  static double _thi(double tC, double rh) =>
      (1.8 * tC + 32) - (0.55 - 0.0055 * rh) * (1.8 * tC - 26);

  String? _harvestWindow() {
    final days = w.days;
    for (var i = 0; i < days.length - 1; i++) {
      if (days[i].precipSum < 2 && days[i + 1].precipSum < 2) {
        return '${_weekday(days[i].date)} & ${_weekday(days[i + 1].date)}';
      }
    }
    return null;
  }

  List<SprayWindow> sprayWindows() {
    final out = <SprayWindow>[];
    final next = w.nextHours(12);
    if (next.isEmpty) return out;

    for (var b = 0; b < 4; b++) {
      final slice = next.skip(b * 3).take(3).toList();
      if (slice.isEmpty) break;
      final maxProb =
          slice.map((h) => h.precipProb).reduce((a, c) => a > c ? a : c);
      final maxCape =
          slice.map((h) => h.cape).reduce((a, c) => a > c ? a : c);
      final maxWind =
          slice.map((h) => h.windKmh).reduce((a, c) => a > c ? a : c);
      final start = slice.first.time;
      final end = slice.last.time.add(const Duration(hours: 1));
      final label = '${_hm(start)}–${_hm(end)}';

      String status;
      String reason;
      if (maxProb >= rainProbUnsafe || maxCape >= capeHigh) {
        status = 'unsafe';
        reason =
            'Rain ${maxProb.toStringAsFixed(0)}%, CAPE ${maxCape.toStringAsFixed(0)}. Do not spray.';
      } else if (maxProb >= rainProbMarginal || maxWind >= sprayWindMax) {
        status = 'marginal';
        reason =
            'Rain ${maxProb.toStringAsFixed(0)}%, wind ${maxWind.toStringAsFixed(0)} km/h. Risk of wash-off.';
      } else {
        status = 'safe';
        reason =
            'Rain ${maxProb.toStringAsFixed(0)}%, wind ${maxWind.toStringAsFixed(0)} km/h. Good window.';
      }
      out.add(SprayWindow(label, status, status, reason));
    }
    return out;
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _weekday(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(d.weekday - 1) % 7];
  }
}
