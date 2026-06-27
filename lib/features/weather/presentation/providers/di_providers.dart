import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/datasources/flood_remote_datasource.dart';
import '../../data/datasources/metar_remote_datasource.dart';
import '../../data/datasources/radar_remote_datasource.dart';
import '../../data/datasources/weather_local_datasource.dart';
import '../../data/datasources/weather_remote_datasource.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/usecases/get_cached_forecast.dart';
import '../../domain/usecases/get_flood.dart';
import '../../domain/usecases/get_forecast.dart';
import '../../domain/usecases/language_usecases.dart';

/// Dependency-injection graph. Widgets read these — never construct services
/// directly. [hiveBoxProvider] is overridden in main() with the opened box.

// ── Infrastructure ──────────────────────────────────────────────────────────
final dioProvider = Provider<Dio>((ref) => DioClient().dio);

final hiveBoxProvider = Provider<Box>(
    (ref) => throw UnimplementedError('hiveBoxProvider must be overridden'));

final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfoImpl());

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

// ── Data sources ────────────────────────────────────────────────────────────
final weatherRemoteProvider = Provider<WeatherRemoteDataSource>(
    (ref) => WeatherRemoteDataSourceImpl(ref.watch(dioProvider)));

final metarRemoteProvider = Provider<MetarRemoteDataSource>(
    (ref) => MetarRemoteDataSourceImpl(ref.watch(dioProvider)));

final floodRemoteProvider = Provider<FloodRemoteDataSource>(
    (ref) => FloodRemoteDataSourceImpl(ref.watch(dioProvider)));

final radarRemoteProvider = Provider<RadarRemoteDataSource>(
    (ref) => RadarRemoteDataSourceImpl(ref.watch(dioProvider)));

final weatherLocalProvider = Provider<WeatherLocalDataSource>(
    (ref) => WeatherLocalDataSourceImpl(ref.watch(hiveBoxProvider)));

// ── Repository ──────────────────────────────────────────────────────────────
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => WeatherRepositoryImpl(
    remote: ref.watch(weatherRemoteProvider),
    metar: ref.watch(metarRemoteProvider),
    flood: ref.watch(floodRemoteProvider),
    local: ref.watch(weatherLocalProvider),
    network: ref.watch(networkInfoProvider),
  ),
);

// ── Use cases ───────────────────────────────────────────────────────────────
final getForecastProvider =
    Provider((ref) => GetForecast(ref.watch(weatherRepositoryProvider)));
final getCachedForecastProvider =
    Provider((ref) => GetCachedForecast(ref.watch(weatherRepositoryProvider)));
final getFloodProvider =
    Provider((ref) => GetFlood(ref.watch(weatherRepositoryProvider)));
final getLanguageProvider =
    Provider((ref) => GetLanguage(ref.watch(weatherRepositoryProvider)));
final setLanguageProvider =
    Provider((ref) => SetLanguage(ref.watch(weatherRepositoryProvider)));
