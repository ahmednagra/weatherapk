import '../../../../core/constants/api_constants.dart';
import '../entities/flood_info.dart';
import '../repositories/weather_repository.dart';

/// River-discharge (GloFAS) outlook for the farm location.
class GetFlood {
  final WeatherRepository _repo;
  const GetFlood(this._repo);

  Future<FloodInfo?> call({
    double lat = ApiConstants.farmLat,
    double lon = ApiConstants.farmLon,
  }) =>
      _repo.getFlood(lat: lat, lon: lon);
}
