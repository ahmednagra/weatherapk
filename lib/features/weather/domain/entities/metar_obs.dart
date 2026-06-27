import 'package:equatable/equatable.dart';

/// A live surface observation from the nearest airport (OPST/OPLA). The only
/// reliable real-time ground truth near the farm — anchors "now" and the
/// temperature bias correction.
class MetarObs extends Equatable {
  final String station;
  final double tempC;
  final double dewpC;
  final double windKmh;
  final DateTime time; // device-local
  final bool precipNow; // present-weather reports precipitation

  const MetarObs({
    required this.station,
    required this.tempC,
    required this.dewpC,
    required this.windKmh,
    required this.time,
    this.precipNow = false,
  });

  bool get isFresh =>
      DateTime.now().difference(time).abs() <= const Duration(minutes: 90);

  int get ageMinutes => DateTime.now().difference(time).inMinutes;

  @override
  List<Object?> get props =>
      [station, tempC, dewpC, windKmh, time, precipNow];
}
