import 'package:flutter/material.dart';
import 'package:ruhh/core/motion/animated_count_up.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

/// B.5 radial dial with arc sweep + center count-up.
class AnimatedRadialDial extends StatefulWidget {
  const AnimatedRadialDial({
    super.key,
    required this.label,
    required this.progress,
    this.displayValue,
    this.percentLabel,
    this.accent,
    this.size = 120,
  });

  final String label;
  final double progress;
  final double? displayValue;
  final String? percentLabel;
  final Color? accent;
  final double size;

  @override
  State<AnimatedRadialDial> createState() => _AnimatedRadialDialState();
}

class _AnimatedRadialDialState extends State<AnimatedRadialDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedRadialDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _c.forward(from: 0);
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
    final color = widget.accent ?? t.accentLavender;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: widget.progress.clamp(0, 1) * _anim.value,
                  strokeWidth: 8,
                  backgroundColor: t.pastelForAccent(color),
                  color: color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.displayValue != null)
                    AnimatedCountUp(
                      value: widget.displayValue! * _anim.value,
                      style: t.statMedium(Theme.of(context).textTheme),
                      formatter: (_) => widget.percentLabel ??
                          '${(widget.progress * 100).round()}%',
                    )
                  else
                    Text(
                      widget.percentLabel ?? '${(widget.progress * 100).round()}%',
                      style: t.statMedium(Theme.of(context).textTheme),
                    ),
                  Text(
                    widget.label,
                    style: t.caption(Theme.of(context).textTheme),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
