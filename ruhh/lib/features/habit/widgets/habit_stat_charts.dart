import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';

class HabitWeekdayChart extends StatelessWidget {
  const HabitWeekdayChart({super.key, required this.counts});

  final List<int> counts;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxY = counts.fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: maxY < 1 ? 1 : maxY + 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: NBColors.black, width: 2),
              left: BorderSide(color: NBColors.black, width: 2),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  _labels[v.toInt().clamp(0, 6)],
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < 7; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: counts[i].toDouble(),
                    color: NBColors.habit,
                    width: 14,
                    borderSide: const BorderSide(color: NBColors.black, width: 1),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class HabitStreakLineChart extends StatelessWidget {
  const HabitStreakLineChart({super.key, required this.series});

  final List<double> series;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < series.length; i++)
                  FlSpot(i.toDouble(), series[i]),
              ],
              isCurved: true,
              color: NBColors.habit,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitStatSummaryCards extends StatelessWidget {
  const HabitStatSummaryCards({
    super.key,
    required this.total,
    required this.bestStreak,
    required this.consistency,
    required this.perfectDays,
  });

  final int total;
  final int bestStreak;
  final int consistency;
  final int perfectDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _chip('Completions', '$total')),
        const SizedBox(width: 8),
        Expanded(child: _chip('Best streak', '$bestStreak')),
        const SizedBox(width: 8),
        Expanded(child: _chip('Consistency', '$consistency%')),
        const SizedBox(width: 8),
        Expanded(child: _chip('Perfect', '$perfectDays')),
      ],
    );
  }

  Widget _chip(String t, String v) => NBCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: const TextStyle(fontSize: 10)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
