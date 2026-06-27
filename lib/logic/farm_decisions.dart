import '../models/weather_models.dart';

enum ActionLevel { go, hold, alert }

class FarmAction {
  final ActionLevel level;
  final String iconKey; // maps to an icon in the widget
  final String title;
  final String badge;
  final String detail;
  FarmAction(this.level, this.iconKey, this.title, this.badge, this.detail);
}

class SprayWindow {
  final String time;
  final String status; // 'safe' | 'marginal' | 'unsafe'
  final String label;
  final String reason;
  SprayWindow(this.time, this.status, this.label, this.reason);
}

class IrrigationVerdict {
  final double forecast24h;
  final double soilMoisturePct;
  final double et0Demand;
  final bool hold;
  final String rationale;
  IrrigationVerdict(this.forecast24h, this.soilMoisturePct, this.et0Demand,
      this.hold, this.rationale);
}

/// Pure rule-based decisions. Every output exposes the numbers behind it.
class FarmDecisions {
  final WeatherBundle w;
  FarmDecisions(this.w);

  // Thresholds (tunable).
  static const double capeHigh = 2500; // J/kg
  static const double soilHealthy = 0.30; // m3/m3 surface (~30%)
  static const double sprayWindMax = 20; // km/h
  static const double rainProbUnsafe = 60; // %
  static const double rainProbMarginal = 35;

  double get soilPct => (w.current.soilMoisture * 100);

  IrrigationVerdict irrigation() {
    final rain = w.rain24h;
    final et0 = _et0Today();
    final soil = w.current.soilMoisture;
    final hold = rain >= et0 && soil >= soilHealthy;
    final rationale = hold
        ? 'Forecast ${rain.toStringAsFixed(0)}mm over next 24h covers today\u2019s '
            '${et0.toStringAsFixed(1)}mm ET\u2080 demand, and soil is at '
            '${(soil * 100).toStringAsFixed(0)}% (healthy). Skip the tubewell and '
            're-check at 06:00 tomorrow.'
        : 'Forecast rain ${rain.toStringAsFixed(0)}mm is below the '
            '${et0.toStringAsFixed(1)}mm ET\u2080 demand or soil is dry '
            '(${(soil * 100).toStringAsFixed(0)}%). Irrigation recommended.';
    return IrrigationVerdict(rain, soil * 100, et0, hold, rationale);
  }

  double _et0Today() {
    // Sum ET0 across the next 24h (mm/day demand proxy).
    final next = w.nextHours(24);
    if (next.isEmpty) return w.current.et0;
    return next.fold(0.0, (a, h) => a + h.et0);
  }

  List<FarmAction> actions() {
    final out = <FarmAction>[];
    final irr = irrigation();
    final capeTonight = w.capeTonightMax;
    final next6 = w.nextHours(6);
    final maxProb6 =
        next6.isEmpty ? 0 : next6.map((h) => h.precipProb).reduce((a, b) => a > b ? a : b);

    // Irrigation
    out.add(FarmAction(
      irr.hold ? ActionLevel.hold : ActionLevel.go,
      'water',
      irr.hold ? 'Hold irrigation — rain expected' : 'Irrigate today',
      irr.hold ? 'Hold' : 'Go',
      irr.rationale,
    ));

    // Spray
    final sprayLevel = maxProb6 >= rainProbUnsafe
        ? ActionLevel.hold
        : (maxProb6 >= rainProbMarginal ? ActionLevel.hold : ActionLevel.go);
    out.add(FarmAction(
      sprayLevel,
      'spray',
      sprayLevel == ActionLevel.go
          ? 'Spray window is open'
          : 'Delay pesticide spray',
      sprayLevel == ActionLevel.go ? 'Go' : 'Wait',
      'Max rain probability in the next 6h is ${maxProb6.toStringAsFixed(0)}%. '
          'Wind ${w.current.windKmh.toStringAsFixed(0)} km/h, '
          'VPD ${w.current.vpd.toStringAsFixed(1)} kPa. '
          '${sprayLevel == ActionLevel.go ? "Conditions acceptable now." : "Risk of wash-off — wait for a drier window."}',
    ));

    // CAPE / storm
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

    // Harvest window: consecutive dry days (<2mm)
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

    // Urea timing if rain coming
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

    return out;
  }

  String? _harvestWindow() {
    // Find first run of >=2 days with precipSum < 2mm.
    final days = w.days;
    for (var i = 0; i < days.length - 1; i++) {
      if (days[i].precipSum < 2 && days[i + 1].precipSum < 2) {
        final a = _weekday(days[i].date);
        final b = _weekday(days[i + 1].date);
        return '$a & $b';
      }
    }
    return null;
  }

  List<SprayWindow> sprayWindows() {
    final out = <SprayWindow>[];
    final next = w.nextHours(12);
    if (next.isEmpty) return out;

    // Bucket into 4 windows of 3 hours.
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
