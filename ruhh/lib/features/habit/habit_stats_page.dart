import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_stat_card.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';
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
            final weekStart =
                habitDateKey(now.subtract(const Duration(days: 6)));

            String? bestName;
            String? worstName;
            var bestRate = -1.0;
            var worstRate = 2.0;
            var weekRateSum = 0.0;
            var bestStreak = 0;
            String? bestStreakHabit;

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
              weekRateSum += completionRateForPeriod(
                h,
                logs,
                weekStart,
                todayKey,
                todayKey,
              );
              final streak = currentStreakForHabit(h, logs, todayKey);
              if (streak > bestStreak) {
                bestStreak = streak;
                bestStreakHabit = h.name;
              }
            }

            final avgWeekRate =
                habits.isEmpty ? 0.0 : weekRateSum / habits.length;

            final milestones = <String>[];
            for (final h in habits) {
              final logs = allLogs[h.remoteId] ?? {};
              final streak = currentStreakForHabit(h, logs, todayKey);
              final m = streakMilestone(streak);
              if (m != null) milestones.add('${h.name}: $m days');
            }

            final t = context.ruhh;
            final heatmapAccent = NBColors.habit;

            return NBPageBody(
              child: ListView(
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _HabitSummaryChip(
                            label: 'Active',
                            value: '${habits.length}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HabitSummaryChip(
                            label: 'This week',
                            value: '${(avgWeekRate * 100).round()}%',
                            accent: heatmapAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HabitSummaryChip(
                            label: 'Top streak',
                            value: bestStreak > 0 ? '$bestStreak d' : '—',
                            subtitle: bestStreakHabit,
                            accent: t.accentAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Last 12 weeks',
                    style: t.cardTitle(Theme.of(context).textTheme),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily completion across all habits',
                    style: t.caption(Theme.of(context).textTheme).copyWith(
                          color: t.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  RuhhSoftCard(
                    radius: t.radiusCardMedium,
                    padding: EdgeInsets.all(t.spaceCardPaddingCompact),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 156,
                          child: GridView.builder(
                            scrollDirection: Axis.horizontal,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 3,
                              crossAxisSpacing: 3,
                              childAspectRatio: 1,
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
                              return NBHeatmapCell(
                                intensity: intensity,
                                accent: heatmapAccent,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        _HabitHeatmapLegend(accent: heatmapAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (bestName != null)
                    NBStatCard(
                      label: 'Best this month',
                      value: bestName,
                      targetLabel: '${(bestRate * 100).round()}%',
                      subtitle: 'Completion rate',
                      progress: bestRate,
                      accent: NBMetrics.incomeGreen,
                      prominentLabel: true,
                    ),
                  const SizedBox(height: 12),
                  if (worstName != null)
                    NBStatCard(
                      label: 'Needs attention',
                      value: worstName,
                      targetLabel: '${(worstRate * 100).round()}%',
                      subtitle: 'Completion rate',
                      progress: worstRate,
                      accent: NBMetrics.expenseRed,
                      prominentLabel: true,
                    ),
                  if (milestones.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Milestones',
                      style: t.cardTitle(Theme.of(context).textTheme),
                    ),
                    const SizedBox(height: 8),
                    ...milestones.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: RuhhSoftCard(
                          radius: t.radiusCardMedium,
                          padding: EdgeInsets.symmetric(
                            horizontal: t.spaceCardPaddingCompact,
                            vertical: 10,
                          ),
                          child: Text(
                            '🎉 $m',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: t.textPrimary,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const RuhhNavClearance(extra: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HabitSummaryChip extends StatelessWidget {
  const _HabitSummaryChip({
    required this.label,
    required this.value,
    this.subtitle,
    this.accent,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final color = accent ?? t.accentMint;
    return RuhhSoftCard(
      radius: t.radiusCardMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            label,
            style: t.caption(Theme.of(context).textTheme).copyWith(
                  color: t.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: t.statMedium(Theme.of(context).textTheme).copyWith(
                  color: color,
                ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: t.micro(Theme.of(context).textTheme),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _HabitHeatmapLegend extends StatelessWidget {
  const _HabitHeatmapLegend({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Row(
      children: [
        Text(
          'Less',
          style: t.micro(Theme.of(context).textTheme).copyWith(
                color: t.textSecondary,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              for (var step = 0; step < 4; step++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: step == 0 ? 0 : 3),
                    child: NBHeatmapCell(
                      intensity: step / 3,
                      accent: accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'More',
          style: t.micro(Theme.of(context).textTheme).copyWith(
                color: t.textSecondary,
              ),
        ),
      ],
    );
  }
}
