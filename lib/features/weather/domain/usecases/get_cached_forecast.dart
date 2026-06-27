import '../entities/weather_bundle.dart';
import '../repositories/weather_repository.dart';

/// Last cached forecast for instant cold-start display.
class GetCachedForecast {
  final WeatherRepository _repo;
  const GetCachedForecast(this._repo);

  Future<WeatherBundle?> call() => _repo.getCachedForecast();
}
