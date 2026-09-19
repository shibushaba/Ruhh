import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/motion/animated_progress_bar.dart';
import 'package:ruhh/core/motion/animated_segmented_control.dart';
import 'package:ruhh/core/motion/animated_selection.dart';
import 'package:ruhh/core/motion/pressable_scale.dart';
import 'package:ruhh/core/theme/portfolio_palette.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';

// --- Surfaces ---

class _SectionAddButton extends StatelessWidget {
  const _SectionAddButton({required this.accent, required this.onPressed});

  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(t.radiusChip),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusChip),
            border: Border.all(color: PortfolioPalette.borderHighlight, width: 1),
          ),
          child: Icon(AppIcons.plus(filled: true), size: 18, color: t.textPrimary),
        ),
      ),
    );
  }
}

class RuhhSoftCard extends StatelessWidget {
  const RuhhSoftCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double? radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    Widget inner = Padding(
      padding: padding ?? EdgeInsets.all(t.spaceCardPadding),
      child: child,
    );
    final r = this.radius ?? t.radiusCardLarge;
    final corner = BorderRadius.circular(r);
    final box = DecoratedBox(
      decoration: vectorPanelDecoration(
        context,
        borderRadius: corner,
        tint: t.surfacePrimary,
      ),
      child: inner,
    );
    if (onTap == null) return box;
    return PressableScale(onTap: onTap, gentle: true, child: box);
  }
}

class RuhhIconChip extends StatelessWidget {
  const RuhhIconChip({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 40,
  });

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.pastelForAccent(accent),
        borderRadius: BorderRadius.circular(t.radiusChip),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: accent),
    );
  }
}

// --- §7.1 Stat + progress ---

class RuhhStatProgressCard extends StatelessWidget {
  const RuhhStatProgressCard({
    super.key,
    required this.label,
    required this.value,
    this.targetLabel,
    this.progress = 0,
    this.accent,
    this.compact = false,
    this.trailingIcon,
    this.subtitle,
    this.onTap,
    this.onAdd,
  });

  final String label;
  final String value;
  final String? targetLabel;
  final double progress;
  final Color? accent;
  final bool compact;
  final IconData? trailingIcon;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final barColor = accent ?? t.accentMint;
    final radius = compact ? t.radiusCardMedium : t.radiusCardLarge;
    return RuhhSoftCard(
      radius: radius,
      onTap: onTap,
      padding: EdgeInsets.all(
        compact ? t.spaceCardPaddingCompact : t.spaceCardPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: t.caption(Theme.of(context).textTheme),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onAdd != null)
                _SectionAddButton(accent: barColor, onPressed: onAdd!),
              if (trailingIcon != null)
                RuhhIconChip(icon: trailingIcon!, accent: barColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: compact
                      ? t.statLarge(Theme.of(context).textTheme)
                      : t.statHero(Theme.of(context).textTheme),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (targetLabel != null) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    targetLabel!,
                    style: t.caption(Theme.of(context).textTheme),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: t.caption(Theme.of(context).textTheme).copyWith(
                    color: t.textSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          AnimatedProgressBar(
            progress: progress,
            color: barColor,
          ),
          if (onTap != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                AppIcons.caretRight(),
                size: 18,
                color: t.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RuhhTwinMetricRow extends StatelessWidget {
  const RuhhTwinMetricRow({
    super.key,
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: t.spaceGridGap),
        Expanded(child: right),
      ],
    );
  }
}

// --- §7.7 Radial dial ---

class RuhhRadialDial extends StatelessWidget {
  const RuhhRadialDial({
    super.key,
    required this.value,
    required this.label,
    this.progress = 0,
    this.accent,
    this.size = 120,
  });

  final String value;
  final String label;
  final double progress;
  final Color? accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final color = accent ?? t.accentLavender;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1),
              strokeWidth: 8,
              backgroundColor: t.pastelForAccent(color),
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: t.statMedium(Theme.of(context).textTheme),
                textAlign: TextAlign.center,
              ),
              Text(
                label,
                style: t.caption(Theme.of(context).textTheme),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- §7.6 Rank badge ---

class RuhhRankBadge extends StatelessWidget {
  const RuhhRankBadge({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: t.accentAmberPastel,
        borderRadius: BorderRadius.circular(t.radiusChip),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusChip),
      child: chip,
    );
  }
}

// --- §7.11 Selectable row ---

enum RuhhSelectionTrailing { radio, check, checkbox }

class RuhhSelectableRow extends StatelessWidget {
  const RuhhSelectableRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    required this.selected,
    this.trailing = RuhhSelectionTrailing.radio,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final RuhhSelectionTrailing trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusInput),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              RuhhIconChip(icon: icon, accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.cardTitle(Theme.of(context).textTheme)
                          .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: t.caption(Theme.of(context).textTheme),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _trailing(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailing(RuhhTokens t) {
    switch (trailing) {
      case RuhhSelectionTrailing.check:
        return SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedAppCheckCircle(checked: selected),
          ),
        );
      case RuhhSelectionTrailing.checkbox:
        return SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedAppCheckbox(checked: selected),
          ),
        );
      case RuhhSelectionTrailing.radio:
        return SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedAppRadio(selected: selected),
          ),
        );
    }
  }
}

// --- §7.18 Segmented chips ---

class RuhhSegmentedChips extends StatelessWidget {
  const RuhhSegmentedChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedSegmentedControl(
      labels: labels,
      selectedIndex: selectedIndex,
      onSelected: onSelected,
    );
  }
}

// --- §7.12 Segmented icon row ---

class RuhhSegmentedIconRow extends StatelessWidget {
  const RuhhSegmentedIconRow({
    super.key,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.canvas,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          for (var i = 0; i < icons.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: Material(
                  color: selectedIndex == i ? t.surfacePrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  elevation: selectedIndex == i ? 1 : 0,
                  shadowColor: t.elevationShadowColor,
                  child: InkWell(
                    onTap: () => onSelected(i),
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 44,
                      child: Icon(
                        icons[i],
                        color: selectedIndex == i
                            ? t.textPrimary
                            : t.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- §7.10 Step progress ---

class RuhhStepProgress extends StatelessWidget {
  const RuhhStepProgress({
    super.key,
    required this.stepCount,
    required this.currentStep,
  });

  final int stepCount;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Row(
      children: [
        for (var i = 0; i < stepCount; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentStep ? t.accentMint : t.divider,
              ),
            ),
          _StepDot(
            index: i + 1,
            done: i < currentStep,
            current: i == currentStep,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.done,
    required this.current,
  });

  final int index;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? t.accentMint : Colors.transparent,
        border: Border.all(
          color: done || current ? t.accentMint : t.divider,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(
              '$index',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: current ? t.accentMint : t.textSecondary,
              ),
            ),
    );
  }
}

// --- §7.15 Timeline row (flat) ---

class RuhhTimelineRow extends StatelessWidget {
  const RuhhTimelineRow({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.amount,
    this.amountColor,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final String amount;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RuhhIconChip(icon: icon, accent: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: t.textPrimary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: t.caption(Theme.of(context).textTheme),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: t.statMedium(Theme.of(context).textTheme).copyWith(
                  fontSize: 16,
                  color: amountColor ?? t.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

// --- §7.8 Floating nav ---

class RuhhFloatingNav extends StatelessWidget {
  const RuhhFloatingNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<RuhhNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final count = destinations.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.surfacePrimary,
          borderRadius: BorderRadius.circular(t.radiusNavBar),
          border: Border.all(color: PortfolioPalette.borderHighlight, width: 1),
          boxShadow: t.shadowNav,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segW = constraints.maxWidth / count;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: segW * selectedIndex.clamp(0, count - 1) + 4,
                    top: 4,
                    bottom: 4,
                    width: segW - 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.textPrimary,
                        borderRadius:
                            BorderRadius.circular(t.radiusNavActive),
                        border: Border.all(
                          color: PortfolioPalette.borderHighlight,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < count; i++)
                        Expanded(
                          child: _NavIcon(
                            icon: destinations[i].icon,
                            selectedIcon: destinations[i].selectedIcon,
                            selected: i == selectedIndex,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class RuhhNavDestination {
  const RuhhNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

class _NavIcon extends StatefulWidget {
  const _NavIcon({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> {
  @override
  void didUpdateWidget(covariant _NavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return PressableScale(
      onTap: widget.onTap,
      pressedScale: 0.92,
      child: SizedBox(
        height: 44,
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(widget.selected),
            tween: Tween(begin: 1.0, end: widget.selected ? 1.15 : 1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale.clamp(0.9, 1.2),
                child: child,
              );
            },
            child: Icon(
              widget.selected ? widget.selectedIcon : widget.icon,
              size: 26,
              color: widget.selected ? t.canvas : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// --- §8 Buttons ---

class RuhhPrimaryButton extends StatelessWidget {
  const RuhhPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final cs = Theme.of(context).colorScheme;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: cs.onPrimary),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
        ),
      ],
    );
    return SizedBox(
      width: expand ? double.infinity : null,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusButton),
          color: onPressed == null
              ? t.textSecondary.withValues(alpha: 0.35)
              : cs.primary,
          border: Border.all(color: PortfolioPalette.borderHighlight, width: 1),
          boxShadow: onPressed != null ? t.shadowPrimaryButton : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(t.radiusButton),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class RuhhSecondaryButton extends StatelessWidget {
  const RuhhSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return SizedBox(
      width: expand ? double.infinity : null,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusButton),
          color: Colors.transparent,
          border: Border.all(color: PortfolioPalette.borderHighlight, width: 1),
          boxShadow: t.shadowPrimaryButton,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(t.radiusButton),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RuhhIconCircleButton extends StatelessWidget {
  const RuhhIconCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Material(
      color: t.surfacePrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusChip),
        side: BorderSide(color: PortfolioPalette.borderHighlight),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(t.radiusChip),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 22, color: t.textPrimary),
        ),
      ),
    );
  }
}

// --- §7.9 Hero ---

class RuhhGradientHero extends StatelessWidget {
  const RuhhGradientHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.primaryLabel,
    this.onPrimary,
  });

  final String title;
  final String subtitle;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusCardLarge),
        gradient: LinearGradient(
          colors: [t.accentLavender, t.accentSky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: t.shadowCard,
      ),
      child: Padding(
        padding: EdgeInsets.all(t.spaceCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: t.screenTitle(Theme.of(context).textTheme)
                  .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: t.caption(Theme.of(context).textTheme).copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
            ),
            if (primaryLabel != null) ...[
              const SizedBox(height: 20),
              RuhhPrimaryButton(
                label: primaryLabel!,
                onPressed: onPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- §7.13 Comment-style row ---

class RuhhInsightRow extends StatelessWidget {
  const RuhhInsightRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.tag,
    this.tagPastel,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final String? tag;
  final Color? tagPastel;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return RuhhSoftCard(
      radius: t.radiusCardMedium,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.cardTitle(Theme.of(context).textTheme),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: t.caption(Theme.of(context).textTheme),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tagPastel ?? t.accentAmberPastel,
                borderRadius: BorderRadius.circular(t.radiusChip),
              ),
              child: Text(
                tag!,
                style: t.micro(Theme.of(context).textTheme),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Empty chart ---

class RuhhEmptyChartPlaceholder extends StatelessWidget {
  const RuhhEmptyChartPlaceholder({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return SizedBox(
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: t.divider, width: 1, style: BorderStyle.solid),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(message, style: t.caption(Theme.of(context).textTheme)),
        ],
      ),
    );
  }
}

// --- §7.2 / §7.3 Chart cards (fl_chart wrappers) ---

class RuhhLineChartCard extends StatelessWidget {
  const RuhhLineChartCard({
    super.key,
    required this.title,
    required this.spots,
    this.emptyMessage = 'No data yet',
  });

  final String title;
  final List<Offset> spots;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return RuhhSoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: t.cardTitle(Theme.of(context).textTheme)),
          const SizedBox(height: 16),
          if (spots.isEmpty)
            RuhhEmptyChartPlaceholder(message: emptyMessage)
          else
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _SimpleLinePainter(
                  spots: spots,
                  color: t.accentSky,
                  fill: t.accentSky.withValues(alpha: 0.25),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SimpleLinePainter extends CustomPainter {
  _SimpleLinePainter({
    required this.spots,
    required this.color,
    required this.fill,
  });

  final List<Offset> spots;
  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (spots.length < 2) return;
    final maxX = spots.map((e) => e.dx).reduce(math.max);
    final maxY = spots.map((e) => e.dy).reduce(math.max);
    final minY = spots.map((e) => e.dy).reduce(math.min);
    final rangeY = (maxY - minY).clamp(1.0, double.infinity);

    Offset map(Offset p) => Offset(
          p.dx / maxX * size.width,
          size.height - (p.dy - minY) / rangeY * (size.height - 16) - 8,
        );

    final path = Path()..moveTo(map(spots.first).dx, size.height);
    for (final s in spots) {
      path.lineTo(map(s).dx, map(s).dy);
    }
    path.lineTo(map(spots.last).dx, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = fill);

    final line = Path()..moveTo(map(spots.first).dx, map(spots.first).dy);
    for (var i = 1; i < spots.length; i++) {
      line.lineTo(map(spots[i]).dx, map(spots[i]).dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SimpleLinePainter oldDelegate) =>
      oldDelegate.spots != spots;
}

class RuhhBarChartCard extends StatelessWidget {
  const RuhhBarChartCard({
    super.key,
    required this.title,
    required this.values,
    required this.labels,
    this.selectedIndex = 0,
    this.emptyMessage = 'No data yet',
  });

  final String title;
  final List<double> values;
  final List<String> labels;
  final int selectedIndex;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final max = values.isEmpty ? 1.0 : values.reduce(math.max);
    return RuhhSoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: t.cardTitle(Theme.of(context).textTheme)),
          const SizedBox(height: 16),
          if (values.isEmpty)
            RuhhEmptyChartPlaceholder(message: emptyMessage)
          else
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (i == selectedIndex)
                              Text(
                                values[i].toStringAsFixed(0),
                                style: t.micro(Theme.of(context).textTheme),
                              ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: (values[i] / max).clamp(0.05, 1),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: i == selectedIndex
                                          ? t.accentPeach
                                          : t.accentSlate.withValues(alpha: 0.3),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              labels[i],
                              style: t.micro(Theme.of(context).textTheme),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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

// --- Top bar ---

class RuhhScreenHeader extends StatelessWidget {
  const RuhhScreenHeader({
    super.key,
    required this.title,
    this.actions,
  });

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.spaceScreenHorizontal,
        t.spaceScreenHorizontal * 0.8,
        t.spaceScreenHorizontal,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: t.screenTitle(Theme.of(context).textTheme),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class RuhhProfileAvatar extends StatelessWidget {
  const RuhhProfileAvatar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Material(
      color: t.surfaceSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusChip),
        side: BorderSide(color: PortfolioPalette.borderHighlight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusChip),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.person_outline, color: t.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class RuhhModuleTabStrip extends StatelessWidget {
  const RuhhModuleTabStrip({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: RuhhSegmentedChips(
        labels: labels,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
      ),
    );
  }
}
