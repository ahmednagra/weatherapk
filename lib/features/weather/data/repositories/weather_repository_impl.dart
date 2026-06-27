import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/flood_info.dart';
import '../../domain/entities/weather_bundle.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/services/bias_corrector.dart';
import '../datasources/flood_remote_datasource.dart';
import '../datasources/metar_remote_datasource.dart';
import '../datasources/weather_local_datasource.dart';
import '../datasources/weather_remote_datasource.dart';

/// Orchestrates the forecast pipeline:
/// remote fetch → learn/apply per-station temperature bias → attach live
/// observation → cache. Falls back to cache on any failure.
class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource _remote;
  final MetarRemoteDataSource _metar;
  final FloodRemoteDataSource _flood;
  final WeatherLocalDataSource _local;
  final NetworkInfo _network;

  const WeatherRepositoryImpl({
    required WeatherRemoteDataSource remote,
    required MetarRemoteDataSource metar,
    required FloodRemoteDataSource flood,
    required WeatherLocalDataSource local,
    required NetworkInfo network,
  })  : _remote = remote,
        _metar = metar,
        _flood = flood,
        _local = local,
        _network = network;

  @override
  Future<Result<WeatherBundle>> getForecast({
    required double lat,
    required double lon,
    required String placeName,
  }) async {
    if (!await _network.isConnected) {
      final cached = _local.getCachedForecast();
      return cached != null
          ? Ok(cached)
          : const Err<WeatherBundle>(NetworkFailure());
    }
    try {
      final raw =
          await _remote.fetchForecast(lat: lat, lon: lon, placeName: placeName);

      // Ground-truth bias correction against the nearest airport.
      var bias = _local.getBias();
      final obs = await _metar.fetchLatest();
      if (obs != null && obs.isFresh) {
        final err = BiasCorrector.errorAt(raw, obs.tempC, obs.time);
        if (err != null) {
          bias = BiasCorrector.update(bias, err, obs.time);
          await _local.saveBias(bias);
        }
      }
      var corrected = BiasCorrector.apply(raw, bias);
      if (obs != null) corrected = corrected.copyWith(observed: obs);

      await _local.cacheForecast(corrected);
      return Ok(corrected);
    } on ServerException catch (e) {
      final cached = _local.getCachedForecast();
      return cached != null
          ? Ok(cached)
          : Err<WeatherBundle>(ServerFailure(detail: e.message));
    } catch (e) {
      final cached = _local.getCachedForecast();
      return cached != null
          ? Ok(cached)
          : Err<WeatherBundle>(UnknownFailure(detail: e.toString()));
    }
  }

  @override
  Future<WeatherBundle?> getCachedForecast() async => _local.getCachedForecast();

  @override
  Future<FloodInfo?> getFlood({required double lat, required double lon}) =>
      _flood.fetch(lat: lat, lon: lon);

  @override
  Future<String> getLanguage() async => _local.getLanguage();

  @override
  Future<void> setLanguage(String code) => _local.saveLanguage(code);
}
