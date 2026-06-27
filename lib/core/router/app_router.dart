import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/farm/presentation/screens/farm_screen.dart';
import '../../features/weather/presentation/screens/home_shell.dart';
import '../../features/weather/presentation/screens/hourly_screen.dart';
import '../../features/weather/presentation/screens/now_screen.dart';
import '../../features/weather/presentation/screens/radar_screen.dart';
import '../../features/weather/presentation/screens/seven_day_screen.dart';

/// Named routes for the five tabs, hosted in a [StatefulShellRoute] so each tab
/// keeps its own navigation state (IndexedStack-style branches).
class AppRouter {
  AppRouter._();

  static const now = '/now';
  static const hourly = '/hourly';
  static const sevenDay = '/seven-day';
  static const radar = '/radar';
  static const farm = '/farm';

  static final GoRouter router = GoRouter(
    initialLocation: now,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: now,
                name: 'now',
                builder: (_, __) => const NowScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: hourly,
                name: 'hourly',
                builder: (_, __) => const HourlyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: sevenDay,
                name: 'sevenDay',
                builder: (_, __) => const SevenDayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: radar,
                name: 'radar',
                builder: (_, __) => const RadarScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: farm,
                name: 'farm',
                builder: (_, __) => const FarmScreen()),
          ]),
        ],
      ),
    ],
  );
}
