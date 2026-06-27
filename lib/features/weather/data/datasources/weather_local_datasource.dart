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
  String getCrop();
  Future<void> saveCrop(String id);
}

class WeatherLocalDataSourceImpl implements WeatherLocalDataSource {
  static const String boxName = 'app_cache';
  static const _kBundle = 'bundle';
  static const _kBiasDay = 'bias_day';
  static const _kBiasNight = 'bias_night';
  static const _kBiasSeeded = 'bias_seeded';
  static const _kBiasRhDay = 'bias_rh_day';
  static const _kBiasRhNight = 'bias_rh_night';
  static const _kBiasRhSeeded = 'bias_rh_seeded';
  static const _kModelMae = 'model_mae';
  static const _kPrecipCal = 'precip_cal';
  static const _kLang = 'lang';
  static const _kCrop = 'crop';

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
        rhDay: (_box.get(_kBiasRhDay) as num?)?.toDouble() ?? 0,
        rhNight: (_box.get(_kBiasRhNight) as num?)?.toDouble() ?? 0,
        rhSeeded: _box.get(_kBiasRhSeeded) as bool? ?? false,
        modelMae: _decodeMae(_box.get(_kModelMae)),
        precipDeciles: _decodeDeciles(_box.get(_kPrecipCal)),
      );

  @override
  Future<void> saveBias(TempBias bias) async {
    await _box.put(_kBiasDay, bias.day);
    await _box.put(_kBiasNight, bias.night);
    await _box.put(_kBiasSeeded, bias.seeded);
    await _box.put(_kBiasRhDay, bias.rhDay);
    await _box.put(_kBiasRhNight, bias.rhNight);
    await _box.put(_kBiasRhSeeded, bias.rhSeeded);
    await _box.put(_kModelMae, jsonEncode(bias.modelMae));
    await _box.put(_kPrecipCal, jsonEncode(bias.precipDeciles));
  }

  static Map<String, double> _decodeMae(dynamic raw) {
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return const {};
    }
  }

  static List<double> _decodeDeciles(dynamic raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => (e as num).toDouble())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  String getLanguage() => _box.get(_kLang) as String? ?? 'en';

  @override
  Future<void> saveLanguage(String code) => _box.put(_kLang, code);

  @override
  String getCrop() => _box.get(_kCrop) as String? ?? 'wheat';

  @override
  Future<void> saveCrop(String id) => _box.put(_kCrop, id);
}
