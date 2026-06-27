import 'package:equatable/equatable.dart';

/// Learned day/night temperature bias (forecast minus observed), persisted
/// across launches. [seeded] distinguishes "never learned" from a genuine 0.
class TempBias extends Equatable {
  final double day;
  final double night;
  final bool seeded;

  const TempBias({this.day = 0, this.night = 0, this.seeded = false});

  bool get active => seeded && (day != 0 || night != 0);

  TempBias copyWith({double? day, double? night, bool? seeded}) => TempBias(
        day: day ?? this.day,
        night: night ?? this.night,
        seeded: seeded ?? this.seeded,
      );

  @override
  List<Object?> get props => [day, night, seeded];
}
