import '../../../../core/utils/result.dart';
import '../entities/flood_info.dart';
import '../entities/weather_bundle.dart';

/// Domain contract for weather data. Implementations orchestrate remote fetch,
/// ground-truth bias correction and caching; callers see only entities.
abstract class WeatherRepository {
  /// Live forecast for a point, bias-corrected and cached on success.
  Future<Result<WeatherBundle>> getForecast({
    required double lat,
    required double lon,
    required String placeName,
  });

  /// Last cached forecast, or null if none saved yet.
  Future<WeatherBundle?> getCachedForecast();

  /// River-discharge outlook (optional; null when unavailable).
  Future<FloodInfo?> getFlood({required double lat, required double lon});

  /// Persisted UI language code ('en' | 'ur').
  Future<String> getLanguage();
  Future<void> setLanguage(String code);
}
