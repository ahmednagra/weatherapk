import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';

/// Resolved RainViewer radar manifest: tile host + frame paths + the index of
/// the most recent observed frame.
class RadarManifest {
  final String host;
  final List<String> frames;
  final int currentIndex;
  const RadarManifest(this.host, this.frames, this.currentIndex);

  /// XYZ template for the current frame (Universal Blue, smoothed).
  String get tileUrl =>
      '$host${frames[currentIndex.clamp(0, frames.length - 1)]}/256/{z}/{x}/{y}/4/1_1.png';
}

abstract class RadarRemoteDataSource {
  Future<RadarManifest?> fetch();
}

class RadarRemoteDataSourceImpl implements RadarRemoteDataSource {
  final Dio _dio;
  const RadarRemoteDataSourceImpl(this._dio);

  @override
  Future<RadarManifest?> fetch() async {
    try {
      final res = await _dio.get(ApiConstants.rainviewerManifest);
      final j = res.data is String ? jsonDecode(res.data) : res.data;
      if (j is! Map) return null;
      final host = j['host'] as String?;
      final radar = j['radar'];
      if (host == null || radar is! Map) return null;
      final past = (radar['past'] as List?) ?? [];
      final nowcast = (radar['nowcast'] as List?) ?? [];
      final frames = [...past, ...nowcast]
          .map((e) => e['path'] as String)
          .toList();
      if (frames.isEmpty) return null;
      return RadarManifest(
          host, frames, past.isNotEmpty ? past.length - 1 : 0);
    } catch (_) {
      return null;
    }
  }
}
