import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';

class NBTile extends StatelessWidget {
  const NBTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final fg = Theme.of(context).colorScheme.onSurface;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: NBCard(
        onTap: disabled ? null : onTap,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: disabled ? NBColors.mutedText(Theme.of(context).brightness) : accent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(NBMetrics.radius - 1),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: fg, width: 2),
                          borderRadius: BorderRadius.circular(NBMetrics.radius),
                        ),
                        child: Icon(icon, size: 26, color: fg),
                      ),
                      const Spacer(),
                      Text(title, style: theme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
