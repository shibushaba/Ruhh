import 'package:flutter/material.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

/// B.6 custom animated checkbox (mint fill + check path draw).
class AnimatedAppCheckbox extends StatefulWidget {
  const AnimatedAppCheckbox({
    super.key,
    required this.checked,
    this.size = 22,
  });

  final bool checked;
  final double size;

  @override
  State<AnimatedAppCheckbox> createState() => _AnimatedAppCheckboxState();
}

class _AnimatedAppCheckboxState extends State<AnimatedAppCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.checked ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedAppCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked) {
      _c.forward();
    } else {
      _c.reverse();
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _CheckPainter(
            progress: Curves.easeOutBack.transform(_c.value),
            checkProgress: (_c.value * 1.2).clamp(0, 1),
            mint: t.accentMint,
            border: t.divider,
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.progress,
    required this.checkProgress,
    required this.mint,
    required this.border,
  });

  final double progress;
  final double checkProgress;
  final Color mint;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(6),
    );
    if (progress > 0) {
      canvas.drawRRect(
        r,
        Paint()..color = Color.lerp(Colors.transparent, mint, progress)!,
      );
    }
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.lerp(border, mint, progress)!,
    );
    if (checkProgress > 0) {
      final path = Path()
        ..moveTo(size.width * 0.22, size.height * 0.52)
        ..lineTo(size.width * 0.42, size.height * 0.72)
        ..lineTo(size.width * 0.78, size.height * 0.28);
      final metric = path.computeMetrics().first;
      final len = metric.length * checkProgress;
      canvas.drawPath(
        metric.extractPath(0, len),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.checkProgress != checkProgress;
}

/// B.6 animated radio dot.
class AnimatedAppRadio extends StatelessWidget {
  const AnimatedAppRadio({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? t.accentMint : t.textTertiary,
                width: 2,
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            builder: (context, v, _) {
              return Transform.scale(
                scale: v,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: t.accentMint,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// B.6 check circle for prayer/habit rows.
class AnimatedAppCheckCircle extends StatelessWidget {
  const AnimatedAppCheckCircle({
    super.key,
    required this.checked,
    this.activeColor,
  });

  final bool checked;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: checked ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, v, _) {
        if (v < 0.05) {
          final ring = activeColor ?? t.divider;
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 2),
            ),
          );
        }
        return Transform.scale(
          scale: v,
          child: Icon(
            AppIcons.checkCircle(filled: true),
            color: activeColor ?? t.accentMint,
            size: 28,
          ),
        );
      },
    );
  }
}
