import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../weather/presentation/controllers/weather_controller.dart';
import '../../domain/entities/farm_models.dart';
import '../../domain/farm_decisions.dart';

class FarmScreen extends ConsumerWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final state = ref.watch(weatherControllerProvider).valueOrNull;
    if (state == null) return EmptyState(message: s.t('loading'));
    final w = state.bundle;
    final fd = FarmDecisions(w);
    final actions = fd.actions();
    final irr = fd.irrigation();
    final windows = fd.sprayWindows();

    final age = DateTime.now().difference(w.fetchedAt).inMinutes;
    final freshness = state.fromCache
        ? s.t('offline_cached')
        : '${s.t('updated')} '
            '${age <= 1 ? s.t('just_now') : '$age ${s.t('min_ago')}'}';

    return RefreshIndicator(
      color: AppColors.rainCyan,
      backgroundColor: AppColors.navSurface,
      onRefresh: () => ref.read(weatherControllerProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SectionCard(
            title: '${s.t('farm_actions')} · $freshness',
            icon: Icons.eco,
            child: Column(
              children: actions.map((a) => _actionCard(s, a)).toList(),
            ),
          ),
          _irrigationMatrix(s, irr),
          SectionCard(
            title: s.t('spray_windows'),
            icon: Icons.science,
            child: Column(
              children: windows.map((win) => _windowRow(s, win)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(ActionLevel l) => switch (l) {
        ActionLevel.go => AppColors.growthGreen,
        ActionLevel.hold => AppColors.stormAmber,
        ActionLevel.alert => AppColors.dangerCoral,
      };

  IconData _icon(String key) => switch (key) {
        'water' => Icons.water_drop,
        'spray' => Icons.science,
        'bolt' => Icons.bolt,
        'sun' => Icons.wb_sunny,
        'plant' => Icons.grass,
        'frost' => Icons.ac_unit,
        'heat' => Icons.whatshot,
        'cow' => Icons.pets,
        _ => Icons.info,
      };

  Widget _actionCard(S s, FarmAction a) {
    final col = _levelColor(a.level);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: col.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: col.withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(_icon(a.iconKey), size: 16, color: col),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(a.title,
                          style: AppTypography.title(size: 12)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: col.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(a.badge,
                          style: AppTypography.label(size: 9, color: col)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(a.detail, style: AppTypography.label(size: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _irrigationMatrix(S s, IrrigationVerdict irr) {
    final col = irr.hold ? AppColors.growthGreen : AppColors.stormAmber;
    return SectionCard(
      title: s.t('irrigation_matrix'),
      icon: Icons.water_drop,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      value: '${irr.forecast24h.toStringAsFixed(0)}mm',
                      label: s.t('forecast_24h'),
                      color: AppColors.stormAmber)),
              const SizedBox(width: 8),
              Expanded(
                  child: StatTile(
                      value: '${irr.soilMoisturePct.toStringAsFixed(0)}%',
                      label: s.t('soil_moisture'),
                      color: AppColors.growthGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      value: '${irr.et0Demand.toStringAsFixed(1)}mm',
                      label: s.t('et0_demand'),
                      color: AppColors.rainCyan)),
              const SizedBox(width: 8),
              Expanded(
                  child: StatTile(
                      value: irr.hold
                          ? s.t('hold').toUpperCase()
                          : s.t('go').toUpperCase(),
                      label: s.t('decision'),
                      color: col)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: col.withOpacity(0.07),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: col.withOpacity(0.2)),
            ),
            child: Text(irr.rationale,
                style:
                    AppTypography.label(size: 11, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _windowRow(S s, SprayWindow win) {
    final (col, label) = switch (win.status) {
      'safe' => (AppColors.growthGreen, s.t('safe')),
      'marginal' => (AppColors.stormAmber, s.t('marginal')),
      _ => (AppColors.dangerCoral, s.t('unsafe')),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: BoxDecoration(
        color: col.withOpacity(0.07),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child:
                Text(win.time, style: AppTypography.mono(size: 10, color: col)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.title(size: 11, color: col)),
                const SizedBox(height: 2),
                Text(win.reason, style: AppTypography.label(size: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
