import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../models/weather_models.dart';
import '../widgets/common_widgets.dart';
import 'weather_icons.dart';

class SevenDayScreen extends StatelessWidget {
  final AppController controller;
  const SevenDayScreen({super.key, required this.controller});

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final w = controller.bundle!;

    return RefreshIndicator(
      color: AppColors.rainCyan,
      backgroundColor: AppColors.navSurface,
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _dayGrid(s, w),
          _weeklyChart(s, w),
          _soilCrop(s, w),
        ],
      ),
    );
  }

  Widget _dayGrid(S s, WeatherBundle w) {
    final days = w.days.take(7).toList();
    final maxMm =
        days.map((d) => d.precipSum).fold(0.001, (a, b) => a > b ? a : b);
    final today = DateTime.now();

    return SectionCard(
      title: s.t('outlook_7day'),
      icon: Icons.calendar_view_week,
      child: Row(
        children: days.asMap().entries.map((e) {
          final d = e.value;
          final isToday = d.date.day == today.day && d.date.month == today.month;
          final bw = maxMm == 0 ? 0.0 : (d.precipSum / maxMm).clamp(0.08, 1.0);
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.cyanFill
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: isToday
                        ? const Color(0x8000D4FF)
                        : AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Text(_names[(d.date.weekday - 1) % 7],
                      style: AppTheme.label(size: 9)),
                  const SizedBox(height: 5),
                  Text(WeatherIcons.emoji(d.weatherCode),
                      style: const TextStyle(fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('${d.tMax.toStringAsFixed(0)}°',
                      style: AppTheme.mono(size: 13, weight: FontWeight.w600)),
                  Text('${d.tMin.toStringAsFixed(0)}°',
                      style: AppTheme.mono(
                          size: 10, color: AppColors.textFaint)),
                  const SizedBox(height: 4),
                  Text('${d.precipSum.toStringAsFixed(0)}mm',
                      style: AppTheme.mono(
                          size: 9, color: AppColors.rainCyan)),
                  const SizedBox(height: 4),
                  FractionallySizedBox(
                    widthFactor: bw,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.rainCyan,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _weeklyChart(S s, WeatherBundle w) {
    final ecmwf = w.models.firstWhere((m) => m.key == 'ECMWF',
        orElse: () => w.models.isNotEmpty
            ? w.models.first
            : ModelPrecip(key: 'ECMWF', next24hSum: 0, dailySums: []));
    final gfs = w.models.firstWhere((m) => m.key == 'GFS',
        orElse: () => ModelPrecip(key: 'GFS', next24hSum: 0, dailySums: []));

    final n = w.days.length.clamp(0, 7);
    double maxY = 1;
    for (var i = 0; i < n; i++) {
      final a = i < ecmwf.dailySums.length ? ecmwf.dailySums[i] : 0;
      final b = i < gfs.dailySums.length ? gfs.dailySums[i] : 0;
      maxY = [maxY, a.toDouble(), b.toDouble()].reduce((x, y) => x > y ? x : y);
    }

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < n; i++) {
      final a = i < ecmwf.dailySums.length ? ecmwf.dailySums[i] : 0.0;
      final b = i < gfs.dailySums.length ? gfs.dailySums[i] : 0.0;
      groups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(
            toY: a.toDouble(),
            color: AppColors.rainCyan.withOpacity(0.8),
            width: 7,
            borderRadius: BorderRadius.circular(2)),
        BarChartRodData(
            toY: b.toDouble(),
            color: const Color(0xFF60A5FA).withOpacity(0.5),
            width: 7,
            borderRadius: BorderRadius.circular(2)),
      ]));
    }

    return SectionCard(
      title: s.t('weekly_rain'),
      icon: Icons.bar_chart,
      child: Column(
        children: [
          Row(
            children: [
              _legend(AppColors.rainCyan, 'ECMWF'),
              const SizedBox(width: 14),
              _legend(const Color(0xFF60A5FA), 'GFS'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barGroups: groups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                          style: AppTheme.label(size: 8)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= w.days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              _names[(w.days[i].date.weekday - 1) % 7],
                              style: AppTheme.label(size: 8)),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.label(size: 9)),
        ],
      );

  Widget _soilCrop(S s, WeatherBundle w) {
    final soil = w.current.soilMoisture * 100;
    final et0 = w.current.et0;
    // 7-day surplus = sum(rain) - sum(et0) over next 7 days approximation.
    final next = w.nextHours(24 * 7);
    final rain = next.fold(0.0, (a, h) => a + h.precipMm);
    final demand = next.fold(0.0, (a, h) => a + h.et0);
    final surplus = rain - demand;

    return SectionCard(
      title: s.t('soil_crop'),
      icon: Icons.water_drop,
      child: Row(
        children: [
          Expanded(
              child: StatTile(
                  value: '${soil.toStringAsFixed(0)}%',
                  label: s.t('soil_moisture'),
                  color: AppColors.growthGreen)),
          const SizedBox(width: 8),
          Expanded(
              child: StatTile(
                  value: '${et0.toStringAsFixed(1)}mm',
                  label: s.t('et0_today'),
                  color: AppColors.rainCyan)),
          const SizedBox(width: 8),
          Expanded(
              child: StatTile(
                  value: '${surplus >= 0 ? '+' : ''}${surplus.toStringAsFixed(0)}mm',
                  label: s.t('surplus_7d'),
                  color: surplus >= 0
                      ? AppColors.growthGreen
                      : AppColors.stormAmber)),
        ],
      ),
    );
  }
}
