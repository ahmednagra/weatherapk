import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/weather_icons.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/cape_ring.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/hour_point.dart';
import '../../domain/entities/weather_bundle.dart';
import '../controllers/locale_controller.dart';
import '../controllers/weather_controller.dart';

class NowScreen extends ConsumerWidget {
  const NowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final state = ref.watch(weatherControllerProvider).valueOrNull;
    if (state == null) {
      return EmptyState(message: s.t('loading'));
    }
    final w = state.bundle;
    final cur = w.current;

    return RefreshIndicator(
      color: AppColors.rainCyan,
      backgroundColor: AppColors.navSurface,
      onRefresh: () => ref.read(weatherControllerProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _locationHeader(context, ref, s, w),
          const SizedBox(height: 12),
          _hero(s, cur, w),
          const SizedBox(height: 12),
          _statGrid(s, cur, w),
          const SizedBox(height: 10),
          _nowcast(s, w),
          const SizedBox(height: 10),
          _modelConsensus(s, w),
          const SizedBox(height: 10),
          _capeCard(s, w),
        ],
      ),
    );
  }

  Widget _locationHeader(BuildContext context, WidgetRef ref, S s, WeatherBundle w) {
    return Row(
      children: [
        const PulsingDot(color: AppColors.growthGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${w.placeName} · ${w.lat}°N ${w.lon}°E',
            style: AppTypography.label(size: 10, color: AppColors.rainCyan),
          ),
        ),
        InkWell(
          onTap: () => _langSheet(context, ref),
          child: Icon(Icons.language, size: 18, color: AppColors.textMuted),
        ),
      ],
    );
  }

  void _langSheet(BuildContext context, WidgetRef ref) {
    final locale = ref.read(localeControllerProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navSurface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('English', style: AppTypography.title()),
              onTap: () {
                locale.setLanguage('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('اردو', style: AppTypography.title()),
              onTap: () {
                locale.setLanguage('ur');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(S s, HourPoint cur, WeatherBundle w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyanFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x2600D4FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(w.displayCurrentTempC.toStringAsFixed(0),
                  style: AppTypography.mono(size: 52, weight: FontWeight.w600)),
              Text('°C',
                  style: AppTypography.mono(size: 22, color: AppColors.textMuted)),
              const Spacer(),
              Text(WeatherIcons.emoji(cur.weatherCode),
                  style: const TextStyle(fontSize: 40)),
            ],
          ),
          const SizedBox(height: 4),
          Text(WeatherIcons.label(cur.weatherCode),
              style: AppTypography.title(size: 14, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          _sourceLine(s, w),
        ],
      ),
    );
  }

  Widget _sourceLine(S s, WeatherBundle w) {
    final obs = w.observed;
    final live = obs != null && obs.isFresh;
    final String text;
    if (live) {
      final age = obs.ageMinutes;
      final ago = age <= 1 ? s.t('just_now') : '$age ${s.t('min_ago')}';
      text = '${s.t('live')} · ${obs.station} · $ago';
    } else {
      text = s.t('forecast_label');
    }
    return Row(
      children: [
        Icon(live ? Icons.sensors : Icons.cloud_queue,
            size: 11, color: live ? AppColors.growthGreen : AppColors.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            live ? '$text · ${s.t('station_corrected')}' : text,
            style: AppTypography.label(
                size: 9,
                color: live ? AppColors.growthGreen : AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _statGrid(S s, HourPoint cur, WeatherBundle w) {
    final items = [
      ('${cur.rh.toStringAsFixed(0)}%', s.t('humidity'), AppColors.rainCyan),
      ('${cur.windKmh.toStringAsFixed(0)}km/h', s.t('wind'),
          AppColors.growthGreen),
      (cur.cape.toStringAsFixed(0), s.t('cape'), AppColors.stormAmber),
      ('${w.rain24h.toStringAsFixed(0)}mm', s.t('rain_24h'), AppColors.rainCyan),
    ];
    return Row(
      children: items
          .map((e) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: StatTile(value: e.$1, label: e.$2, color: e.$3),
                ),
              ))
          .toList(),
    );
  }

  Widget _nowcast(S s, WeatherBundle w) {
    final next6 = w.nextHours(6);
    final soon = next6.isEmpty
        ? 0.0
        : next6.map((h) => h.precipProb).reduce((a, b) => a > b ? a : b);
    final tonight = w.nextHours(12);
    final tonightProb = tonight.isEmpty
        ? 0.0
        : tonight.map((h) => h.precipProb).reduce((a, b) => a > b ? a : b);
    final cur = w.current.precipProb;

    Widget box(String time, double prob, String desc) {
      final col = prob >= 60
          ? AppColors.rainCyan
          : (prob >= 35 ? AppColors.stormAmber : AppColors.growthGreen);
      final bg = prob >= 60
          ? AppColors.cyanFill
          : (prob >= 35 ? AppColors.amberFill : Colors.black.withOpacity(0.2));
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: prob >= 35 ? col.withOpacity(0.4) : AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Text(time.toUpperCase(), style: AppTypography.label(size: 9)),
              const SizedBox(height: 6),
              Text(prob < 10 ? s.t('dry') : '${prob.toStringAsFixed(0)}%',
                  style: AppTypography.mono(
                      size: 22, weight: FontWeight.w600, color: col)),
              const SizedBox(height: 3),
              Text(desc,
                  textAlign: TextAlign.center,
                  style: AppTypography.label(size: 9)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        box(s.t('now'), cur, '${w.current.precipMm.toStringAsFixed(1)}mm'),
        box(s.t('next_2_6h'), soon, ''),
        box(s.t('tonight'), tonightProb, ''),
      ],
    );
  }

  Widget _modelConsensus(S s, WeatherBundle w) {
    if (w.models.isEmpty) return const SizedBox.shrink();
    final maxV =
        w.models.map((m) => m.next24hSum).fold(1.0, (a, b) => a > b ? a : b);
    final colors = {
      'ECMWF': AppColors.rainCyan,
      'ICON': const Color(0xFFA78BFA),
      'GFS': const Color(0xFF60A5FA),
      'GEM': AppColors.growthGreen,
    };

    return SectionCard(
      title: s.t('model_consensus'),
      icon: Icons.hub,
      child: Column(
        children: [
          ...w.models.asMap().entries.map((e) {
            final m = e.value;
            final col = colors[m.key] ?? AppColors.rainCyan;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(m.key,
                        style: AppTypography.mono(
                            size: 10, weight: FontWeight.w600, color: col)),
                  ),
                  Expanded(
                    child: AnimatedBar(
                      fraction: maxV == 0 ? 0 : m.next24hSum / maxV,
                      color: col,
                      delayMs: e.key * 80,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: Text('${m.next24hSum.toStringAsFixed(0)}mm',
                        textAlign: TextAlign.end,
                        style: AppTypography.mono(size: 11, color: col)),
                  ),
                  if (m.key == 'ECMWF')
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: Icon(Icons.star,
                          size: 11, color: AppColors.stormAmber),
                    ),
                ],
              ),
            );
          }),
          if (w.agreement != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                    width: 80,
                    child: Text(s.t('agreement'),
                        style: AppTypography.label(size: 10))),
                Expanded(
                  child: AnimatedBar(
                      fraction: w.agreement!, color: AppColors.growthGreen),
                ),
                const SizedBox(width: 8),
                Text('${(w.agreement! * 100).toStringAsFixed(0)}%',
                    style: AppTypography.mono(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.growthGreen)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _capeCard(S s, WeatherBundle w) {
    final cape = w.current.cape;
    final tonight = w.capeTonightMax;
    return SectionCard(
      title: s.t('convective'),
      icon: Icons.bolt,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CapeRing(value: cape),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(cape.toStringAsFixed(0),
                        style: AppTypography.mono(
                            size: 26,
                            weight: FontWeight.w600,
                            color: AppColors.stormAmber)),
                    const SizedBox(width: 4),
                    Text('J/kg', style: AppTypography.label(size: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                _band('🟢 <1000  ${s.t('stable')}'),
                _band('🟠 1000–2500  ${s.t('moderate')}'),
                _band('🔴 2500+  ${s.t('high_risk')}'),
                const SizedBox(height: 4),
                Text('→ ${s.t('tonight')}: ${tonight.toStringAsFixed(0)} J/kg',
                    style: AppTypography.mono(
                        size: 11, color: AppColors.stormAmber)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _band(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text, style: AppTypography.label(size: 10)),
      );
}
