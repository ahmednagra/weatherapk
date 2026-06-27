import 'package:flutter/material.dart';
import '../app.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../logic/farm_decisions.dart';
import '../widgets/common_widgets.dart';

class FarmScreen extends StatelessWidget {
  final AppController controller;
  const FarmScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final w = controller.bundle!;
    final fd = FarmDecisions(w);
    final actions = fd.actions();
    final irr = fd.irrigation();
    final windows = fd.sprayWindows();

    return RefreshIndicator(
      color: AppColors.rainCyan,
      backgroundColor: AppColors.navSurface,
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SectionCard(
            title: '${s.t('farm_actions')} · ${s.t('updated_just_now')}',
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

  Color _levelColor(ActionLevel l) {
    switch (l) {
      case ActionLevel.go:
        return AppColors.growthGreen;
      case ActionLevel.hold:
        return AppColors.stormAmber;
      case ActionLevel.alert:
        return AppColors.dangerCoral;
    }
  }

  IconData _icon(String key) {
    switch (key) {
      case 'water':
        return Icons.water_drop;
      case 'spray':
        return Icons.science;
      case 'bolt':
        return Icons.bolt;
      case 'sun':
        return Icons.wb_sunny;
      case 'plant':
        return Icons.grass;
      default:
        return Icons.info;
    }
  }

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
                          style: AppTheme.title(size: 12)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: col.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(a.badge,
                          style: AppTheme.label(size: 9, color: col)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(a.detail,
                    style: AppTheme.label(size: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _irrigationMatrix(S s, IrrigationVerdict irr) {
    final col =
        irr.hold ? AppColors.growthGreen : AppColors.stormAmber;
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
                      value: irr.hold ? s.t('hold').toUpperCase() : s.t('go').toUpperCase(),
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
                style: AppTheme.label(size: 11, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _windowRow(S s, SprayWindow win) {
    Color col;
    String label;
    switch (win.status) {
      case 'safe':
        col = AppColors.growthGreen;
        label = s.t('safe');
        break;
      case 'marginal':
        col = AppColors.stormAmber;
        label = s.t('marginal');
        break;
      default:
        col = AppColors.dangerCoral;
        label = s.t('unsafe');
    }
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
            child: Text(win.time,
                style: AppTheme.mono(size: 10, color: col)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.title(size: 11, color: col)),
                const SizedBox(height: 2),
                Text(win.reason, style: AppTheme.label(size: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
