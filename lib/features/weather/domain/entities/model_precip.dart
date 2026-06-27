import 'package:equatable/equatable.dart';

/// One NWP model's precipitation outlook, used for the consensus bars.
class ModelPrecip extends Equatable {
  final String key; // 'ECMWF' | 'GFS' | 'ICON' | 'GEM'
  final double next24hSum;
  final List<double> dailySums; // up to 7

  const ModelPrecip({
    required this.key,
    required this.next24hSum,
    required this.dailySums,
  });

  @override
  List<Object?> get props => [key, next24hSum, dailySums];
}
