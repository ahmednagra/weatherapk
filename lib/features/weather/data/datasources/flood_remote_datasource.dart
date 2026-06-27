import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/flood_info.dart';

/// River-discharge outlook from Open-Meteo Flood (GloFAS). Optional layer —
/// returns null on any failure or when no GloFAS cell covers the point.
abstract class FloodRemoteDataSource {
  Future<FloodInfo?> fetch({required double lat, required double lon});
}

class FloodRemoteDataSourceImpl implements FloodRemoteDataSource {
  final Dio _dio;
  const FloodRemoteDataSourceImpl(this._dio);

  @override
  Future<FloodInfo?> fetch({required double lat, required double lon}) async {
    try {
      final res = await _dio.get('${ApiConstants.openMeteoFlood}'
          '?latitude=$lat&longitude=$lon&daily=river_discharge'
          '&forecast_days=${ApiConstants.forecastDays}');
      final data = res.data is String ? jsonDecode(res.data) : res.data;
      if (data is! Map) return null;
      final d = data['daily'];
      if (d is! Map) return null;
      final times = (d['time'] as List?)?.cast<String>() ?? [];
      final raw = d['river_discharge'];
      if (raw is! List || times.isEmpty) return null;

      final days = times.map(DateTime.parse).toList();
      final q = <double>[];
      for (var i = 0; i < days.length; i++) {
        final v = i < raw.length ? raw[i] : null;
        q.add(v == null ? 0.0 : (v as num).toDouble());
      }
      if (q.every((e) => e == 0)) return null;
      return FloodInfo(days, q);
    } catch (_) {
      return null;
    }
  }
}
