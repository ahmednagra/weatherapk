import 'package:equatable/equatable.dart';

/// A single forecast day (daily aggregates).
class DayPoint extends Equatable {
  final DateTime date;
  final int weatherCode;
  final double tMax;
  final double tMin;
  final double precipSum;
  final double precipProbMax;

  const DayPoint({
    required this.date,
    required this.weatherCode,
    required this.tMax,
    required this.tMin,
    required this.precipSum,
    required this.precipProbMax,
  });

  DayPoint copyWith({double? tMax, double? tMin, double? precipProbMax}) =>
      DayPoint(
        date: date,
        weatherCode: weatherCode,
        tMax: tMax ?? this.tMax,
        tMin: tMin ?? this.tMin,
        precipSum: precipSum,
        precipProbMax: precipProbMax ?? this.precipProbMax,
      );

  @override
  List<Object?> get props =>
      [date, weatherCode, tMax, tMin, precipSum, precipProbMax];
}
