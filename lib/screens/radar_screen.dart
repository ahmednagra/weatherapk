import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../app.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../models/weather_models.dart';
import '../widgets/common_widgets.dart';

class RadarScreen extends StatefulWidget {
  final AppController controller;
  const RadarScreen({super.key, required this.controller});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  String? _radarHost;
  List<String> _frames = []; // tile path templates
  int _frameIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRadar();
  }

  Future<void> _loadRadar() async {
    try {
      final res = await http
          .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final host = j['host'] as String;
        final radar = j['radar'] as Map<String, dynamic>;
        final past = (radar['past'] as List).cast<dynamic>();
        final nowcast = (radar['nowcast'] as List?)?.cast<dynamic>() ?? [];
        final all = [...past, ...nowcast];
        final paths = all.map((e) => e['path'] as String).toList();
        if (mounted) {
          setState(() {
            _radarHost = host;
            _frames = paths;
            _frameIndex = past.isNotEmpty ? past.length - 1 : 0;
          });
        }
      }
    } catch (_) {
      // Radar overlay is optional; map still renders.
    }
  }

  String? get _currentTileUrl {
    if (_radarHost == null || _frames.isEmpty) return null;
    final path = _frames[_frameIndex.clamp(0, _frames.length - 1)];
    // color 4 = Universal Blue, options: smooth=1, snow=1
    return '$_radarHost$path/256/{z}/{x}/{y}/4/1_1.png';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final w = widget.controller.bundle!;

    return RefreshIndicator(
      color: AppColors.rainCyan,
      backgroundColor: AppColors.navSurface,
      onRefresh: () async {
        await widget.controller.refresh();
        await _loadRadar();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _mapCard(s, w),
          _sourcesCard(s),
          _satCard(s),
        ],
      ),
    );
  }

  Widget _mapCard(S s, WeatherBundle w) {
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
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: true,
                    userAgentPackageName: 'com.echooo.changi_agriweather',
                  ),
                  if (_currentTileUrl != null)
                    Opacity(
                      opacity: 0.65,
                      child: TileLayer(
                        urlTemplate: _currentTileUrl!,
                        userAgentPackageName:
                            'com.echooo.changi_agriweather',
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
                    _currentTileUrl != null
                        ? 'RainViewer radar · live frame'
                        : 'Radar feed unavailable',
                    style: AppTheme.label(size: 9),
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
      _Src('live', AppColors.growthGreen, 'Himawari-9 IR (JAXA)',
          '140.7°E · 2km · 10min · 16 channels'),
      _Src('live', AppColors.growthGreen, 'NASA GPM IMERG',
          '0.1° grid · 30-min · satellite rainfall'),
      _Src('live', AppColors.growthGreen, 'JAXA GSMaP NOW',
          'global hourly rain rate'),
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
    final badgeText = s.t(e.badge);
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
                child: Text(badgeText.toUpperCase(),
                    style: AppTheme.label(size: 8, color: e.color)),
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
                Text(e.name, style: AppTheme.title(size: 12)),
                const SizedBox(height: 2),
                Text(e.sub,
                    style: AppTheme.mono(
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
  _Src(this.badge, this.color, this.name, this.sub);
}
