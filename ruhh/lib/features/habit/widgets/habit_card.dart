import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/features/habit/habit_logic.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/tracker/habit_appearance.dart';
import 'package:ruhh/features/habit/widgets/habit_heatmap_strip.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.byDay,
    required this.streak,
    required this.onToggle,
    required this.onAddProgress,
    this.onLongPress,
  });

  final HabitLocal habit;
  final Map<DateTime, double> byDay;
  final int streak;
  final VoidCallback onToggle;
  final void Function(double delta) onAddProgress;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final today = HabitLogic.dayOnly(DateTime.now());
    final scheduled = HabitLogic.isScheduledOn(habit, today);
    final value = byDay[today];
    final done = HabitLogic.isCompletedOn(
      habit,
      today,
      value,
      now: DateTime.now(),
    );
    final color = Color(habit.colorValue);

    return NBGlassSurface(
      accent: color,
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: () => context.push('/habit/edit/${habit.remoteId}'),
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.5),
                  child: habitIconChip(habit.icon, color, size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        habit.kind == HabitKind.negative
                            ? '$streak day clean streak'
                            : '$streak day streak · ${HabitRepository.kindLabel(habit.kind)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!scheduled)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: NBColors.black),
                      color: Colors.grey.shade300,
                    ),
                    child: const Text('Off day', style: TextStyle(fontSize: 11)),
                  )
                else if (habit.kind == HabitKind.quantitative)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => onAddProgress(-habit.incrementAmount),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '${value ?? 0}/${habit.targetPerDay}${habit.unitLabel.isEmpty ? '' : ' ${habit.unitLabel}'}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      IconButton(
                        onPressed: () => onAddProgress(habit.incrementAmount),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  )
                else
                  NBButton(
                    expand: false,
                    label: habit.kind == HabitKind.negative
                        ? (HabitLogic.isRelapseOn(habit, value)
                            ? 'Undo slip'
                            : 'Log slip')
                        : (done ? 'Done' : 'Check'),
                    color: done ? Colors.grey.shade400 : NBColors.habit,
                    onPressed: onToggle,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            HabitHeatmapStrip(habit: habit, byDay: byDay),
          ],
        ),
      ),
    );
  }
}
