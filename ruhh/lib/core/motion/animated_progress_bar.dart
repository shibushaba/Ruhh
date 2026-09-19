import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

/// B.3 animated horizontal progress.
class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 6,
    this.onCrossedFull,
  });

  final double progress;
  final Color? color;
  final double height;
  final VoidCallback? onCrossedFull;

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;
  double _prev = 0;
  var _pulsed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _prev = oldWidget.progress;
    _c.forward(from: 0);
    if (widget.progress >= 1 &&
        _prev < 1 &&
        !_pulsed &&
        widget.onCrossedFull != null) {
      _pulsed = true;
      widget.onCrossedFull!();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final color = widget.color ?? t.textPrimary;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final from = _prev.clamp(0.0, 1.0);
        final to = widget.progress.clamp(0.0, 1.0);
        final v = from + (to - from) * _anim.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(t.radiusButton),
          child: LinearProgressIndicator(
            value: v,
            minHeight: widget.height,
            backgroundColor: t.divider,
            color: color,
          ),
        );
      },
    );
  }
}
