import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/motion/celebration_burst.dart';
import 'package:ruhh/core/services/notification_permissions.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/tracker/habit_appearance.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/home/logic/home_weekly_consistency.dart';
import 'package:ruhh/features/home/widgets/home_feed_insights.dart';
import 'package:ruhh/features/home/widgets/home_insight_widgets.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:ruhh/features/prayer/tracker/prayer_theme.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class HomeScreenHeader extends ConsumerWidget {
  const HomeScreenHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);
    final name = _displayName(auth.username);
    final now = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BellButton(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${homeTimeGreeting(now)}, $name',
                style: t.statLarge(theme).copyWith(fontSize: 28, height: 1.15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.yMMMMEEEEd().format(now),
                style: t.caption(theme),
              ),
            ],
          ),
        ),
        RuhhProfileAvatar(onTap: () => context.push('/settings')),
      ],
    );
  }

  String _displayName(String? username) {
    if (username == null || username.isEmpty) return 'there';
    if (username.length == 1) return username.toUpperCase();
    return username[0].toUpperCase() + username.substring(1);
  }
}

class _BellButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends ConsumerState<_BellButton> {
  var _showBadge = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final perms = await ref.read(notificationPermissionsProvider.future);
    final s = await perms.readStatus();
    if (mounted) setState(() => _showBadge = !s.notificationsEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push('/settings/notifications'),
      icon: Badge(
        isLabelVisible: _showBadge,
        smallSize: 8,
        child: Icon(AppIcons.bell()),
      ),
    );
  }
}

class HomeInsightChipRow extends ConsumerWidget {
  const HomeInsightChipRow({super.key, required this.budgetEnabled});

  final bool budgetEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<_InsightChipData>>(
      future: _load(ref),
      builder: (context, snap) {
        final chips = snap.data ?? [];
        if (chips.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: context.ruhh.spaceScreenHorizontal,
            ),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _InsightChip(data: chips[i]),
          ),
        );
      },
    );
  }

  Future<List<_InsightChipData>> _load(WidgetRef ref) async {
    final out = <_InsightChipData>[];
    try {
      final habitRepo = await ref.read(habitRepositoryProvider.future);
      final logs = await ref.read(habitLogViewsProvider.future);
      final habits = await habitRepo.activeHabits();
      final bestHabit = await habitRepo.bestStreakAmongActive();
      final prayerRepo = await ref.read(prayerRepositoryProvider.future);
      final prayerLogs = await ref.read(dailyPrayerLogsProvider.future);
      final prayerStreak = prayerRepo.computeSummary(prayerLogs).currentStreak;
      if (bestHabit >= 2 || prayerStreak >= 2) {
        out.add(
          _InsightChipData(
            icon: AppIcons.flame(),
            label:
                '${bestHabit >= prayerStreak ? bestHabit : prayerStreak}-day streak',
            accent: NBColors.habit,
          ),
        );
      }
      final score = todayScore(habits, logs, habitRepo.todayKey);
      final today = resolveDayLog(
        prayerRepo.todayKey,
        prayerLogs,
        prayerRepo.todayKey,
      );
      final prayerPct = todayRatio(today);
      final habitPct = score.ratio;
      final composite = (habitPct + prayerPct) / 2;
      if (composite >= 0.6 && composite < 1.0) {
        out.add(
          _InsightChipData(
            icon: AppIcons.trendUp(),
            label: 'Almost there',
            accent: const Color(0xFF5EEAD4),
          ),
        );
      }
    } catch (_) {}

    if (budgetEnabled) {
      try {
        final budgetRepo = await ref.read(budgetRepositoryProvider.future);
        final budgets = await budgetRepo.budgets();
        if (budgets.isNotEmpty) {
          final limits =
              await budgetRepo.categoryLimitsForBudget(budgets.first.remoteId);
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, 1);
          final end = DateTime(now.year, now.month + 1, 0);
          for (final lim in limits) {
            final spent = await budgetRepo.categorySpentInRange(
              lim.categoryName,
              start,
              end,
            );
            if (lim.limitAmount > 0 && spent / lim.limitAmount >= 0.8) {
              out.add(
                _InsightChipData(
                  icon: AppIcons.wallet(),
                  label: lim.categoryName,
                  accent: spent >= lim.limitAmount
                      ? NBColors.budget
                      : const Color(0xFF38BDF8),
                ),
              );
              break;
            }
          }
        }
      } catch (_) {}
    }

    try {
      final movieRepo = await ref.read(movieRepositoryProvider.future);
      final watchlist = await movieRepo.watchlistMovies();
      final high = watchlist.where((m) => m.priority >= 4).length;
      if (high > 0) {
        out.add(
          _InsightChipData(
            icon: AppIcons.film(),
            label: '$high to watch',
            accent: NBColors.movie,
          ),
        );
      }
    } catch (_) {}

    return out;
  }
}

class _InsightChipData {
  _InsightChipData({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.data});

  final _InsightChipData data;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: t.pastelForAccent(data.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 16, color: data.accent),
          const SizedBox(width: 6),
          Text(
            data.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class HomeWeeklyTrendSection extends ConsumerWidget {
  const HomeWeeklyTrendSection({super.key, required this.budgetEnabled});

  final bool budgetEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<({List<DailyConsistencyPoint> points, String takeaway})>(
      future: _load(ref),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const RuhhLineChartCard(title: 'Your Week', spots: []);
        }
        final points = snap.data!.points;
        final spots = List.generate(
          points.length,
          (i) => Offset(i.toDouble(), points[i].score),
        );
        final takeaway = snap.data!.takeaway;
        final t = context.ruhh;
        final trendUp = takeaway.contains('up') || takeaway.contains('stronger');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RuhhLineChartCard(title: 'Your Week', spots: spots),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trendUp ? AppIcons.trendUp() : AppIcons.trendDown(),
                  size: 16,
                  color: t.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(takeaway, style: t.caption(Theme.of(context).textTheme)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<({List<DailyConsistencyPoint> points, String takeaway})> _load(
    WidgetRef ref,
  ) async {
    final habitRepo = await ref.read(habitRepositoryProvider.future);
    final habits = await habitRepo.activeHabits();
    final habitLogs = await ref.read(habitLogViewsProvider.future);
    final prayerLogs = await ref.read(dailyPrayerLogsProvider.future);
    final prayerRepo = await ref.read(prayerRepositoryProvider.future);
    final todayKey = habitRepo.todayKey;

    Future<bool> budgetOk(String dateKey) async {
      if (!budgetEnabled) return true;
      try {
        final budgetRepo = await ref.read(budgetRepositoryProvider.future);
        final budgets = await budgetRepo.budgets();
        if (budgets.isEmpty) return true;
        final limits =
            await budgetRepo.categoryLimitsForBudget(budgets.first.remoteId);
        final parts = dateKey.split('-');
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final start = DateTime(d.year, d.month, 1);
        final end = DateTime(d.year, d.month, d.day, 23, 59, 59);
        for (final lim in limits) {
          if (lim.limitAmount <= 0) continue;
          final spent = await budgetRepo.categorySpentInRange(
            lim.categoryName,
            start,
            end,
          );
          if (spent > lim.limitAmount) return false;
        }
        return true;
      } catch (_) {
        return true;
      }
    }

    final points = <DailyConsistencyPoint>[];
    final now = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final key = dateKeyFromDate(day);
      final score = dailyConsistencyScore(
        dateKey: key,
        todayKey: todayKey,
        habitsEnabled: true,
        prayerEnabled: true,
        budgetEnabled: budgetEnabled,
        habits: habits,
        habitLogsByHabit: habitLogs,
        prayerLogsByDate: prayerLogs,
        budgetWithinLimitOnDay: await budgetOk(key),
      );
      points.add(
        DailyConsistencyPoint(
          date: day,
          label: DateFormat.E().format(day).substring(0, 3),
          score: score,
          isToday: i == 0,
        ),
      );
    }
    return (points: points, takeaway: weekOverWeekTakeaway(points));
  }
}

class HomeInsightsCarousel extends ConsumerWidget {
  const HomeInsightsCarousel({super.key, required this.budgetEnabled});

  final bool budgetEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<HomeInsightItem>>(
      future: HomeFeedInsights.loadInsights(ref, budgetEnabled),
      builder: (context, snap) {
        final items = (snap.data ?? [])
            .where((e) => !e.title.toLowerCase().contains('start a habit'))
            .take(4)
            .toList();
        if (items.isEmpty) return const SizedBox.shrink();
        final t = context.ruhh;
        return SizedBox(
          height: 132,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: t.spaceScreenHorizontal),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.72,
                  child: RuhhSoftCard(
                    radius: 20,
                    onTap: () => context.go(item.route),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        RuhhIconChip(
                          icon: Icons.lightbulb_outline,
                          accent: item.accent,
                          emoji: item.emoji,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${item.title} — ${item.detail}',
                            style: t.caption(Theme.of(context).textTheme)
                                .copyWith(color: t.textPrimary),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class HomeTodaysFocusSection extends ConsumerStatefulWidget {
  const HomeTodaysFocusSection({super.key});

  @override
  ConsumerState<HomeTodaysFocusSection> createState() =>
      _HomeTodaysFocusSectionState();
}

class _HomeTodaysFocusSectionState extends ConsumerState<HomeTodaysFocusSection> {
  var _celebrate = false;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final settings = ref.watch(settingsControllerProvider);
    return FutureBuilder<List<_FocusRow>>(
      future: _load(settings.budgetEnabled),
      builder: (context, snap) {
        final rows = snap.data ?? [];
        if (rows.isEmpty) {
          return CelebrationBurst(
            trigger: _celebrate ? 1 : null,
            child: RuhhSoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(AppIcons.checkCircle(), color: t.accentMint, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'All caught up',
                    style: t.cardTitle(Theme.of(context).textTheme),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nothing left on today\'s list.',
                    style: t.caption(Theme.of(context).textTheme),
                  ),
                ],
              ),
            ),
          );
        }
        return RuhhSoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              for (final row in rows) ...[
                RuhhSelectableRow(
                  title: row.title,
                  subtitle: row.subtitle,
                  leading: RuhhIconChip(
                    icon: row.icon,
                    accent: row.accent,
                    emoji: row.emoji,
                    size: 36,
                  ),
                  selected: row.done,
                  trailing: RuhhSelectionTrailing.checkbox,
                  onTap: () => _toggle(row),
                ),
                if (row != rows.last) Divider(height: 1, color: t.divider),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<List<_FocusRow>> _load(bool budgetEnabled) async {
    final out = <_FocusRow>[];
    try {
      final habitRepo = await ref.read(habitRepositoryProvider.future);
      final logs = await ref.read(habitLogViewsProvider.future);
      final habits = await habitRepo.activeHabits();
      final key = habitRepo.todayKey;
      for (final h in habits) {
        if (!isDue(h, key)) continue;
        final log = resolveLog(key, logs[h.remoteId] ?? {}, key);
        final done = log.status == HabitLogStatus.completed;
        if (done) continue;
        out.add(
          _FocusRow(
            kind: _FocusKind.habit,
            id: h.remoteId,
            title: h.name,
            subtitle: 'Habit · due today',
            accent: Color(h.colorValue),
            icon: habitIconData(h.icon),
            emoji: null,
            done: false,
          ),
        );
      }
    } catch (_) {}

    try {
      final prayerRepo = await ref.read(prayerRepositoryProvider.future);
      final logs = await ref.read(dailyPrayerLogsProvider.future);
      final today = resolveDayLog(prayerRepo.todayKey, logs, prayerRepo.todayKey);
      for (final p in prayerOrder) {
        if (today.statuses[p] == TrackerPrayerStatus.prayed) continue;
        out.add(
          _FocusRow(
            kind: _FocusKind.prayer,
            id: p.name,
            title: PrayerTheme.label(p),
            subtitle: 'Prayer',
            accent: PrayerTheme.accentSolid(p),
            icon: AppIcons.prayer(),
            done: false,
          ),
        );
      }
    } catch (_) {}

    if (out.isEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _celebrate = true);
      });
    }
    return out;
  }

  Future<void> _toggle(_FocusRow row) async {
    if (row.kind == _FocusKind.habit) {
      final repo = await ref.read(habitRepositoryProvider.future);
      HabitLocal? habit;
      for (final h in await repo.activeHabits()) {
        if (h.remoteId == row.id) {
          habit = h;
          break;
        }
      }
      if (habit == null) return;
      await repo.markDone(habit);
      bumpHabitRefresh(ref);
    } else if (row.kind == _FocusKind.prayer) {
      final prayerRepo = await ref.read(prayerRepositoryProvider.future);
      final p = PrayerName.values.byName(row.id);
      await prayerRepo.toggleTrackerPrayer(prayerRepo.todayKey, p);
      ref.invalidate(dailyPrayerLogsProvider);
      bumpPrayerRefresh(ref);
    }
    if (mounted) setState(() {});
  }
}

enum _FocusKind { habit, prayer }

class _FocusRow {
  _FocusRow({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle,
    required this.accent,
    required this.icon,
    this.emoji,
    required this.done,
  });

  final _FocusKind kind;
  final String id;
  final String title;
  final String? subtitle;
  final Color accent;
  final IconData icon;
  final String? emoji;
  final bool done;
}

class HomeMonthSnapshotGrid extends ConsumerWidget {
  const HomeMonthSnapshotGrid({super.key, required this.budgetEnabled});

  final bool budgetEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Widget>>(
      future: _cells(ref),
      builder: (context, snap) {
        final cells = snap.data ?? [];
        if (cells.isEmpty) return const SizedBox.shrink();
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: cells,
        );
      },
    );
  }

  Future<List<Widget>> _cells(WidgetRef ref) async {
    final out = <Widget>[];
    final now = DateTime.now();
    try {
      final habitRepo = await ref.read(habitRepositoryProvider.future);
      final logs = await ref.read(habitLogViewsProvider.future);
      final habits = await habitRepo.activeHabits();
      final start = dateKeyFromDate(DateTime(now.year, now.month, 1));
      final end = habitRepo.todayKey;
      var sum = 0.0;
      var denom = 0;
      for (final h in habits) {
        sum += completionRateForPeriod(
          h,
          logs[h.remoteId] ?? {},
          start,
          end,
          end,
        );
        denom++;
      }
      final pct = denom == 0 ? 0 : ((sum / denom) * 100).round();
      out.add(
        RuhhStatProgressCard(
          compact: true,
          label: 'Habits',
          value: '$pct',
          targetLabel: '%',
          subtitle: 'This month',
          progress: pct / 100,
          accent: NBColors.habit,
          onTap: () {},
        ),
      );
    } catch (_) {}

    try {
      final prayerRepo = await ref.read(prayerRepositoryProvider.future);
      final logs = await ref.read(dailyPrayerLogsProvider.future);
      final monthStart = DateTime(now.year, now.month, 1);
      var prayedDays = 0;
      var days = 0;
      for (var d = monthStart;
          !d.isAfter(now);
          d = d.add(const Duration(days: 1))) {
        final key = dateKeyFromDate(d);
        final log = resolveDayLog(key, logs, prayerRepo.todayKey);
        days++;
        if (todayRatio(log) >= 1) prayedDays++;
      }
      final pct = days == 0 ? 0 : ((prayedDays / days) * 100).round();
      out.add(
        RuhhStatProgressCard(
          compact: true,
          label: 'Prayer',
          value: '$pct',
          targetLabel: '%',
          subtitle: 'This month',
          progress: pct / 100,
          accent: NBColors.prayer,
          onTap: () {},
        ),
      );
    } catch (_) {}

    try {
      final movieRepo = await ref.read(movieRepositoryProvider.future);
      final watched = await movieRepo.watchedThisMonth();
      out.add(
        RuhhStatProgressCard(
          compact: true,
          label: 'Movies',
          value: '$watched',
          targetLabel: 'watched',
          subtitle: DateFormat.MMMM().format(now),
          progress: (watched / 10).clamp(0, 1),
          accent: NBColors.movie,
          onTap: () {},
        ),
      );
    } catch (_) {}

    if (budgetEnabled) {
      try {
        final budgetRepo = await ref.read(budgetRepositoryProvider.future);
        final totals = await budgetRepo.monthTotals(now);
        out.add(
          RuhhStatProgressCard(
            compact: true,
            label: 'Budget',
            value: BudgetInr.format(totals.balance),
            targetLabel: '',
            subtitle: 'Balance',
            progress: 0.5,
            accent: NBColors.budget,
            onTap: () {},
          ),
        );
      } catch (_) {}
    }
    return out;
  }
}

class HomeNotificationBanner extends ConsumerWidget {
  const HomeNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permsAsync = ref.watch(notificationPermissionsProvider);
    return permsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (perms) => FutureBuilder(
        future: Future.wait([
          perms.readStatus(),
          perms.isHomeBannerDismissed(),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final status = snap.data![0] as NotificationPermissionStatus;
          final dismissed = snap.data![1] as bool;
          if (status.notificationsEnabled || dismissed) {
            return const SizedBox.shrink();
          }
          final t = context.ruhh;
          return RuhhSoftCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications are off — reminders won\'t fire.',
                    style: t.caption(Theme.of(context).textTheme),
                  ),
                ),
                TextButton(
                  onPressed: perms.openAppNotificationSettings,
                  child: const Text('Fix'),
                ),
                IconButton(
                  onPressed: () async {
                    await perms.dismissHomeBanner();
                    ref.invalidate(notificationPermissionsProvider);
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
