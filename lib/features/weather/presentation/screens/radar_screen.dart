import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/weather_bundle.dart';
import '../controllers/weather_controller.dart';
import '../providers/feature_providers.dart';

class RadarScreen extends ConsumerWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final state = ref.watch(weatherControllerProvider).valueOrNull;
    if (state == null) return EmptyState(message: s.t('loading'));
    final w = state.bundle;
    final radarUrl = ref.watch(radarProvider).valueOrNull?.tileUrl;

    return RefreshIndicator(
      color: AppColors.rainCyan,
      backgroundColor: AppColors.navSurface,
      onRefresh: () async {
        await ref.read(weatherControllerProvider.notifier).refresh();
        ref.invalidate(radarProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _mapCard(s, w, radarUrl),
          _sourcesCard(s),
          _satCard(s),
        ],
      ),
    );
  }

  /// Most recent published NASA GIBS IMERG frame (~2h latency, 30-min grid).
  String _gibsImergUrl() {
    final t = DateTime.now().toUtc().subtract(const Duration(minutes: 120));
    final snapped =
        DateTime.utc(t.year, t.month, t.day, t.hour, t.minute < 30 ? 0 : 30);
    String two(int v) => v.toString().padLeft(2, '0');
    final ts = '${snapped.year}-${two(snapped.month)}-${two(snapped.day)}'
        'T${two(snapped.hour)}:${two(snapped.minute)}:00Z';
    return '${ApiConstants.gibsWmts}/IMERG_Precipitation_Rate/default/$ts/'
        'GoogleMapsCompatible_Level6/{z}/{y}/{x}.png';
  }

  Widget _mapCard(S s, WeatherBundle w, String? radarUrl) {
    return SectionCard(
      title: s.t('radar_sources'),
      icon: Icons.radar,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 260,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(w.lat, w.lon),
                  initialZoom: 7,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: ApiConstants.cartoDark,
                    retinaMode: true,
                    userAgentPackageName: ApiConstants.userAgent,
                  ),
                  Opacity(
                    opacity: 0.5,
                    child: TileLayer(
                      urlTemplate: _gibsImergUrl(),
                      maxNativeZoom: 6,
                      userAgentPackageName: ApiConstants.userAgent,
                    ),
                  ),
                  if (radarUrl != null)
                    Opacity(
                      opacity: 0.65,
                      child: TileLayer(
                        urlTemplate: radarUrl,
                        userAgentPackageName: ApiConstants.userAgent,
                      ),
                    ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(w.lat, w.lon),
                      width: 24,
                      height: 24,
                      child: const Icon(Icons.location_on,
                          color: AppColors.rainCyan, size: 24),
                    ),
                  ]),
                ],
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    radarUrl != null
                        ? 'RainViewer radar · live frame'
                        : s.t('satellite_rain'),
                    style: AppTypography.label(size: 9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourcesCard(S s) {
    final radar = [
      _Src('gap', AppColors.dangerCoral, 'PMD Sialkot C-band (PK2420)',
          'ffd.pmd.gov.pk · 350km range · feed often offline'),
      _Src('gap', AppColors.dangerCoral, 'RainViewer PK2420',
          'ingests PMD feed · same outage'),
      _Src('alt', AppColors.stormAmber, 'IMD Amritsar radar (upstream)',
          '~80km east · storms arrive here first · best alternative'),
      _Src('alt', AppColors.stormAmber, 'PMD FFD Sialkot page',
          'ffd.pmd.gov.pk/ffd_radars/sialkot.html'),
    ];
    return SectionCard(
      title: s.t('ground_radar'),
      icon: Icons.cell_tower,
      child: Column(children: radar.map((e) => _srcRow(s, e)).toList()),
    );
  }

  Widget _satCard(S s) {
    final sat = [
      _Src('live', AppColors.growthGreen, 'NASA GPM IMERG',
          '0.1° grid · 30-min · satellite rainfall (live layer)'),
      _Src('live', AppColors.growthGreen, 'EUMETSAT Meteosat IODC',
          '45.5°E · near-nadir over Pakistan'),
      _Src('live', AppColors.growthGreen, 'Himawari-9 IR (JAXA)',
          '140.7°E · 2km · 10min · 16 channels'),
      _Src('live', AppColors.growthGreen, 'ECMWF IFS Open Data 9km',
          'CC BY 4.0 · 4×/day · lead model'),
    ];
    return SectionCard(
      title: s.t('sat_feeds'),
      icon: Icons.satellite_alt,
      child: Column(children: sat.map((e) => _srcRow(s, e)).toList()),
    );
  }

  Widget _srcRow(S s, _Src e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: e.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: e.color.withOpacity(0.3)),
                ),
                child: Text(s.t(e.badge).toUpperCase(),
                    style: AppTypography.label(size: 8, color: e.color)),
              ),
              const SizedBox(height: 5),
              PulsingDot(color: e.color),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: AppTypography.title(size: 12)),
                const SizedBox(height: 2),
                Text(e.sub,
                    style: AppTypography.mono(
                        size: 10, color: AppColors.textFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Src {
  final String badge;
  final Color color;
  final String name;
  final String sub;
  const _Src(this.badge, this.color, this.name, this.sub);
}
