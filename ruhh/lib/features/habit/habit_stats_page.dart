import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_stat_card.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/habit/widgets/habit_tracker_widgets.dart';

class HabitStatsPage extends ConsumerWidget {
  const HabitStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(habitRefreshProvider);
    final repoAsync = ref.watch(habitRepositoryProvider);
    final logsAsync = ref.watch(habitLogViewsProvider);

    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (repo) => logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (allLogs) => StreamBuilder(
          stream: repo.watchActiveHabits(),
          builder: (context, snap) {
            final habits = snap.data ?? [];
            if (habits.isEmpty) {
              return const NBEmptyState(message: 'Add habits to see stats.');
            }
            final todayKey = repo.todayKey;
            final now = DateTime.now();
            final monthStart = habitDateKey(DateTime(now.year, now.month, 1));

            String? bestName;
            String? worstName;
            var bestRate = -1.0;
            var worstRate = 2.0;
            for (final h in habits) {
              final logs = allLogs[h.remoteId] ?? {};
              final rate = completionRateForPeriod(
                h,
                logs,
                monthStart,
                todayKey,
                todayKey,
              );
              if (rate > bestRate) {
                bestRate = rate;
                bestName = h.name;
              }
              if (rate < worstRate) {
                worstRate = rate;
                worstName = h.name;
              }
            }

            final milestones = <String>[];
            for (final h in habits) {
              final logs = allLogs[h.remoteId] ?? {};
              final streak = currentStreakForHabit(h, logs, todayKey);
              final m = streakMilestone(streak);
              if (m != null) milestones.add('${h.name}: $m days');
            }

            return NBPageBody(
              child: ListView(
                children: [
                  Text('Overview', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text('Last 12 weeks (all habits)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      itemCount: 7 * 12,
                      itemBuilder: (context, i) {
                        final day = DateTime.now().subtract(
                          Duration(days: (7 * 12 - 1) - i),
                        );
                        final key = habitDateKey(day);
                        final intensity = dayScoreOn(
                          habits,
                          allLogs,
                          key,
                          todayKey,
                        );
                        return NBHeatmapCell(intensity: intensity);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (bestName != null)
                    NBStatCard(
                      label: 'Best this month',
                      value: bestName!,
                      accent: const Color(0xFF22C55E),
                    ),
                  const SizedBox(height: 8),
                  if (worstName != null)
                    NBStatCard(
                      label: 'Needs attention',
                      value: worstName!,
                      accent: NBMetrics.expenseRed,
                    ),
                  if (milestones.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Milestones',
                        style: Theme.of(context).textTheme.titleMedium),
                    ...milestones.map((m) => Text('🎉 $m')),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
