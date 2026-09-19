import 'package:flutter/material.dart';

/// B.1 / B.2 tap scale feedback.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.pressedScale = 0.96,
    this.gentle = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double pressedScale;
  final bool gentle;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _c, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() {
    if (!widget.enabled || widget.onTap == null) return;
    _c.duration = const Duration(milliseconds: 100);
    _c.forward();
  }

  void _up() {
    if (!widget.enabled) return;
    _c.duration = const Duration(milliseconds: 220);
    _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.gentle ? 0.98 : widget.pressedScale;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _down(),
      onTapUp: (_) {
        _up();
        if (widget.enabled) widget.onTap?.call();
      },
      onTapCancel: _up,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final s = widget.enabled
              ? 1 - (_c.value * (1 - scale))
              : 1.0;
          return Transform.scale(scale: s, child: child);
        },
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.4,
          child: widget.child,
        ),
      ),
    );
  }
}
