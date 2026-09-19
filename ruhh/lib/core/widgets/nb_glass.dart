import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/portfolio_palette.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

/// Desk grid + paper panels — matches shabas.vercel.app scrapbook layout.
class NBGlassBackground extends StatelessWidget {
  const NBGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor =
        isDark ? PortfolioPalette.gridLineDark : PortfolioPalette.gridLineLight;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? PortfolioPalette.deskDark : PortfolioPalette.deskLight,
            gradient: isDark ? PortfolioPalette.deskGradientDark : null,
          ),
        ),
        if (isDark)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: PortfolioPalette.deskGradientAccentDark,
            ),
          ),
        CustomPaint(
          painter: PortfolioGridPainter(lineColor: gridColor),
        ),
        child,
      ],
    );
  }
}

BoxDecoration glassDecoration(
  BuildContext context, {
  BorderRadius? borderRadius,
  Color? tint,
  bool elevated = true,
}) {
  return vectorPanelDecoration(
    context,
    borderRadius: borderRadius,
    tint: tint,
    elevated: elevated,
  );
}

BoxDecoration vectorPanelDecoration(
  BuildContext context, {
  BorderRadius? borderRadius,
  Color? tint,
  bool elevated = true,
}) {
  final t = context.ruhh;
  final radius = borderRadius ?? BorderRadius.circular(t.radiusCardLarge);
  return BoxDecoration(
    color: tint ?? t.surfacePrimary,
    borderRadius: radius,
    border: Border.all(color: PortfolioPalette.borderHighlight, width: 1),
    boxShadow: elevated && t.shadowCard.isNotEmpty ? t.shadowCard : null,
  );
}

class NBGlassSurface extends StatelessWidget {
  const NBGlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.expand = false,
    this.accent,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final bool expand;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final radius = borderRadius ?? BorderRadius.circular(t.radiusCardMedium);
    Widget panel = DecoratedBox(
      decoration: vectorPanelDecoration(
        context,
        borderRadius: radius,
        tint: accent ?? t.surfacePrimary,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (!expand) return panel;
    return SizedBox(width: double.infinity, height: double.infinity, child: panel);
  }
}

class NBGlassPanel extends StatelessWidget {
  const NBGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.expand = false,
    this.color,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final bool expand;
  final Color? color;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final radius = borderRadius ?? BorderRadius.circular(t.radiusCardLarge);
    Widget panel = DecoratedBox(
      decoration: vectorPanelDecoration(
        context,
        borderRadius: radius,
        tint: color ?? t.surfacePrimary,
        elevated: elevated,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (!expand) return panel;
    return SizedBox(width: double.infinity, child: panel);
  }
}
