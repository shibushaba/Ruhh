import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';

class HabitTodayProgress extends StatelessWidget {
  const HabitTodayProgress({
    super.key,
    required this.done,
    required this.total,
    required this.ratio,
  });

  final int done;
  final int total;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, d MMM').format(DateTime.now());
    final allDone = total > 0 && done == total;

    return NBGlassSurface(
      accent: NBColors.habit,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date[0].toUpperCase() + date.substring(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  allDone
                      ? 'Perfect day — all habits done!'
                      : '$done of $total habits done today',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total == 0 ? 0 : ratio,
                  strokeWidth: 6,
                  backgroundColor: Colors.black12,
                  color: allDone ? Colors.green : NBColors.habit,
                ),
                Text(
                  total == 0 ? '—' : '${(ratio * 100).round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
