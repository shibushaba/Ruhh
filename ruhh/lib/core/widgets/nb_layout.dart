import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

/// Shared page spacing and section structure.
abstract final class NBLayout {
  static const pagePadding = EdgeInsets.fromLTRB(20, 8, 20, 24);
  static const sectionGap = 24.0;
  static const itemGap = 12.0;
  static const maxContentWidth = 720.0;
}

/// Constrains and pads scrollable module content.
class NBPageBody extends StatelessWidget {
  const NBPageBody({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: NBLayout.maxContentWidth),
          child: Padding(
            padding: padding ?? NBLayout.pagePadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class NBSection extends StatelessWidget {
  const NBSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: theme.bodyMedium),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class NBStreakBadge extends StatelessWidget {
  const NBStreakBadge({super.key, required this.value, this.onTap});

  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: NBColors.black, width: 2),
        borderRadius: BorderRadius.circular(NBMetrics.radius),
      ),
      child: Text(
        'Streak $value',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
    if (onTap == null) return chip;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(NBMetrics.radius), child: chip);
  }
}
