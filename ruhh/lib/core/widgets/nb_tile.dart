import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

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
    final t = context.ruhh;
    final color = disabled ? t.textTertiary : accent;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: RuhhSoftCard(
        radius: t.radiusCardMedium,
        onTap: disabled ? null : onTap,
        padding: EdgeInsets.all(t.spaceCardPaddingCompact),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RuhhIconChip(icon: icon, accent: color),
            const Spacer(),
            Text(
              title,
              style: t.cardTitle(Theme.of(context).textTheme),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: t.caption(Theme.of(context).textTheme),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
