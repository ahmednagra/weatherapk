/// Centralised endpoints, tuning and the fixed farm location. No secrets here —
/// every source is keyless. Kept flat and const for zero-cost access.
class ApiConstants {
  ApiConstants._();

  // Open-Meteo (forecast + flood). Free, no API key.
  static const String openMeteoForecast =
      'https://api.open-meteo.com/v1/forecast';
  static const String openMeteoFlood =
      'https://flood-api.open-meteo.com/v1/flood';

  // NOAA Aviation Weather Center — METAR ground truth.
  static const String awcMetar = 'https://aviationweather.gov/api/data/metar';

  // RainViewer radar tile manifest.
  static const String rainviewerManifest =
      'https://api.rainviewer.com/public/weather-maps.json';

  // NASA GIBS — satellite layers (only sat QPE that covers Pakistan).
  static const String gibsWmts =
      'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best';

  // CartoDB dark base map (fixed subdomain — avoids the removed `subdomains`
  // API in flutter_map 7).
  static const String cartoDark =
      'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  // Multi-model set for the precipitation/temperature blend.
  static const String forecastModels =
      'ecmwf_ifs025,gfs_seamless,icon_seamless,gem_seamless';
  static const List<String> modelSuffixes = [
    'ecmwf_ifs025',
    'gfs_seamless',
    'icon_seamless',
    'gem_seamless',
  ];

  // Nearest airport observation stations (Sialkot, then Lahore fallback).
  static const List<String> metarStations = ['OPST', 'OPLA'];

  static const String timezone = 'Asia/Karachi';
  static const int forecastDays = 7;
  static const Duration httpTimeout = Duration(seconds: 20);
  static const String userAgent = 'com.echooo.changi_agriweather';

  // Default farm location (Village Changi, Daska, Sialkot).
  static const double farmLat = 32.145;
  static const double farmLon = 74.526;
  static const String farmPlace = 'Changi Village · Daska · Sialkot';
}
