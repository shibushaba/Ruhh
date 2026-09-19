import 'package:flutter/material.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/habit/habit_logic.dart';

class HabitHeatmapStrip extends StatelessWidget {
  const HabitHeatmapStrip({
    super.key,
    required this.habit,
    required this.byDay,
    this.days = 14,
  });

  final HabitLocal habit;
  final Map<DateTime, double> byDay;
  final int days;

  @override
  Widget build(BuildContext context) {
    final now = HabitLogic.dayOnly(DateTime.now());
    return Row(
      children: List.generate(days, (i) {
        final day = now.subtract(Duration(days: days - 1 - i));
        final v = byDay[day];
        final scheduled = HabitLogic.isScheduledOn(habit, day);
        Color color;
        if (!scheduled) {
          color = Colors.transparent;
        } else if (HabitLogic.isRelapseOn(habit, v)) {
          color = Colors.red.shade400;
        } else if (HabitLogic.isCompletedOn(habit, day, v, now: DateTime.now())) {
          color = Color(habit.colorValue);
        } else if (day.isBefore(now)) {
          color = Colors.grey.shade300;
        } else {
          color = Colors.grey.shade200;
        }
        return Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: scheduled ? NBColors.black : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}
