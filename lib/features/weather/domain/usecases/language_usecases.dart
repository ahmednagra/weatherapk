import '../repositories/weather_repository.dart';

/// Read the persisted UI language code.
class GetLanguage {
  final WeatherRepository _repo;
  const GetLanguage(this._repo);
  Future<String> call() => _repo.getLanguage();
}

/// Persist the chosen UI language code.
class SetLanguage {
  final WeatherRepository _repo;
  const SetLanguage(this._repo);
  Future<void> call(String code) => _repo.setLanguage(code);
}
