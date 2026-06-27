import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/metar_obs.dart';

/// Latest airport observation (OPST, then OPLA fallback) from NOAA AWC.
abstract class MetarRemoteDataSource {
  Future<MetarObs?> fetchLatest();
}

class MetarRemoteDataSourceImpl implements MetarRemoteDataSource {
  final Dio _dio;
  const MetarRemoteDataSourceImpl(this._dio);

  @override
  Future<MetarObs?> fetchLatest() async {
    MetarObs? freshestStale;
    for (final st in ApiConstants.metarStations) {
      try {
        final res = await _dio.get(
            '${ApiConstants.awcMetar}?ids=$st&format=json&hours=3');
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        if (data is! List || data.isEmpty) continue;

        Map<String, dynamic>? best;
        int bestEpoch = -1;
        for (final e in data) {
          if (e is! Map || e['temp'] == null) continue;
          final epoch = (e['obsTime'] as num?)?.toInt() ?? -1;
          if (epoch > bestEpoch) {
            bestEpoch = epoch;
            best = Map<String, dynamic>.from(e);
          }
        }
        if (best == null) continue;

        final temp = (best['temp'] as num).toDouble();
        final dewp = (best['dewp'] as num?)?.toDouble() ?? temp;
        final wspdKt = (best['wspd'] as num?)?.toDouble() ?? 0; // knots
        final obs = MetarObs(
          station: st,
          tempC: temp,
          dewpC: dewp,
          windKmh: wspdKt * 1.852,
          time: DateTime.fromMillisecondsSinceEpoch(bestEpoch * 1000,
                  isUtc: true)
              .toLocal(),
          precipNow: _hasPrecip(best['wxString']),
        );
        if (obs.isFresh) return obs;
        if (freshestStale == null || obs.time.isAfter(freshestStale.time)) {
          freshestStale = obs;
        }
      } catch (_) {
        continue;
      }
    }
    return freshestStale;
  }

  /// True when the METAR present-weather group reports any precipitation.
  static bool _hasPrecip(dynamic wxString) {
    if (wxString is! String || wxString.isEmpty) return false;
    final wx = wxString.toUpperCase();
    const tokens = ['RA', 'DZ', 'SN', 'SG', 'PL', 'GR', 'GS', 'SH', 'TS', 'UP'];
    return tokens.any(wx.contains);
  }
}
