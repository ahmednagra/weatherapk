import 'package:equatable/equatable.dart';

/// A single forecast hour. Immutable domain entity (no JSON — that's the DTO).
class HourPoint extends Equatable {
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

  const HourPoint({
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

  HourPoint copyWith({double? tempC}) => HourPoint(
        time: time,
        tempC: tempC ?? this.tempC,
        rh: rh,
        precipProb: precipProb,
        precipMm: precipMm,
        cape: cape,
        soilMoisture: soilMoisture,
        et0: et0,
        vpd: vpd,
        windKmh: windKmh,
        windDir: windDir,
        weatherCode: weatherCode,
      );

  @override
  List<Object?> get props => [
        time,
        tempC,
        rh,
        precipProb,
        precipMm,
        cape,
        soilMoisture,
        et0,
        vpd,
        windKmh,
        windDir,
        weatherCode,
      ];
}
