import 'package:flutter/material.dart';
import '../app.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/rain_canvas.dart';
import 'now_screen.dart';
import 'hourly_screen.dart';
import 'seven_day_screen.dart';
import 'radar_screen.dart';
import 'farm_screen.dart';

class HomeShell extends StatefulWidget {
  final AppController controller;
  const HomeShell({super.key, required this.controller});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  double get _intensity {
    final b = widget.controller.bundle;
    if (b == null) return 0.3;
    final p = b.current.precipProb / 100.0;
    return (0.2 + p * 0.8).clamp(0.1, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final s = S.of(context);
        final screens = [
          NowScreen(controller: widget.controller),
          HourlyScreen(controller: widget.controller),
          SevenDayScreen(controller: widget.controller),
          RadarScreen(controller: widget.controller),
          FarmScreen(controller: widget.controller),
        ];

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              // Background rain canvas (continuous, behind content).
              Positioned.fill(
                child: IgnorePointer(
                  child: RainCanvas(intensity: _intensity),
                ),
              ),
              SafeArea(
                child: _body(context, screens),
              ),
            ],
          ),
          bottomNavigationBar: _navBar(s),
        );
      },
    );
  }

  Widget _body(BuildContext context, List<Widget> screens) {
    final c = widget.controller;
    if (c.loading && c.bundle == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.rainCyan),
            const SizedBox(height: 16),
            Text(S.of(context).t('loading'),
                style: AppTheme.label(size: 12)),
          ],
        ),
      );
    }
    if (c.bundle == null && c.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(c.error!,
                  textAlign: TextAlign.center,
                  style: AppTheme.label(size: 11)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.rainCyan,
                  foregroundColor: AppColors.bg),
              onPressed: c.refresh,
              child: Text(S.of(context).t('retry')),
            ),
          ],
        ),
      );
    }
    return IndexedStack(index: _index, children: screens);
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
        border: Border(
          top: BorderSide(color: Color(0x2600D4FF), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = _index == i;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: active
                              ? AppColors.rainCyan
                              : Colors.transparent,
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
                            style: AppTheme.label(
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
