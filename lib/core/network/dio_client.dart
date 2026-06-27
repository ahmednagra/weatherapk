import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Single configured [Dio] instance for the whole app: sane timeouts, a
/// package user-agent, and lightweight request/response logging in debug.
/// Per CLAUDE.md, widgets never touch Dio directly — only data sources do.
class DioClient {
  final Dio dio;

  DioClient([Dio? dio]) : dio = dio ?? Dio() {
    this.dio
      ..options.connectTimeout = ApiConstants.httpTimeout
      ..options.receiveTimeout = ApiConstants.httpTimeout
      ..options.headers['User-Agent'] = ApiConstants.userAgent
      ..interceptors.add(_LogInterceptor());
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    dev.log('→ ${options.method} ${options.uri}', name: 'dio');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    dev.log('← ${response.statusCode} ${response.requestOptions.uri}',
        name: 'dio');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    dev.log('✗ ${err.type} ${err.requestOptions.uri} — ${err.message}',
        name: 'dio');
    handler.next(err);
  }
}
