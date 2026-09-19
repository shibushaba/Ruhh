import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/habit/data/aggregated_habit_stats.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/widgets/habit_heatmap_strip.dart';
import 'package:ruhh/features/habit/widgets/habit_stat_charts.dart';

class HabitStatsPage extends ConsumerWidget {
  const HabitStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(habitRefreshProvider);
    final repoAsync = ref.watch(habitRepositoryProvider);
    return repoAsync.when(
      data: (repo) => StreamBuilder(
        stream: repo.watchActiveHabits(),
        builder: (context, snap) {
          final habits = snap.data ?? [];
          if (habits.isEmpty) {
            return const Center(child: Text('Add habits to see statistics.'));
          }
          return FutureBuilder(
            future: AggregatedHabitStats.compute(repo),
            builder: (context, aggSnap) {
              final agg = aggSnap.data;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Statistics',
                      style: Theme.of(context).textTheme.headlineMedium),
                  if (agg != null) ...[
                    const SizedBox(height: 12),
                    HabitStatSummaryCards(
                      total: agg.total,
                      bestStreak: agg.bestStreak,
                      consistency: agg.consistency,
                      perfectDays: agg.perfectDays,
                    ),
                    const SizedBox(height: 16),
                    NBCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('By weekday',
                              style: Theme.of(context).textTheme.titleMedium),
                          HabitWeekdayChart(counts: agg.weekday),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    NBCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Streak trend (90d)',
                              style: Theme.of(context).textTheme.titleMedium),
                          HabitStreakLineChart(series: agg.streakSeries),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Per habit',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...habits.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FutureBuilder(
                        future: Future.wait([
                          repo.streakFor(h),
                          repo.consistencyFor(h),
                          repo.completionsMap(
                            h,
                            since: DateTime.now()
                                .subtract(const Duration(days: 30)),
                          ),
                        ]),
                        builder: (context, s) {
                          if (!s.hasData) {
                            return const NBCard(
                              child: LinearProgressIndicator(),
                            );
                          }
                          final streak = s.data![0] as int;
                          final consistency = s.data![1] as int;
                          final map = s.data![2] as Map<DateTime, double>;
                          return NBCard(
                            color: Color(h.colorValue).withValues(alpha: 0.3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.name,
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                Text(
                                  'Streak $streak · Consistency $consistency%',
                                ),
                                Text(
                                  '${HabitRepository.intervalLabel(h.interval)} · ${HabitRepository.kindLabel(h.kind)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 10),
                                HabitHeatmapStrip(
                                  habit: h,
                                  byDay: map,
                                  days: 30,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              );
            },
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
