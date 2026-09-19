import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/nb_stat_card.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/habit/widgets/habit_tracker_widgets.dart';

class HabitDetailPage extends ConsumerStatefulWidget {
  const HabitDetailPage({super.key, required this.remoteId});

  final String remoteId;

  @override
  ConsumerState<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends ConsumerState<HabitDetailPage> {
  DateTime _focused = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(habitRepositoryProvider);
    final logsAsync = ref.watch(habitLogViewsProvider);

    return repoAsync.when(
      loading: () => const NBModuleScaffold(
        title: 'Habit',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => NBModuleScaffold(title: 'Habit', body: Center(child: Text('$e'))),
      data: (repo) => FutureBuilder(
        future: repo.byRemoteId(widget.remoteId),
        builder: (context, hSnap) {
          final habit = hSnap.data;
          if (habit == null) {
            return const NBModuleScaffold(
              title: 'Habit',
              body: Center(child: Text('Not found')),
            );
          }
          return logsAsync.when(
            loading: () => const NBModuleScaffold(
              title: 'Habit',
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                NBModuleScaffold(title: habit.name, body: Center(child: Text('$e'))),
            data: (allLogs) {
              final logs = allLogs[habit.remoteId] ?? {};
              final todayKey = repo.todayKey;
              final now = DateTime.now();
              final monthStart = habitDateKey(DateTime(now.year, now.month, 1));
              final monthEnd = todayKey;
              final rate = completionRateForPeriod(
                habit,
                logs,
                monthStart,
                monthEnd,
                todayKey,
              );

              return NBModuleScaffold(
                title: habit.name,
                glassBackground: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.push('/habit/edit/${habit.remoteId}'),
                  ),
                ],
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder(
                        future: Future.wait([
                          repo.trackerStreak(habit),
                          repo.trackerLongestStreak(habit),
                        ]),
                        builder: (context, s) {
                          final cur = (s.data?[0] as int?) ?? 0;
                          final longest = (s.data?[1] as int?) ?? 0;
                          return Row(
                            children: [
                              Expanded(
                                child: NBStatCard(
                                  label: 'Current streak',
                                  value: '$cur',
                                  accent: Color(habit.colorValue),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: NBStatCard(
                                  label: 'Longest',
                                  value: '$longest',
                                  accent: Color(habit.colorValue),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      NBStatCard(
                        label: 'This month',
                        value: '${(rate * 100).round()}%',
                        accent: Color(habit.colorValue),
                      ),
                      const SizedBox(height: 16),
                      TableCalendar<void>(
                        firstDay: DateTime(2020),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focused,
                        onPageChanged: (d) => setState(() => _focused = d),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focused) {
                            final key = habitDateKey(day);
                            if (!isDue(habit, key)) {
                              return Center(child: Text('${day.day}'));
                            }
                            final log = resolveLog(key, logs, todayKey);
                            final color = Color(habit.colorValue);
                            Widget marker;
                            switch (log.status) {
                              case HabitLogStatus.completed:
                                marker = Container(
                                  color: color,
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              case HabitLogStatus.excused:
                                marker = Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: NBColors.black),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.event_busy, size: 16),
                                  ),
                                );
                              case HabitLogStatus.missed:
                                marker = Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: NBColors.mutedText(
                                        Theme.of(context).brightness,
                                      ),
                                    ),
                                  ),
                                  child: Center(child: Text('${day.day}')),
                                );
                              case HabitLogStatus.pending:
                                marker = Center(child: Text('${day.day}'));
                            }
                            return GestureDetector(
                              onTap: day.isAfter(DateTime.now())
                                  ? null
                                  : () => _editDay(repo, habit, key, log),
                              child: marker,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editDay(
    HabitRepository repo,
    HabitLocal habit,
    String dateKey,
    HabitLogView log,
  ) async {
    if (isHabitGoal(habit)) {
      await repo.stepGoal(
        habit,
        dateKey,
        habitGoalTarget(habit) - (log.currentValue ?? 0),
      );
    } else {
      await repo.toggleSimple(habit, dateKey);
    }
    bumpHabitRefresh(ref);
  }
}
