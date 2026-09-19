import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/motion/animated_progress_bar.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:ruhh/features/prayer/tracker/prayer_theme.dart';
import 'package:ruhh/features/prayer/widgets/prayer_tracker_widgets.dart';

class PrayerStatsMonthHeader extends StatelessWidget {
  const PrayerStatsMonthHeader({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    this.canGoNext = false,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            DateFormat.yMMMM().format(month),
            textAlign: TextAlign.center,
            style: t.cardTitle(Theme.of(context).textTheme),
          ),
        ),
        IconButton(
          onPressed: canGoNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class PrayerStatsStreakHero extends StatelessWidget {
  const PrayerStatsStreakHero({
    super.key,
    required this.current,
    required this.longest,
  });

  final int current;
  final int longest;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return RuhhSoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _streakColumn(
              context,
              label: 'Current streak',
              value: current,
              color: PrayerTheme.dhuhr,
              emoji: '🔥',
            ),
          ),
          Container(width: 1, height: 56, color: t.divider),
          Expanded(
            child: _streakColumn(
              context,
              label: 'Best streak',
              value: longest,
              color: PrayerTheme.isha,
              emoji: '⭐',
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakColumn(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
    required String emoji,
  }) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: t.caption(theme)),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: t.statHero(theme).copyWith(color: color),
        ),
        Text(
          value == 1 ? 'day' : 'days',
          style: t.caption(theme).copyWith(color: color),
        ),
      ],
    );
  }
}

class PrayerStatsMonthBreakdown extends StatelessWidget {
  const PrayerStatsMonthBreakdown({
    super.key,
    required this.stats,
    required this.daysInPeriod,
  });

  final MonthlyPrayerStats stats;
  final int daysInPeriod;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final pct = (stats.completionPercent * 100).round();

    return RuhhSoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$pct%', style: t.statLarge(theme)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'perfect days',
                  style: t.caption(theme),
                ),
              ),
              Text(
                '${stats.fullyPrayedDays}/$daysInPeriod',
                style: t.cardTitle(theme).copyWith(
                      color: PrayerTheme.dhuhr,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StackedMonthBar(stats: stats, daysInPeriod: daysInPeriod),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LegendChip(
                label: 'Full ${stats.fullyPrayedDays}',
                color: PrayerTheme.dhuhr,
              ),
              _LegendChip(
                label: 'Partial ${stats.partialDays}',
                color: PrayerTheme.asr,
              ),
              _LegendChip(
                label: 'Missed ${stats.missedDays}',
                color: const Color(0xFFEF4444),
              ),
              _LegendChip(
                label: 'Excused ${stats.excusedDays}',
                color: t.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StackedMonthBar extends StatelessWidget {
  const _StackedMonthBar({
    required this.stats,
    required this.daysInPeriod,
  });

  final MonthlyPrayerStats stats;
  final int daysInPeriod;

  @override
  Widget build(BuildContext context) {
    if (daysInPeriod <= 0) return const SizedBox.shrink();
    final segments = <({int count, Color color})>[
      (count: stats.fullyPrayedDays, color: PrayerTheme.dhuhr),
      (count: stats.partialDays, color: PrayerTheme.asr),
      (count: stats.missedDays, color: const Color(0xFFEF4444)),
      (count: stats.excusedDays, color: const Color(0xFF6B7280)),
    ].where((s) => s.count > 0).toList();

    if (segments.isEmpty) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: Theme.of(context).extension<RuhhTokens>()!.surfaceSecondary,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final s in segments)
              Expanded(
                flex: s.count,
                child: ColoredBox(color: s.color),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(t.radiusChip),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: t.micro(Theme.of(context).textTheme).copyWith(color: color),
      ),
    );
  }
}

class PrayerStatsInsights extends StatelessWidget {
  const PrayerStatsInsights({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return RuhhSoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Insights', style: t.cardTitle(theme)),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: theme.bodyMedium),
                  Expanded(
                    child: Text(
                      line,
                      style: theme.bodyMedium?.copyWith(color: t.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PrayerStatsPerPrayerSection extends StatelessWidget {
  const PrayerStatsPerPrayerSection({
    super.key,
    required this.perPrayer,
    required this.daysInPeriod,
  });

  final Map<PrayerName, double> perPrayer;
  final int daysInPeriod;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final sorted = prayerOrder.toList()
      ..sort(
        (a, b) =>
            (perPrayer[a] ?? 0).compareTo(perPrayer[b] ?? 0),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Per prayer', style: t.cardTitle(theme)),
        const SizedBox(height: 4),
        Text(
          'Share of days logged on time this month',
          style: t.caption(theme),
        ),
        const SizedBox(height: 12),
        for (final p in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PrayerRateRow(
              prayer: p,
              rate: perPrayer[p] ?? 0,
              daysInPeriod: daysInPeriod,
            ),
          ),
      ],
    );
  }
}

class _PrayerRateRow extends StatelessWidget {
  const _PrayerRateRow({
    required this.prayer,
    required this.rate,
    required this.daysInPeriod,
  });

  final PrayerName prayer;
  final double rate;
  final int daysInPeriod;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final color = PrayerTheme.accentSolid(prayer);
    final pct = (rate * 100).round();
    final prayedDays = (rate * daysInPeriod).round();

    return RuhhSoftCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(t.radiusChip),
            ),
            alignment: Alignment.center,
            child: Icon(
              PrayerTheme.icon(prayer),
              color: PrayerTheme.iconOnAccent(prayer),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        PrayerTheme.label(prayer),
                        style: t.cardTitle(theme).copyWith(fontSize: 16),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: t.cardTitle(theme).copyWith(color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$prayedDays / $daysInPeriod days',
                  style: t.caption(theme),
                ),
                const SizedBox(height: 8),
                AnimatedProgressBar(
                  progress: rate.clamp(0, 1),
                  color: color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrayerStatsRecentWeek extends StatelessWidget {
  const PrayerStatsRecentWeek({
    super.key,
    required this.days,
    required this.todayKey,
  });

  final List<({String key, DailyPrayerLog log})> days;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    if (days.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Last 7 days', style: t.cardTitle(theme)),
        const SizedBox(height: 10),
        RuhhSoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in days) _WeekDayCell(day: d, todayKey: todayKey),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({required this.day, required this.todayKey});

  final ({String key, DailyPrayerLog log}) day;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final date = parseDateKey(day.key);
    final label = DateFormat.E().format(date).substring(0, 1);
    final isToday = day.key == todayKey;
    final kind = dayVisualKind(day.log, todayKey);

    Color ring = t.divider;
    if (isToday) ring = PrayerTheme.fajr;
    if (kind == DayVisualKind.fullStar) ring = PrayerTheme.dhuhr;

    return Column(
      children: [
        Text(label, style: t.micro(theme)),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ring, width: isToday ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: theme.labelSmall?.copyWith(
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        MiniPrayerDots(log: day.log, dotSize: 3, spacing: 1),
      ],
    );
  }
}

List<String> buildPrayerStatsInsights({
  required MonthlyPrayerStats stats,
  required int daysInPeriod,
  required int currentStreak,
  required Map<PrayerName, double> perPrayer,
}) {
  final lines = <String>[];

  if (stats.fullyPrayedDays > 0) {
    lines.add(
      '${stats.fullyPrayedDays} perfect day${stats.fullyPrayedDays == 1 ? '' : 's'} '
      'this month (${(stats.completionPercent * 100).round()}% of days so far).',
    );
  } else if (daysInPeriod > 0) {
    lines.add('No perfect 5/5 days yet — start with logging today fully.');
  }

  if (stats.missedDays > 0) {
    lines.add(
      '${stats.missedDays} day${stats.missedDays == 1 ? '' : 's'} with all prayers missed — '
      'tap Calendar to backfill or excuse.',
    );
  }

  PrayerName? weakest;
  var lowest = 2.0;
  for (final p in prayerOrder) {
    final r = perPrayer[p] ?? 0;
    if (r < lowest) {
      lowest = r;
      weakest = p;
    }
  }
  if (weakest != null && lowest < 0.85 && daysInPeriod > 3) {
    lines.add(
      '${PrayerTheme.label(weakest)} is your lowest this month '
      '(${(lowest * 100).round()}%) — give it extra focus.',
    );
  }

  if (currentStreak >= 2) {
    lines.add('You\'re on a $currentStreak-day streak — keep today complete.');
  }

  return lines.take(3).toList();
}

List<({String key, DailyPrayerLog log})> lastSevenDays(
  Map<String, DailyPrayerLog> logs,
  String todayKey,
) {
  final today = parseDateKey(todayKey);
  return List.generate(7, (i) {
    final d = today.subtract(Duration(days: 6 - i));
    final key = dateKeyFrom(d);
    final log = resolveDayLog(key, logs, todayKey);
    return (key: key, log: log);
  });
}

int daysInStatsPeriod(DateTime month, String todayKey) {
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final isCurrentMonth =
      month.year == parseDateKey(todayKey).year &&
      month.month == parseDateKey(todayKey).month;
  return isCurrentMonth ? parseDateKey(todayKey).day : daysInMonth;
}
