import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_models.dart';

/// Stores the last successful WeatherBundle as JSON for offline launch.
class CacheService {
  static const _key = 'weather_bundle_v1';
  static const _langKey = 'lang_code';

  Future<void> saveBundle(WeatherBundle b) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(b.toJson()));
  }

  Future<WeatherBundle?> loadBundle() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return WeatherBundle.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
  }

  Future<String> loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'en';
  }
}
