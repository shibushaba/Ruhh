import 'package:flutter/material.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/motion/animated_radial_dial.dart';
import 'package:ruhh/core/motion/celebration_burst.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/habit/tracker/habit_appearance.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';

export 'package:ruhh/features/habit/tracker/habit_appearance.dart'
    show habitIconChip, habitIconData, habitIconIsEmoji;

class NBHabitTodayRing extends StatelessWidget {
  const NBHabitTodayRing({
    super.key,
    required this.done,
    required this.total,
    required this.ratio,
    required this.streak,
  });

  final int done;
  final int total;
  final double ratio;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return RuhhTwinMetricRow(
      left: RuhhSoftCard(
        radius: t.radiusCardMedium,
        padding: EdgeInsets.all(t.spaceCardPaddingCompact),
        child: AnimatedRadialDial(
          label: 'Today',
          progress: ratio,
          percentLabel: total == 0 ? '—' : '${(ratio * 100).round()}%',
          accent: t.accentLavender,
          size: 100,
        ),
      ),
      right: RuhhStatProgressCard(
        compact: true,
        label: 'Current streak',
        value: '$streak',
        targetLabel: 'days',
        progress: (streak / 30).clamp(0, 1),
        accent: t.accentAmber,
        trailingIcon: AppIcons.flame(),
      ),
    );
  }
}

class NBHabitTile extends StatelessWidget {
  const NBHabitTile({
    super.key,
    required this.habit,
    required this.log,
    required this.streak,
    required this.onToggle,
    required this.onStep,
    this.onExcuse,
  });

  final HabitLocal habit;
  final HabitLogView log;
  final int streak;
  final VoidCallback onToggle;
  final ValueChanged<double> onStep;
  final VoidCallback? onExcuse;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final color = Color(habit.colorValue);
    final goal = isHabitGoal(habit);
    final done = log.status == HabitLogStatus.completed;
    final target = habitGoalTarget(habit);

    if (goal) {
      final progress = target == 0
          ? 0.0
          : ((log.currentValue ?? 0) / target).clamp(0.0, 1.0);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RuhhSoftCard(
          radius: context.ruhh.radiusCardMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RuhhStatProgressCard(
                compact: true,
                label: habit.name,
                value: '${log.currentValue ?? 0}',
                targetLabel: '/ $target ${habit.unitLabel}',
                progress: progress,
                accent: color,
                trailingIcon: habitIconIsEmoji(habit.icon)
                    ? null
                    : habitIconData(habit.icon),
                trailingEmoji:
                    habitIconIsEmoji(habit.icon) ? habit.icon : null,
              ),
              const SizedBox(height: 12),
              NBGoalStepper(
                onMinus: () => onStep(-habit.incrementAmount),
                onPlus: () => onStep(habit.incrementAmount),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RuhhSelectableRow(
        title: habit.name,
        subtitle: streak > 0 ? 'Streak $streak' : null,
        leading: habitIconChip(habit.icon, color),
        selected: done,
        trailing: RuhhSelectionTrailing.check,
        onTap: onToggle,
      ),
    );
  }
}

class NBGoalStepper extends StatelessWidget {
  const NBGoalStepper({
    super.key,
    required this.onMinus,
    required this.onPlus,
  });

  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RuhhIconCircleButton(icon: AppIcons.minus(), onPressed: onMinus),
        const SizedBox(width: 12),
        RuhhIconCircleButton(icon: AppIcons.plus(), onPressed: onPlus),
      ],
    );
  }
}

class NBHeatmapCell extends StatelessWidget {
  const NBHeatmapCell({super.key, required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final fill = Color.lerp(
      t.canvas,
      t.accentMintPastel,
      intensity.clamp(0.0, 1.0),
    )!;
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: intensity > 0 ? fill : t.canvas,
        borderRadius: BorderRadius.circular(t.radiusChip),
      ),
    );
  }
}

class HabitMilestoneOverlay extends StatefulWidget {
  const HabitMilestoneOverlay({
    super.key,
    required this.milestone,
    required this.child,
  });

  final int? milestone;
  final Widget child;

  @override
  State<HabitMilestoneOverlay> createState() => _HabitMilestoneOverlayState();
}

class _HabitMilestoneOverlayState extends State<HabitMilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(covariant HabitMilestoneOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.milestone != null && widget.milestone != oldWidget.milestone) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationBurst(
      trigger: widget.milestone,
      child: Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,
        if (widget.milestone != null)
          ScaleTransition(
            scale: Tween<double>(begin: 0.3, end: 1.1).animate(
              CurvedAnimation(parent: _c, curve: Curves.elasticOut),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: RuhhRankBadge(label: '${widget.milestone}-day streak!'),
            ),
          ),
      ],
    ),
    );
  }
}
