import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/budget/tracker/budget_trends_insights.dart';
import 'package:ruhh/features/budget/widgets/category_display.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/home/widgets/home_insight_widgets.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:ruhh/features/prayer/tracker/prayer_theme.dart';

/// Cross-module insight cards for the home feed.
class HomeFeedInsights extends ConsumerStatefulWidget {
  const HomeFeedInsights({super.key, required this.budgetEnabled});

  final bool budgetEnabled;

  @override
  ConsumerState<HomeFeedInsights> createState() => _HomeFeedInsightsState();

  static Future<List<HomeInsightItem>> loadInsights(
    WidgetRef ref,
    bool budgetEnabled,
  ) async {
    final items = <HomeInsightItem>[];

    try {
      final habitRepo = await ref.read(habitRepositoryProvider.future);
      final allLogs = await ref.read(habitLogViewsProvider.future);
      final habits = await habitRepo.activeHabits();
      final score = todayScore(habits, allLogs, habitRepo.todayKey);
      final best = await habitRepo.bestStreakAmongActive();
      if (habits.isEmpty) {
        items.add(
          HomeInsightItem(
            emoji: '🌱',
            tag: 'Habits',
            title: 'Start a habit',
            detail: 'Small daily wins compound — add your first routine.',
            accent: NBColors.habit,
            route: '/habit/new',
          ),
        );
      } else if (score.total > 0 && score.done == score.total) {
        items.add(
          HomeInsightItem(
            emoji: '🔥',
            tag: 'Today',
            title: 'All habits done',
            detail:
                'You cleared ${score.total} due habits today. Best streak $best days.',
            accent: NBColors.habit,
            route: '/habit',
          ),
        );
      } else {
        items.add(
          HomeInsightItem(
            emoji: '📋',
            tag: 'Today',
            title: '${score.done}/${score.total} habits done',
            detail: score.total - score.done > 0
                ? '${score.total - score.done} still open · best streak $best days'
                : 'Nothing due today · best streak $best days',
            accent: NBColors.habit,
            route: '/habit',
          ),
        );
      }
    } catch (_) {}

    try {
      final prayerRepo = await ref.read(prayerRepositoryProvider.future);
      final logs = await ref.read(dailyPrayerLogsProvider.future);
      final summary = prayerRepo.computeSummary(logs);
      final today =
          resolveDayLog(prayerRepo.todayKey, logs, prayerRepo.todayKey);
      final prayed = (todayRatio(today) * 5).round();
      final next = await prayerRepo.nextUnloggedPrayerByTime();
      if (next != null && prayed < 5) {
        final times = await prayerRepo.displayTimesForDay(DateTime.now());
        final timeLabel = times[next];
        items.add(
          HomeInsightItem(
            emoji: '🕌',
            tag: 'Next up',
            title: '${PrayerTheme.label(next)} next',
            detail: timeLabel != null && timeLabel.length >= 5
                ? '$prayed/5 logged · adhan ${timeLabel.substring(0, 5)} · ${summary.currentStreak} day streak'
                : '$prayed/5 logged today · ${summary.currentStreak} day streak',
            accent: PrayerTheme.accentSolid(next),
            route: '/prayer',
          ),
        );
      } else if (prayed >= 5) {
        items.add(
          HomeInsightItem(
            emoji: '⭐',
            tag: 'Prayer',
            title: 'Full day logged',
            detail:
                '${summary.currentStreak} day streak · longest ${summary.longestStreak}',
            accent: NBColors.prayer,
            route: '/prayer',
          ),
        );
      } else {
        items.add(
          HomeInsightItem(
            emoji: '🕌',
            tag: 'Prayer',
            title: '$prayed/5 prayers today',
            detail: '${summary.currentStreak} day streak — tap to log',
            accent: NBColors.prayer,
            route: '/prayer',
          ),
        );
      }
    } catch (_) {}

    try {
      final movieRepo = await ref.read(movieRepositoryProvider.future);
      final watchlist = await movieRepo.watchlistMovies();
      final watchedMonth = await movieRepo.watchedThisMonth();
      if (watchlist.isEmpty) {
        items.add(
          HomeInsightItem(
            emoji: '🎬',
            tag: 'Movies',
            title: 'Build your watchlist',
            detail: 'Save titles you want to see — swipe to mark watched.',
            accent: NBColors.movie,
            route: '/movie/add',
          ),
        );
      } else {
        final next = watchlist.first.title;
        items.add(
          HomeInsightItem(
            emoji: '🍿',
            tag: 'Watchlist',
            title: '${watchlist.length} to watch',
            detail: watchedMonth > 0
                ? 'Up next: $next · $watchedMonth finished this month'
                : 'Up next: $next',
            accent: NBColors.movie,
            route: '/movie',
          ),
        );
      }
    } catch (_) {}

    if (budgetEnabled) {
      try {
        final budgetRepo = await ref.read(budgetRepositoryProvider.future);
        final rows = await budgetRepo.ledgerRows();
        final cats = await budgetRepo.activeCategories(income: false);
        final snap = BudgetTrendsInsights.build(rows);
        final month = DateTime.now();
        final totals = await budgetRepo.monthTotals(month);

        if (snap.topSpend.isNotEmpty) {
          final top = snap.topSpend.first;
          CategoryLocal? cat;
          for (final c in cats) {
            if (c.remoteId == top.categoryId) {
              cat = c;
              break;
            }
          }
          final name = cat != null
              ? categoryChipLabel(cat)
              : BudgetTrendsInsights.categoryLabel(top.categoryId, cats);
          final pct = (top.shareOfExpense * 100).toStringAsFixed(0);
          items.add(
            HomeInsightItem(
              emoji: '📊',
              tag: 'Trending',
              title: 'Top spend: $name',
              detail:
                  '$pct% of last 6 months · ${BudgetInr.format(top.amount)}',
              accent: cat != null
                  ? categoryAccentColor(cat)
                  : NBMetrics.expenseRed,
              route: '/budget?tab=3',
            ),
          );
        }

        if (snap.expenseChangeVsPriorMonth != 0) {
          final down = snap.expenseChangeVsPriorMonth < 0;
          items.add(
            HomeInsightItem(
              emoji: down ? '📉' : '📈',
              tag: 'Trending',
              title: down ? 'Spending down' : 'Spending up',
              detail:
                  '${BudgetInr.format(snap.expenseChangeVsPriorMonth.abs())} vs last month',
              accent: down ? NBMetrics.incomeGreen : NBMetrics.expenseRed,
              route: '/budget?tab=3',
            ),
          );
        }

        if (snap.savingsRate > 0) {
          items.add(
            HomeInsightItem(
              emoji: '💰',
              tag: 'Insight',
              title:
                  '${(snap.savingsRate * 100).toStringAsFixed(0)}% saved (6 mo)',
              detail:
                  'This month balance ${BudgetInr.format(totals.balance)}',
              accent: NBMetrics.incomeGreen,
              route: '/budget',
            ),
          );
        }
      } catch (_) {}
    }

    return items.take(5).toList();
  }
}

class _HomeFeedInsightsState extends ConsumerState<HomeFeedInsights> {
  List<HomeInsightItem>? _items;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant HomeFeedInsights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgetEnabled != widget.budgetEnabled) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(habitRefreshProvider, (_, __) => _reload());
    ref.listen(budgetRefreshProvider, (_, __) => _reload());
    ref.listen(prayerRefreshProvider, (_, __) => _reload());
    ref.watch(habitLogViewsProvider);
    ref.watch(dailyPrayerLogsProvider);

    if (_loading && _items == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_items == null || _items!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in _items!) HomeInsightTile(item: item),
      ],
    );
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final items =
        await HomeFeedInsights.loadInsights(ref, widget.budgetEnabled);
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }
}

class HomeDayHeroSection extends ConsumerStatefulWidget {
  const HomeDayHeroSection({super.key, required this.budgetEnabled});

  final bool budgetEnabled;

  @override
  ConsumerState<HomeDayHeroSection> createState() => _HomeDayHeroSectionState();

  static Future<_HeroCopy> heroCopy(
    WidgetRef ref,
    bool budgetEnabled,
    DateTime now,
  ) async {
    var habitLine = 'Habits — check in when ready';
    var prayerLine = 'Prayer — log your salāh';
    String? budgetLine;
    var headline = 'Here\'s what matters today.';
    var habitProgress = 0.0;
    var prayerProgress = 0.0;

    try {
      final habitRepo = await ref.read(habitRepositoryProvider.future);
      final allLogs = await ref.read(habitLogViewsProvider.future);
      final habits = await habitRepo.activeHabits();
      final score = todayScore(habits, allLogs, habitRepo.todayKey);
      habitProgress = score.ratio;
      if (score.total == 0) {
        habitLine = 'No habits due today';
      } else if (score.done == score.total) {
        habitLine = 'All ${score.total} habits complete';
        headline = 'Strong day — habits are done.';
      } else {
        habitLine =
            '${score.done}/${score.total} habits · ${score.total - score.done} left';
      }
    } catch (_) {}

    try {
      final prayerRepo = await ref.read(prayerRepositoryProvider.future);
      final logs = await ref.read(dailyPrayerLogsProvider.future);
      final today =
          resolveDayLog(prayerRepo.todayKey, logs, prayerRepo.todayKey);
      prayerProgress = todayRatio(today);
      final prayed = (prayerProgress * 5).round();
      prayerLine = prayed >= 5
          ? 'All 5 prayers logged'
          : '$prayed/5 prayers · tap to finish the day';
      if (prayed >= 5 && headline.startsWith('Strong')) {
        headline = 'Great rhythm — habits and prayer on track.';
      }
    } catch (_) {}

    if (budgetEnabled) {
      try {
        final budgetRepo = await ref.read(budgetRepositoryProvider.future);
        final totals = await budgetRepo.monthTotals(now);
        budgetLine =
            '${DateFormat.MMM().format(now)} balance ${BudgetInr.format(totals.balance)}';
        if (totals.totalExpense > 0) {
          budgetLine =
              '$budgetLine · spent ${BudgetInr.format(totals.totalExpense)}';
        }
      } catch (_) {
        budgetLine = 'Budget — log spending to see trends';
      }
    }

    return _HeroCopy(
      headline: headline,
      habitLine: habitLine,
      prayerLine: prayerLine,
      budgetLine: budgetLine,
      habitProgress: habitProgress,
      prayerProgress: prayerProgress,
    );
  }
}

class _HomeDayHeroSectionState extends ConsumerState<HomeDayHeroSection> {
  _HeroCopy? _copy;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(habitRefreshProvider, (_, __) => _reload());
    ref.listen(budgetRefreshProvider, (_, __) => _reload());
    ref.listen(prayerRefreshProvider, (_, __) => _reload());
    ref.watch(habitLogViewsProvider);
    ref.watch(dailyPrayerLogsProvider);

    final c = _copy;
    return HomeDayHero(
      compactHeader: true,
      headline: c?.headline ?? 'Here\'s what matters today.',
      habitLine: c?.habitLine ?? 'Habits —',
      prayerLine: c?.prayerLine ?? 'Prayer —',
      budgetLine: c?.budgetLine,
      habitProgress: c?.habitProgress ?? 0,
      prayerProgress: c?.prayerProgress ?? 0,
    );
  }

  Future<void> _reload() async {
    final copy = await HomeDayHeroSection.heroCopy(
      ref,
      widget.budgetEnabled,
      DateTime.now(),
    );
    if (mounted) setState(() => _copy = copy);
  }
}

class _HeroCopy {
  const _HeroCopy({
    required this.headline,
    required this.habitLine,
    required this.prayerLine,
    this.budgetLine,
    this.habitProgress = 0,
    this.prayerProgress = 0,
  });

  final String headline;
  final String habitLine;
  final String prayerLine;
  final String? budgetLine;
  final double habitProgress;
  final double prayerProgress;
}
