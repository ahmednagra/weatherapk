/// Low-level exceptions thrown by data sources. Repositories catch these and
/// translate them into [Failure]s — exceptions never leak past the data layer.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache read/write failed']);
  @override
  String toString() => 'CacheException: $message';
}
