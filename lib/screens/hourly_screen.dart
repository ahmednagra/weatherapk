import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../models/weather_models.dart';
import '../widgets/common_widgets.dart';
import 'weather_icons.dart';

class HourlyScreen extends StatelessWidget {
  final AppController controller;
  const HourlyScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final w = controller.bundle!;
    final next = w.nextHours(12);

    return RefreshIndicator(
      color: AppColors.rainCyan,
      backgroundColor: AppColors.navSurface,
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _timeline(s, next),
          _chartCard(s, next),
          _surface(s, w),
        ],
      ),
    );
  }

  Widget _timeline(S s, List<HourPoint> hours) {
    final maxMm = hours
        .map((h) => h.precipMm)
        .fold(0.001, (a, b) => a > b ? a : b);
    return SectionCard(
      title: s.t('hourly_precip'),
      icon: Icons.schedule,
      child: Column(
        children: hours.asMap().entries.map((e) {
          final i = e.key;
          final h = e.value;
          final col = h.precipMm > 2
              ? AppColors.rainCyan
              : (h.precipMm > 0.5
                  ? const Color(0xFF60A5FA)
                  : Colors.white.withOpacity(0.25));
          final pCol = h.precipProb > 60
              ? AppColors.rainCyan
              : (h.precipProb > 30
                  ? AppColors.stormAmber
                  : AppColors.textFaint);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(_hm(h.time),
                      style: AppTheme.mono(
                          size: 10, color: AppColors.textFaint)),
                ),
                SizedBox(
                  width: 22,
                  child: Text(WeatherIcons.emoji(h.weatherCode),
                      style: const TextStyle(fontSize: 14)),
                ),
                Expanded(
                  child: AnimatedBar(
                    fraction: (h.precipMm / maxMm).clamp(0.0, 1.0),
                    color: col,
                    delayMs: i * 30,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  child: Text('${h.precipMm.toStringAsFixed(1)}mm',
                      textAlign: TextAlign.end,
                      style: AppTheme.mono(size: 10, color: col)),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 30,
                  child: Text('${h.precipProb.toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                      style: AppTheme.mono(size: 9, color: pCol)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chartCard(S s, List<HourPoint> hours) {
    return SectionCard(
      title: s.t('conditions'),
      icon: Icons.show_chart,
      child: Column(
        children: [
          Row(
            children: [
              _legend(AppColors.dangerCoral, s.t('temp')),
              const SizedBox(width: 14),
              _legend(AppColors.rainCyan, s.t('rain_prob')),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(height: 170, child: _lineChart(hours)),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(
        children: [
          Container(width: 14, height: 2, color: c),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.label(size: 9)),
        ],
      );

  Widget _lineChart(List<HourPoint> hours) {
    final tempSpots = <FlSpot>[];
    final probSpots = <FlSpot>[];
    for (var i = 0; i < hours.length; i++) {
      tempSpots.add(FlSpot(i.toDouble(), hours[i].tempC));
      // scale prob (0..100) onto temp axis range later via second dataset trick:
      probSpots.add(FlSpot(i.toDouble(), hours[i].precipProb));
    }

    // Two charts overlaid would need same Y scale; instead normalise prob to
    // temp axis by using a separate min/max and a secondary scale mapping.
    final tMin = 15.0;
    final tMax = 45.0;
    // Map probability 0..100 to tMin..tMax for display on the same axis.
    final probMapped = probSpots
        .map((p) => FlSpot(p.x, tMin + (p.y / 100.0) * (tMax - tMin)))
        .toList();

    return LineChart(
      LineChartData(
        minY: tMin,
        maxY: tMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 10,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                  style: AppTheme.label(size: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= hours.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_hm(hours[i].time),
                      style: AppTheme.label(size: 8)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: tempSpots,
            color: AppColors.dangerCoral,
            barWidth: 2,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: probMapped,
            color: AppColors.rainCyan,
            barWidth: 2,
            isCurved: true,
            dashArray: [4, 3],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.rainCyan.withOpacity(0.07),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surface(S s, WeatherBundle w) {
    final cur = w.current;
    return SectionCard(
      title: s.t('surface'),
      icon: Icons.air,
      child: Row(
        children: [
          Expanded(
              child: StatTile(
                  value: '${cur.vpd.toStringAsFixed(1)}kPa',
                  label: s.t('vpd'),
                  color: AppColors.rainCyan)),
          const SizedBox(width: 8),
          Expanded(
              child: StatTile(
                  value: '${cur.windKmh.toStringAsFixed(0)}km/h',
                  label: s.t('wind'),
                  color: AppColors.growthGreen)),
          const SizedBox(width: 8),
          Expanded(
              child: StatTile(
                  value: '${cur.et0.toStringAsFixed(1)}mm',
                  label: s.t('et0'),
                  color: AppColors.stormAmber)),
        ],
      ),
    );
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:00';
}
