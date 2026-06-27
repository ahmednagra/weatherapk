import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/temp_bias.dart';
import '../../domain/entities/weather_bundle.dart';
import '../models/weather_bundle_dto.dart';

/// Hive-backed persistence: cached forecast, learned temperature bias, and the
/// UI language. Values are stored as JSON strings / primitives — no codegen
/// adapters required (keeps the Codemagic build on the default flow).
abstract class WeatherLocalDataSource {
  Future<void> cacheForecast(WeatherBundle bundle);
  WeatherBundle? getCachedForecast();
  TempBias getBias();
  Future<void> saveBias(TempBias bias);
  String getLanguage();
  Future<void> saveLanguage(String code);
}

class WeatherLocalDataSourceImpl implements WeatherLocalDataSource {
  static const String boxName = 'app_cache';
  static const _kBundle = 'bundle';
  static const _kBiasDay = 'bias_day';
  static const _kBiasNight = 'bias_night';
  static const _kBiasSeeded = 'bias_seeded';
  static const _kLang = 'lang';

  final Box _box;
  const WeatherLocalDataSourceImpl(this._box);

  @override
  Future<void> cacheForecast(WeatherBundle bundle) =>
      _box.put(_kBundle, jsonEncode(WeatherBundleDto.toJson(bundle)));

  @override
  WeatherBundle? getCachedForecast() {
    final raw = _box.get(_kBundle);
    if (raw is! String) return null;
    try {
      return WeatherBundleDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  TempBias getBias() => TempBias(
        day: (_box.get(_kBiasDay) as num?)?.toDouble() ?? 0,
        night: (_box.get(_kBiasNight) as num?)?.toDouble() ?? 0,
        seeded: _box.get(_kBiasSeeded) as bool? ?? false,
      );

  @override
  Future<void> saveBias(TempBias bias) async {
    await _box.put(_kBiasDay, bias.day);
    await _box.put(_kBiasNight, bias.night);
    await _box.put(_kBiasSeeded, bias.seeded);
  }

  @override
  String getLanguage() => _box.get(_kLang) as String? ?? 'en';

  @override
  Future<void> saveLanguage(String code) => _box.put(_kLang, code);
}
