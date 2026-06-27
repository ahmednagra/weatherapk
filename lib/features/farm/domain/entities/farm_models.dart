/// Crop-specific agronomic thresholds. Universal/operational limits (CAPE,
/// spray wind, rain-probability) stay in [FarmDecisions]; only the crop-varying
/// ones live here. [id] is persisted; [labelKey] resolves via the i18n table.
class CropProfile {
  final String id;
  final String labelKey;
  final double gddBase; // °C base for growing-degree-days
  final double frostThreshold; // °C — first-day-below advisory
  final double heatThreshold; // °C — extreme-heat advisory
  final double soilHealthy; // m³/m³ surface — irrigation adequacy

  const CropProfile({
    required this.id,
    required this.labelKey,
    required this.gddBase,
    required this.frostThreshold,
    required this.heatThreshold,
    required this.soilHealthy,
  });

  static const wheat = CropProfile(
    id: 'wheat',
    labelKey: 'crop_wheat',
    gddBase: 0,
    frostThreshold: 2,
    heatThreshold: 40,
    soilHealthy: 0.30,
  );
  static const rice = CropProfile(
    id: 'rice',
    labelKey: 'crop_rice',
    gddBase: 10,
    frostThreshold: 8,
    heatThreshold: 38,
    soilHealthy: 0.40,
  );
  static const sugarcane = CropProfile(
    id: 'sugarcane',
    labelKey: 'crop_sugarcane',
    gddBase: 12,
    frostThreshold: 2,
    heatThreshold: 42,
    soilHealthy: 0.35,
  );
  static const maize = CropProfile(
    id: 'maize',
    labelKey: 'crop_maize',
    gddBase: 10,
    frostThreshold: 4,
    heatThreshold: 38,
    soilHealthy: 0.30,
  );

  static const List<CropProfile> all = [wheat, rice, sugarcane, maize];

  /// Resolve a persisted id back to a profile (defaults to wheat).
  static CropProfile byId(String? id) =>
      all.firstWhere((c) => c.id == id, orElse: () => wheat);
}

/// View-model value types for farm guidance. Transient (rebuilt each forecast),
/// so plain immutable classes rather than Equatable.
enum ActionLevel { go, hold, alert }

class FarmAction {
  final ActionLevel level;
  final String iconKey;
  final String title;
  final String badge;
  final String detail;
  const FarmAction(
      this.level, this.iconKey, this.title, this.badge, this.detail);
}

class SprayWindow {
  final String time;
  final String status; // 'safe' | 'marginal' | 'unsafe'
  final String label;
  final String reason;
  const SprayWindow(this.time, this.status, this.label, this.reason);
}

class IrrigationVerdict {
  final double forecast24h;
  final double soilMoisturePct;
  final double et0Demand;
  final bool hold;
  final String rationale;
  const IrrigationVerdict(this.forecast24h, this.soilMoisturePct,
      this.et0Demand, this.hold, this.rationale);
}
