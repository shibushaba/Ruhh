import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
class BudgetEmptyCard extends StatelessWidget {
  const BudgetEmptyCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return NBGlassPanel(
      padding: const EdgeInsets.all(16),
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class BudgetListRow extends StatelessWidget {
  const BudgetListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.accent,
    this.onTap,
    this.onEdit,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final Color? accent;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NBLayout.itemGap),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NBMetrics.radius + 4),
          child: NBGlassSurface(
            accent: accent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (onEdit != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact glass metric for the budget home 2×2 grid.
class BudgetMetricTile extends StatelessWidget {
  const BudgetMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.accent = NBColors.budget,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final String? detail;
  final Color accent;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NBMetrics.radius + 4),
        child: NBGlassSurface(
          expand: true,
          accent: accent,
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, size: 18, color: theme.bodyMedium?.color),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: theme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  detail!,
                  style: theme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetFormSection extends StatelessWidget {
  const BudgetFormSection({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: NBLayout.sectionGap),
      child: NBGlassPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class BudgetSectionHeader extends StatelessWidget {
  const BudgetSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
