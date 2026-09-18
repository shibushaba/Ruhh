import 'package:flutter/material.dart';
import 'package:neubrutalism_ui/neubrutalism_ui.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

class NBCard extends StatelessWidget {
  const NBCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = NeuCard(
      cardColor: color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      cardBorderColor: NBColors.black,
      cardBorderWidth: NBMetrics.borderWidth,
      shadowColor: NBColors.shadow,
      offset: NBMetrics.shadowOffset,
      borderRadius: BorderRadius.circular(NBMetrics.radius),
      paddingData: padding,
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}
