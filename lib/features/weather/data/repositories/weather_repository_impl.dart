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
      final (raw, modelTemps) =
          await _remote.fetchForecast(lat: lat, lon: lon, placeName: placeName);

      var bias = _local.getBias();
      final obs = await _metar.fetchLatest();
      final fresh = obs != null && obs.isFresh;

      // 1) Learn per-model skill from the live observation, then blend temps.
      if (fresh) {
        bias = BiasCorrector.learnModelErr(bias, modelTemps, obs.tempC, obs.time);
      }
      final weights = BiasCorrector.weights(bias, modelTemps.keys);
      var bundle = BiasCorrector.blendTempsWeighted(raw, modelTemps, weights);

      // 2) Learn residual temp/RH bias and precip-prob calibration vs METAR.
      if (fresh) {
        final tErr = BiasCorrector.errorAt(bundle, obs.tempC, obs.time);
        if (tErr != null) bias = BiasCorrector.update(bias, tErr, obs.time);

        final obsRh = BiasCorrector.rhFromDewpoint(obs.tempC, obs.dewpC);
        final rhErr = BiasCorrector.rhErrorAt(bundle, obsRh, obs.time);
        if (rhErr != null) bias = BiasCorrector.updateRh(bias, rhErr, obs.time);

        final p = BiasCorrector.precipProbAt(bundle, obs.time);
        if (p != null) bias = BiasCorrector.learnCal(bias, p, obs.precipNow);

        await _local.saveBias(bias);
      }

      // 3) Apply every learned correction, attach the observation, cache.
      var corrected = BiasCorrector.apply(bundle, bias);
      corrected = BiasCorrector.applyRh(corrected, bias);
      corrected = BiasCorrector.applyCal(corrected, bias);
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
