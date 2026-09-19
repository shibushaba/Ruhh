import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import 'package:ruhh/core/icons/app_icons.dart';

import 'package:ruhh/core/motion/list_entrance.dart';

import 'package:ruhh/core/theme/nb_colors.dart';

import 'package:ruhh/core/theme/ruhh_tokens.dart';

import 'package:ruhh/core/widgets/nb_layout.dart';

import 'package:ruhh/core/widgets/ruhh_components.dart';

import 'package:ruhh/features/budget/budget_repository.dart';

import 'package:ruhh/features/budget/ledger/budget_inr.dart';

import 'package:ruhh/features/habit/habit_repository.dart';

import 'package:ruhh/features/habit/tracker/habit_calculations.dart';

import 'package:ruhh/features/home/widgets/home_feed_insights.dart';

import 'package:ruhh/features/home/widgets/home_insight_widgets.dart';

import 'package:ruhh/features/movie/movie_repository.dart';

import 'package:ruhh/features/prayer/prayer_repository.dart';

import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';

import 'package:ruhh/features/settings/settings_controller.dart';



class HomePage extends ConsumerWidget {

  const HomePage({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final t = context.ruhh;

    final settings = ref.watch(settingsControllerProvider);



    return Scaffold(

      backgroundColor: Colors.transparent,

      body: NBPageBody(

        child: RefreshIndicator(

          color: t.accentMint,

          onRefresh: () async {

            ref.invalidate(habitRepositoryProvider);

            ref.invalidate(dailyPrayerLogsProvider);

            ref.invalidate(budgetRepositoryProvider);

            ref.invalidate(movieRepositoryProvider);

            bumpHabitRefresh(ref);

            bumpBudgetRefresh(ref);

          },

          child: ListView(

            physics: const AlwaysScrollableScrollPhysics(),

            children: [

              Row(

                children: [

                  IconButton(

                    onPressed: () => context.push('/settings'),

                    icon: Icon(AppIcons.bell()),

                  ),

                  Expanded(

                    child: Text(

                      'Home',

                      style: t.screenTitle(Theme.of(context).textTheme),

                    ),

                  ),

                  RuhhProfileAvatar(onTap: () => context.push('/settings')),

                ],

              ),

              const SizedBox(height: 8),

              StaggeredEntranceColumn(

                children: [

                  HomeDayHeroSection(budgetEnabled: settings.budgetEnabled),

                  SizedBox(height: t.spaceStackGap),

                  const HomeSectionLabel(

                    title: 'Today',

                    subtitle: 'Quick progress across habits & prayer',

                  ),

                  _TwinTodayRow(ref: ref),

                  SizedBox(height: t.spaceStackGap + 4),

                  const HomeSectionLabel(

                    title: 'Insights & trends',

                    subtitle: 'Tap a card to jump in',

                  ),

                  HomeFeedInsights(budgetEnabled: settings.budgetEnabled),

                  SizedBox(height: t.spaceStackGap),

                  const HomeSectionLabel(

                    title: 'Modules',

                    subtitle: 'Streaks, watchlist, and money',

                  ),

                  _ModuleHighlights(

                    ref: ref,

                    budgetEnabled: settings.budgetEnabled,

                  ),

                  SizedBox(height: t.spaceGridGap),

                  RuhhSoftCard(

                    onTap: () => context.push('/analytics'),

                    padding: const EdgeInsets.symmetric(

                      horizontal: 14,

                      vertical: 12,

                    ),

                    child: Row(

                      children: [

                        const Text('📈', style: TextStyle(fontSize: 22)),

                        const SizedBox(width: 12),

                        Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(

                                'Full insights',

                                style: t.cardTitle(

                                  Theme.of(context).textTheme,

                                ),

                              ),

                              Text(

                                'Deeper stats for every module',

                                style: t.caption(

                                  Theme.of(context).textTheme,

                                ),

                              ),

                            ],

                          ),

                        ),

                        Icon(AppIcons.caretRight(), color: t.textTertiary),

                      ],

                    ),

                  ),

                  const SizedBox(height: 72),

                ],

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _TwinTodayRow extends ConsumerWidget {

  const _TwinTodayRow({required this.ref});

  final WidgetRef ref;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    return RuhhTwinMetricRow(

      left: _HabitTodayCompact(ref: this.ref),

      right: _PrayerTodayCompact(ref: this.ref),

    );

  }

}



class _HabitTodayCompact extends ConsumerWidget {

  const _HabitTodayCompact({required this.ref});

  final WidgetRef ref;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final t = context.ruhh;

    final repoAsync = ref.watch(habitRepositoryProvider);

    final logsAsync = ref.watch(habitLogViewsProvider);

    return repoAsync.when(

      loading: () => const SizedBox(height: 120),

      error: (_, __) => const SizedBox.shrink(),

      data: (repo) => logsAsync.when(

        loading: () => const SizedBox(height: 120),

        error: (_, __) => const SizedBox.shrink(),

        data: (logs) => StreamBuilder(

          stream: repo.watchActiveHabits(),

          builder: (context, snap) {

            final habits = snap.data ?? [];

            final score = todayScore(habits, logs, repo.todayKey);

            final subtitle = score.total == 0

                ? 'Nothing due today'

                : score.done == score.total

                    ? 'All caught up'

                    : '${score.total - score.done} left to go';

            return RuhhStatProgressCard(

              compact: true,

              label: 'Today\'s habits',

              value: '${score.done}',

              targetLabel: '/ ${score.total}',

              subtitle: subtitle,

              progress: score.ratio,

              accent: t.accentMint,

              onTap: () => context.go('/habit'),

              onAdd: () => context.push('/habit/new'),

            );

          },

        ),

      ),

    );

  }

}



class _PrayerTodayCompact extends ConsumerWidget {

  const _PrayerTodayCompact({required this.ref});

  final WidgetRef ref;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final t = context.ruhh;

    final logsAsync = ref.watch(dailyPrayerLogsProvider);

    final repoAsync = ref.watch(prayerRepositoryProvider);

    return repoAsync.when(

      loading: () => const SizedBox.shrink(),

      error: (_, __) => const SizedBox.shrink(),

      data: (repo) => logsAsync.when(

        loading: () => const SizedBox.shrink(),

        error: (_, __) => const SizedBox.shrink(),

        data: (logs) {

          final today = resolveDayLog(repo.todayKey, logs, repo.todayKey);

          final ratio = todayRatio(today);

          final prayed = (ratio * 5).round();

          final subtitle = prayed >= 5

              ? 'Day complete'

              : '${5 - prayed} prayer${5 - prayed == 1 ? '' : 's'} left';

          return RuhhStatProgressCard(

            compact: true,

            label: 'Prayers today',

            value: '$prayed',

            targetLabel: '/ 5',

            subtitle: subtitle,

            progress: ratio,

            accent: t.accentLavender,

            onTap: () => context.go('/prayer'),

            onAdd: () => context.go('/prayer'),

          );

        },

      ),

    );

  }

}



class _ModuleHighlights extends ConsumerWidget {

  const _ModuleHighlights({

    required this.ref,

    required this.budgetEnabled,

  });



  final WidgetRef ref;

  final bool budgetEnabled;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final t = context.ruhh;

    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        RuhhTwinMetricRow(

          left: _HabitStreakCompact(ref: this.ref),

          right: _PrayerStreakCompact(ref: this.ref),

        ),

        SizedBox(height: t.spaceStackGap),

        _MovieHighlight(ref: this.ref),

        if (budgetEnabled) ...[

          SizedBox(height: t.spaceStackGap),

          _BudgetHighlight(ref: this.ref),

        ],

      ],

    );

  }

}



class _HabitStreakCompact extends ConsumerWidget {

  const _HabitStreakCompact({required this.ref});

  final WidgetRef ref;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final repoAsync = ref.watch(habitRepositoryProvider);

    return repoAsync.when(

      loading: () => const SizedBox(height: 100),

      error: (_, __) => const SizedBox.shrink(),

      data: (repo) => FutureBuilder(

        future: repo.bestStreakAmongActive(),

        builder: (context, snap) {

          final streak = snap.data ?? 0;

          return RuhhStatProgressCard(

            compact: true,

            label: 'Habit streak',

            value: '$streak',

            targetLabel: 'days',

            subtitle: streak > 0 ? 'Personal best among active' : 'Log to start',

            progress: (streak / 30).clamp(0, 1),

            accent: NBColors.habit,

            onTap: () => context.go('/habit'),

          );

        },

      ),

    );

  }

}



class _PrayerStreakCompact extends ConsumerWidget {

  const _PrayerStreakCompact({required this.ref});

  final WidgetRef ref;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final logsAsync = ref.watch(dailyPrayerLogsProvider);

    final repoAsync = ref.watch(prayerRepositoryProvider);

    return repoAsync.when(

      loading: () => const SizedBox.shrink(),

      error: (_, __) => const SizedBox.shrink(),

      data: (repo) => logsAsync.when(

        loading: () => const SizedBox.shrink(),

        error: (_, __) => const SizedBox.shrink(),

        data: (logs) {

          final summary = repo.computeSummary(logs);

          return RuhhStatProgressCard(

            compact: true,

            label: 'Prayer streak',

            value: '${summary.currentStreak}',

            targetLabel: 'days',

            subtitle: 'Best ${summary.longestStreak} days',

            progress: (summary.currentStreak / 30).clamp(0, 1),

            accent: NBColors.prayer,

            onTap: () => context.go('/prayer'),

          );

        },

      ),

    );

  }

}



class _MovieHighlight extends ConsumerWidget {

  const _MovieHighlight({required this.ref});

  final WidgetRef ref;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final repoAsync = ref.watch(movieRepositoryProvider);

    return repoAsync.when(

      loading: () => RuhhStatProgressCard(label: 'Watchlist', value: '…', progress: 0),

      error: (_, __) => RuhhStatProgressCard(label: 'Watchlist', value: '—', progress: 0),

      data: (repo) => FutureBuilder(

        future: Future.wait([

          repo.watchlistMovies(),

          repo.watchedThisMonth(),

        ]),

        builder: (context, snap) {

          if (!snap.hasData) {

            return RuhhStatProgressCard(label: 'Watchlist', value: '…', progress: 0);

          }

          final list = snap.data![0] as List;

          final watched = snap.data![1] as int;

          final count = list.length;

          final subtitle = count == 0

              ? 'Add something you want to watch'

              : watched > 0

                  ? 'Next: ${list.first.title} · $watched this month'

                  : 'Next: ${list.first.title}';

          return RuhhStatProgressCard(

            label: 'Watchlist',

            value: '$count',

            targetLabel: 'titles',

            subtitle: subtitle,

            progress: (count / 20).clamp(0, 1),

            accent: NBColors.movie,

            onTap: () => context.go('/movie'),

            onAdd: () => context.push('/movie/add'),

          );

        },

      ),

    );

  }

}



class _BudgetHighlight extends ConsumerWidget {

  const _BudgetHighlight({required this.ref});

  final WidgetRef ref;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    ref.watch(budgetRefreshProvider);

    final repoAsync = ref.watch(budgetRepositoryProvider);

    final month = DateTime(DateTime.now().year, DateTime.now().month);

    return repoAsync.when(

      loading: () => RuhhStatProgressCard(label: 'Budget', value: '…', progress: 0),

      error: (_, __) => RuhhStatProgressCard(label: 'Budget', value: '—', progress: 0),

      data: (repo) => FutureBuilder(

        future: repo.monthTotals(month),

        builder: (context, snap) {

          if (!snap.hasData) {

            return RuhhStatProgressCard(label: 'Budget', value: '…', progress: 0);

          }

          final totals = snap.data!;

          final progress = totals.totalIncome <= 0

              ? 0.0

              : (totals.balance / totals.totalIncome).clamp(0.0, 1.0);

          final subtitle = totals.totalIncome > 0

              ? 'Spent ${BudgetInr.format(totals.totalExpense)} · income ${BudgetInr.format(totals.totalIncome)}'

              : 'Log income to track savings';

          return RuhhStatProgressCard(

            label: DateFormat.yMMMM().format(month),

            value: BudgetInr.format(totals.balance),

            targetLabel: 'balance',

            subtitle: subtitle,

            progress: progress,

            accent: NBMetrics.incomeGreen,

            onTap: () => context.go('/budget'),

            onAdd: () => context.push('/budget/add'),

          );

        },

      ),

    );

  }

}


