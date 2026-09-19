import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

class BudgetPieChart extends StatelessWidget {
  const BudgetPieChart({super.key, required this.byCategory});

  final Map<String, double> byCategory;

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No spending this period')),
      );
    }
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      NBColors.budget,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.blue,
    ];
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 36,
          sections: [
            for (var i = 0; i < entries.length; i++)
              PieChartSectionData(
                value: entries[i].value,
                title: entries[i].key.length > 8
                    ? '${entries[i].key.substring(0, 7)}…'
                    : entries[i].key,
                color: colors[i % colors.length],
                radius: 52,
                titleStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
