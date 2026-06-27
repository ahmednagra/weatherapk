import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../farm/domain/entities/farm_models.dart';
import '../../domain/entities/weather_bundle.dart';
import '../providers/di_providers.dart';
import '../providers/feature_providers.dart';

/// UI state for the forecast: the bundle plus whether it came from cache
/// (drives the offline banner). Async loading/error is encoded by AsyncValue.
class WeatherState extends Equatable {
  final WeatherBundle bundle;
  final bool fromCache;
  const WeatherState({required this.bundle, required this.fromCache});

  @override
  List<Object?> get props => [bundle, fromCache];
}

/// Owns the forecast lifecycle: instant cache on cold start, then a live
/// refresh; pull-to-refresh re-fetches. Notifications fire on each fresh load.
class WeatherController extends AsyncNotifier<WeatherState> {
  @override
  Future<WeatherState> build() async {
    await ref.read(notificationServiceProvider).init();

    final cached = await ref.read(getCachedForecastProvider).call();
    if (cached != null) {
      // Show cache instantly; refresh in the background after first frame.
      Future.microtask(refresh);
      return WeatherState(bundle: cached, fromCache: true);
    }

    final res = await ref.read(getForecastProvider).call();
    return res.fold(
      (failure) => throw failure,
      (bundle) {
        _onFresh(bundle);
        return WeatherState(bundle: bundle, fromCache: false);
      },
    );
  }

  Future<void> refresh() async {
    final res = await ref.read(getForecastProvider).call();
    res.fold(
      (failure) {
        // Keep showing existing data on failure; only surface error if we have
        // nothing at all.
        if (!state.hasValue) {
          state = AsyncError<WeatherState>(failure, StackTrace.current);
        }
      },
      (bundle) {
        _onFresh(bundle);
        state = AsyncData(WeatherState(bundle: bundle, fromCache: false));
        ref.invalidate(floodProvider);
      },
    );
  }

  void _onFresh(WeatherBundle bundle) {
    final crop = CropProfile.byId(ref.read(weatherLocalProvider).getCrop());
    ref
        .read(notificationServiceProvider)
        .evaluateAndNotify(bundle, profile: crop);
  }
}

final weatherControllerProvider =
    AsyncNotifierProvider<WeatherController, WeatherState>(
        WeatherController.new);
