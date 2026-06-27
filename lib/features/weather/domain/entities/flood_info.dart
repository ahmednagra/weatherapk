import 'dart:math';
import 'package:equatable/equatable.dart';

/// River-discharge outlook (Open-Meteo Flood / GloFAS) for the Chenab basin.
class FloodInfo extends Equatable {
  final List<DateTime> days;
  final List<double> discharge; // m³/s

  const FloodInfo(this.days, this.discharge);

  double get today => discharge.isNotEmpty ? discharge.first : 0;
  double get peak => discharge.isEmpty ? 0 : discharge.reduce(max);
  bool get rising => today > 0 && peak >= today * 1.25;

  @override
  List<Object?> get props => [days, discharge];
}
