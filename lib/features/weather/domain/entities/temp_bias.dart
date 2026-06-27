import 'package:equatable/equatable.dart';

/// Persisted learned-state for every ground-truth correction the app applies:
/// temperature & humidity bias, per-model skill weights, and precip-probability
/// calibration. Kept in one entity so load/save lives in a single place (DRY);
/// the maths is in `BiasCorrector`. (Filename retained for cache continuity.)
///
///   temp/rh bias = (1-w)*bias + w*(forecast - observed)   → shown = forecast - bias
///   model skill  = decaying mean-absolute temp error per model
///   calibration  = decaying observed rain frequency per forecast decile
class TempBias extends Equatable {
  // Temperature bias (forecast − observed), day/night buckets.
  final double day;
  final double night;
  final bool seeded;

  // Relative-humidity bias (forecast − observed), day/night buckets.
  final double rhDay;
  final double rhNight;
  final bool rhSeeded;

  // Per-model decaying mean-absolute temperature error (label → MAE).
  // Empty ⇒ not yet learned (equal-weight fallback).
  final Map<String, double> modelMae;

  // Reliability curve: observed rain frequency per forecast-probability decile
  // (index 0 ⇒ 0–10% … 9 ⇒ 90–100%). A bin value of -1 ⇒ not yet seeded.
  final List<double> precipDeciles;

  const TempBias({
    this.day = 0,
    this.night = 0,
    this.seeded = false,
    this.rhDay = 0,
    this.rhNight = 0,
    this.rhSeeded = false,
    this.modelMae = const {},
    this.precipDeciles = const [],
  });

  bool get active => seeded && (day != 0 || night != 0);
  bool get rhActive => rhSeeded && (rhDay != 0 || rhNight != 0);

  TempBias copyWith({
    double? day,
    double? night,
    bool? seeded,
    double? rhDay,
    double? rhNight,
    bool? rhSeeded,
    Map<String, double>? modelMae,
    List<double>? precipDeciles,
  }) =>
      TempBias(
        day: day ?? this.day,
        night: night ?? this.night,
        seeded: seeded ?? this.seeded,
        rhDay: rhDay ?? this.rhDay,
        rhNight: rhNight ?? this.rhNight,
        rhSeeded: rhSeeded ?? this.rhSeeded,
        modelMae: modelMae ?? this.modelMae,
        precipDeciles: precipDeciles ?? this.precipDeciles,
      );

  @override
  List<Object?> get props =>
      [day, night, seeded, rhDay, rhNight, rhSeeded, modelMae, precipDeciles];
}
