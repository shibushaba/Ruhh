import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

/// Flat neo-brutal panel: solid fill + crisp border (readable on all screens).
class NBGlassPanel extends StatelessWidget {
  const NBGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.expand = false,
    this.color,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final bool expand;
  final Color? color;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final radius = borderRadius ?? BorderRadius.circular(NBMetrics.radius);
    final borderColor = NBColors.glassBorder(brightness);
    final fill = color ?? NBColors.surfaceFill(brightness);

    Widget panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: NBMetrics.borderWidth),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: NBColors.shadow,
                  offset: NBMetrics.shadowOffset,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (!expand) return panel;
    return SizedBox(width: double.infinity, child: panel);
  }
}

/// App-wide canvas (single gradient layer from [MaterialApp.builder]).
class NBGlassBackground extends StatelessWidget {
  const NBGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ColoredBox(
      color: NBColors.canvas(brightness),
      child: child,
    );
  }
}
