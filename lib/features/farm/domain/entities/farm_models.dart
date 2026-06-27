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
