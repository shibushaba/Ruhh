import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

/// B.9 confetti burst wrapper.
class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({
    super.key,
    required this.trigger,
    required this.child,
    this.align = Alignment.topCenter,
  });

  final int? trigger;
  final Widget child;
  final Alignment align;

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst> {
  late ConfettiController _controller;
  int? _last;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(milliseconds: 800));
  }

  @override
  void didUpdateWidget(covariant CelebrationBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != _last) {
      _last = widget.trigger;
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Align(
          alignment: widget.align,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 18,
            minBlastForce: 8,
            emissionFrequency: 0.04,
            numberOfParticles: 16,
            gravity: 0.12,
            colors: [
              t.accentMint,
              t.accentAmber,
              t.accentSky,
              t.accentLavender,
            ],
          ),
        ),
      ],
    );
  }
}
