import 'dart:io';

/// Minimal connectivity probe used by the repository to decide between a live
/// fetch and the cached fallback. Kept dependency-free (a DNS lookup) rather
/// than pulling connectivity_plus for a single boolean.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('api.open-meteo.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
