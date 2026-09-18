import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';

class NBTile extends StatelessWidget {
  const NBTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: NBCard(
        color: disabled ? Colors.grey.shade400 : color,
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: NBColors.black),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
