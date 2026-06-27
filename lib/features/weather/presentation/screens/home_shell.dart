import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/rain_canvas.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/weather_controller.dart';

/// Bottom-nav shell. Hosts the GoRouter [StatefulNavigationShell] branches and
/// gates them behind the forecast's loading/error/success state.
class HomeShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final async = ref.watch(weatherControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(child: RainCanvas(intensity: _intensity(ref))),
          ),
          SafeArea(
            child: async.when(
              loading: () => LoadingView(message: s.t('loading')),
              error: (e, _) => ErrorView(
                message: e is Failure ? e.message : e.toString(),
                retryLabel: s.t('retry'),
                onRetry: () =>
                    ref.read(weatherControllerProvider.notifier).refresh(),
              ),
              data: (state) => Column(
                children: [
                  if (state.fromCache ||
                      DateTime.now().difference(state.bundle.fetchedAt).inMinutes >=
                          60)
                    _staleBanner(
                        s,
                        state.fromCache,
                        DateTime.now()
                            .difference(state.bundle.fetchedAt)
                            .inMinutes),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _navBar(s),
    );
  }

  double _intensity(WidgetRef ref) {
    final b = ref.watch(weatherControllerProvider).valueOrNull?.bundle;
    if (b == null) return 0.3;
    return (0.2 + (b.current.precipProb / 100.0) * 0.8).clamp(0.1, 1.0);
  }

  Widget _staleBanner(S s, bool offline, int ageMin) {
    final text =
        offline ? s.t('offline_cached') : '${s.t('updated')} $ageMin ${s.t('min_ago')}';
    return Container(
      width: double.infinity,
      color: AppColors.stormAmber.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(offline ? Icons.cloud_off : Icons.history,
              size: 12, color: AppColors.stormAmber),
          const SizedBox(width: 6),
          Text(text,
              style: AppTypography.label(size: 10, color: AppColors.stormAmber)),
        ],
      ),
    );
  }

  Widget _navBar(S s) {
    final items = [
      (Icons.home_filled, s.t('nav_now')),
      (Icons.schedule, s.t('nav_hourly')),
      (Icons.calendar_view_week, s.t('nav_7day')),
      (Icons.radar, s.t('nav_radar')),
      (Icons.eco, s.t('nav_farm')),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navSurface,
        border: Border(top: BorderSide(color: Color(0x2600D4FF), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = navigationShell.currentIndex == i;
              return Expanded(
                child: InkWell(
                  onTap: () => navigationShell.goBranch(i,
                      initialLocation: i == navigationShell.currentIndex),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color:
                              active ? AppColors.rainCyan : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      color: active
                          ? AppColors.rainCyan.withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i].$1,
                            size: 19,
                            color: active
                                ? AppColors.rainCyan
                                : AppColors.textMuted),
                        const SizedBox(height: 3),
                        Text(items[i].$2,
                            style: AppTypography.label(
                                size: 9,
                                color: active
                                    ? AppColors.rainCyan
                                    : AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
