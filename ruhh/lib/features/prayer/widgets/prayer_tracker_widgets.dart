import 'package:flutter/material.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/motion/celebration_burst.dart';
import 'package:ruhh/core/motion/animated_progress_bar.dart';
import 'package:ruhh/core/motion/animated_selection.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:ruhh/features/prayer/tracker/prayer_theme.dart';

class NBPrayerStreakBadge extends StatelessWidget {
  const NBPrayerStreakBadge({
    super.key,
    required this.current,
    required this.longest,
  });

  final int current;
  final int longest;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return RuhhSoftCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: PrayerTheme.dhuhr.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(t.radiusChip),
              border: Border.all(color: PrayerTheme.dhuhr, width: 1),
            ),
            child: Text(
              '$current day streak',
              style: theme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: PrayerTheme.dhuhr,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Longest streak',
                  style: t.caption(Theme.of(context).textTheme),
                ),
                Text(
                  '$longest days',
                  style: t.statMedium(Theme.of(context).textTheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NBPrayerCheckTile extends StatelessWidget {
  const NBPrayerCheckTile({
    super.key,
    required this.prayer,
    required this.prayed,
    required this.onTap,
    this.timeLabel,
    this.enabled = true,
  });

  final PrayerName prayer;
  final bool prayed;
  final VoidCallback onTap;
  final String? timeLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final color = PrayerTheme.accentSolid(prayer);
    final fill = prayed ? color.withValues(alpha: 0.18) : PrayerTheme.chipFill(prayer);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(t.radiusInput),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(t.radiusInput),
              border: Border.all(
                color: prayed ? color : color.withValues(alpha: 0.65),
                width: prayed ? 2 : 1,
              ),
            ),
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
                    size: 22,
                    color: PrayerTheme.iconOnAccent(prayer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PrayerTheme.label(prayer),
                        style: t.cardTitle(theme).copyWith(
                              fontSize: 16,
                              color: t.textPrimary,
                            ),
                      ),
                      if (timeLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          timeLabel!,
                          style: t.caption(theme).copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedAppCheckCircle(
                      checked: prayed,
                      activeColor: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NBTodayProgressBar extends StatelessWidget {
  const NBTodayProgressBar({
    super.key,
    required this.ratio,
    this.today,
  });

  final double ratio;
  final DailyPrayerLog? today;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final prayed = today != null ? prayedCount(today!) : (ratio * 5).round();

    return RuhhSoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today\'s prayers',
                  style: t.caption(theme),
                ),
              ),
              Text(
                '$prayed/5',
                style: t.cardTitle(theme).copyWith(
                      color: prayed >= 5
                          ? PrayerTheme.dhuhr
                          : t.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(ratio * 100).round()}%',
            style: t.statLarge(theme),
          ),
          const SizedBox(height: 12),
          if (today != null)
            _PrayerSegmentBar(log: today!)
          else
            AnimatedProgressBar(
              progress: ratio,
              color: PrayerTheme.fajr,
            ),
        ],
      ),
    );
  }
}

class _PrayerSegmentBar extends StatelessWidget {
  const _PrayerSegmentBar({required this.log});

  final DailyPrayerLog log;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < prayerOrder.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _segment(prayerOrder[i]),
          ),
        ],
      ],
    );
  }

  Widget _segment(PrayerName p) {
    final done = log.statuses[p] == TrackerPrayerStatus.prayed;
    final color = PrayerTheme.accentSolid(p);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 8,
      decoration: BoxDecoration(
        color: done ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: color.withValues(alpha: done ? 1 : 0.5),
          width: 1,
        ),
      ),
    );
  }
}

class NBPrayerCalendarLegend extends StatelessWidget {
  const NBPrayerCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;

    Widget chip(String label, Color color, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusChip),
          border: Border.all(color: color.withValues(alpha: 0.7)),
          color: color.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.circle, size: 12, color: color),
            const SizedBox(width: 6),
            Text(label, style: t.micro(theme)),
          ],
        ),
      );
    }

    return RuhhSoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          chip('Perfect 5/5', PrayerTheme.dhuhr, icon: Icons.star_rounded),
          chip('In progress', PrayerTheme.asr, icon: Icons.more_horiz_rounded),
          chip('Missed', const Color(0xFFEF4444), icon: Icons.close_rounded),
          chip('Today', PrayerTheme.fajr, icon: Icons.radio_button_checked),
        ],
      ),
    );
  }
}

/// Five prayer dots — shared by calendar cells and legend.
class MiniPrayerDots extends StatelessWidget {
  const MiniPrayerDots({
    required this.log,
    this.dotSize = 5,
    this.spacing = 3,
  });

  final DailyPrayerLog log;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < prayerOrder.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          _dot(prayerOrder[i]),
        ],
      ],
    );
  }

  Widget _dot(PrayerName p) {
    final done = log.statuses[p] == TrackerPrayerStatus.prayed;
    final color = PrayerTheme.accentSolid(p);
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : color.withValues(alpha: 0.2),
        border: Border.all(
          color: color.withValues(alpha: done ? 1 : 0.45),
          width: 0.75,
        ),
      ),
    );
  }
}

class NBCalendarCell extends StatelessWidget {
  const NBCalendarCell({
    super.key,
    required this.day,
    required this.kind,
    required this.log,
    required this.isTodayHighlight,
  });

  final int day;
  final DayVisualKind kind;
  final DailyPrayerLog log;
  final bool isTodayHighlight;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final prayed = prayedCount(log);
    final isFuture = kind == DayVisualKind.future;

    var borderColor = t.divider;
    var borderWidth = 1.0;
    Color? bg;
    var dayColor = t.textPrimary;

    switch (kind) {
      case DayVisualKind.fullStar:
        borderColor = PrayerTheme.dhuhr;
        borderWidth = 1.5;
        bg = PrayerTheme.dhuhr.withValues(alpha: 0.14);
      case DayVisualKind.excused:
        borderColor = t.textTertiary;
        bg = t.surfaceSecondary.withValues(alpha: 0.45);
        dayColor = t.textSecondary;
      case DayVisualKind.partial:
        borderColor = PrayerTheme.asr.withValues(alpha: 0.55);
        bg = t.surfaceSecondary.withValues(alpha: 0.35);
      case DayVisualKind.allMissed:
        borderColor = const Color(0xFFEF4444).withValues(alpha: 0.45);
        bg = const Color(0xFFEF4444).withValues(alpha: 0.07);
      case DayVisualKind.empty:
        bg = Colors.transparent;
      case DayVisualKind.future:
        bg = Colors.transparent;
        dayColor = t.textTertiary;
      case DayVisualKind.today:
        borderColor = PrayerTheme.fajr;
        borderWidth = 2;
        bg = PrayerTheme.fajr.withValues(alpha: 0.1);
    }

    if (isTodayHighlight) {
      borderColor = PrayerTheme.fajr;
      borderWidth = 2;
      if (kind == DayVisualKind.empty || kind == DayVisualKind.future) {
        bg = PrayerTheme.fajr.withValues(alpha: 0.1);
      }
    }

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (kind == DayVisualKind.fullStar) ...[
                Icon(Icons.star_rounded, size: 11, color: PrayerTheme.dhuhr),
                const SizedBox(width: 2),
              ],
              Text(
                '$day',
                style: theme.labelLarge?.copyWith(
                  fontWeight:
                      isTodayHighlight ? FontWeight.w800 : FontWeight.w600,
                  color: dayColor,
                  fontSize: isTodayHighlight ? 14 : 12,
                  height: 1.1,
                ),
              ),
            ],
          ),
          if (!isFuture && kind != DayVisualKind.excused) ...[
            const SizedBox(height: 3),
            MiniPrayerDots(log: log, dotSize: 4, spacing: 2),
          ] else if (kind == DayVisualKind.excused) ...[
            const SizedBox(height: 2),
            Text(
              '—',
              style: theme.labelSmall?.copyWith(
                fontSize: 8,
                color: t.textTertiary,
              ),
            ),
          ],
          if (kind == DayVisualKind.allMissed && prayed == 0) ...[
            const SizedBox(height: 1),
            Text(
              '0/5',
              style: theme.labelSmall?.copyWith(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444).withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StarRewardOverlay extends StatefulWidget {
  const StarRewardOverlay({
    super.key,
    required this.show,
    required this.child,
  });

  final bool show;
  final Widget child;

  @override
  State<StarRewardOverlay> createState() => _StarRewardOverlayState();
}

class _StarRewardOverlayState extends State<StarRewardOverlay> {
  var _burst = 0;

  @override
  void didUpdateWidget(covariant StarRewardOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      setState(() => _burst++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationBurst(
      trigger: widget.show ? _burst : null,
      child: widget.child,
    );
  }
}
