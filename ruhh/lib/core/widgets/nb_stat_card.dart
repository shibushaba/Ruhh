import 'package:flutter/material.dart';
import 'package:ruhh/core/motion/animated_progress_bar.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

class NBStatCard extends StatelessWidget {
  const NBStatCard({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.progress,
    this.subtitle,
    this.targetLabel,
    this.prominentLabel = false,
  });

  final String label;
  final String value;
  final Color? accent;
  final double? progress;
  final String? subtitle;
  final String? targetLabel;
  final bool prominentLabel;

  @override
  Widget build(BuildContext context) {
    if (!prominentLabel) {
      return RuhhStatProgressCard(
        label: label,
        value: value,
        targetLabel: targetLabel,
        subtitle: subtitle,
        progress: progress ?? 0,
        accent: accent,
        compact: true,
      );
    }

    final t = context.ruhh;
    final barColor = accent ?? t.accentMint;
    final theme = Theme.of(context).textTheme;

    return RuhhSoftCard(
      radius: t.radiusCardMedium,
      padding: EdgeInsets.all(t.spaceCardPaddingCompact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: t.cardTitle(theme).copyWith(
                  fontSize: 14,
                  color: t.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: t.statLarge(theme),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (targetLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  targetLabel!,
                  style: t.statMedium(theme).copyWith(color: barColor),
                ),
              ],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: t.caption(theme).copyWith(color: t.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          AnimatedProgressBar(
            progress: (progress ?? 0).clamp(0, 1),
            color: barColor,
          ),
        ],
      ),
    );
  }
}
