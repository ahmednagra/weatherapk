import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/weather_bundle.dart';
import '../repositories/weather_repository.dart';

/// Fetch the live, bias-corrected forecast for the farm location.
class GetForecast {
  final WeatherRepository _repo;
  const GetForecast(this._repo);

  Future<Result<WeatherBundle>> call({
    double lat = ApiConstants.farmLat,
    double lon = ApiConstants.farmLon,
    String placeName = ApiConstants.farmPlace,
  }) =>
      _repo.getForecast(lat: lat, lon: lon, placeName: placeName);
}
