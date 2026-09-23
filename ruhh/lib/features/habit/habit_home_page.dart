import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/habit/widgets/habit_tracker_widgets.dart';

class HabitHomePage extends ConsumerStatefulWidget {
  const HabitHomePage({super.key});

  @override
  ConsumerState<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends ConsumerState<HabitHomePage> {
  int? _milestone;

  @override
  Widget build(BuildContext context) {
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
          builder: (context, habitSnap) {
            final habits = habitSnap.data ?? [];
            final todayKey = repo.todayKey;
            final due = habits.where((h) => isDue(h, todayKey)).toList();
            final score = todayScore(habits, allLogs, todayKey);

            return HabitMilestoneOverlay(
              milestone: _milestone,
              child: Padding(
                padding: NBLayout.pagePadding.copyWith(
                  bottom: 0,
                  right: NBLayout.pagePadding.right +
                      ruhhEffectiveFabEndInset(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FutureBuilder<int>(
                      future: repo.bestStreakAmongActive(),
                      builder: (context, s) => NBHabitTodayRing(
                        done: score.done,
                        total: score.total,
                        ratio: score.ratio,
                        streak: s.data ?? 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (due.isEmpty)
                      Expanded(
                        child: NBEmptyState(
                          message:
                              'No habits due today — enjoy the break or add a new habit.',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                          itemCount: due.length + 1,
                          itemBuilder: (context, i) {
                            if (i == due.length) {
                              return const RuhhNavClearance(extra: 12);
                            }
                            final h = due[i];
                            final logs = allLogs[h.remoteId] ?? {};
                            final log = resolveLog(todayKey, logs, todayKey);
                            return FutureBuilder<int>(
                              future: repo.trackerStreak(h),
                              builder: (context, s) => NBHabitTile(
                                habit: h,
                                log: log,
                                streak: s.data ?? 0,
                                onToggle: () => _onToggle(repo, h),
                                onStep: (d) => _onStep(repo, h, d),
                                onExcuse: () => _onExcuse(repo, h, log),
                              ),
                            );
                          },
                        ),
                      ),
                    if (habits.isEmpty) ...[
                      const SizedBox(height: 12),
                      NBButton(
                        label: 'Create habit',
                        color: NBColors.habit,
                        onPressed: () => context.push('/habit/new'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onToggle(HabitRepository repo, HabitLocal h) async {
    if (isHabitGoal(h)) return;
    await repo.toggleSimple(h, repo.todayKey);
    final streak = await repo.trackerStreak(h);
    final m = streakMilestone(streak);
    if (m != null) setState(() => _milestone = m);
    bumpHabitRefresh(ref);
  }

  Future<void> _onStep(HabitRepository repo, HabitLocal h, double d) async {
    final view = await repo.stepGoal(h, repo.todayKey, d);
    if (view.status == HabitLogStatus.completed) {
      final streak = await repo.trackerStreak(h);
      final m = streakMilestone(streak);
      if (m != null) setState(() => _milestone = m);
    }
    bumpHabitRefresh(ref);
  }

  Future<void> _onExcuse(
    HabitRepository repo,
    HabitLocal h,
    HabitLogView log,
  ) async {
    await repo.setExcused(
      h,
      repo.todayKey,
      log.status != HabitLogStatus.excused,
    );
    bumpHabitRefresh(ref);
  }
}
