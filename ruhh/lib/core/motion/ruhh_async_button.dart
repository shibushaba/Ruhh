import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/motion/pressable_scale.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

/// B.1 / B.7 primary button with loading + success flash.
class RuhhAsyncPrimaryButton extends StatefulWidget {
  const RuhhAsyncPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.icon,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final bool expand;
  final IconData? icon;

  @override
  State<RuhhAsyncPrimaryButton> createState() =>
      _RuhhAsyncPrimaryButtonState();
}

class _RuhhAsyncPrimaryButtonState extends State<RuhhAsyncPrimaryButton> {
  var _loading = false;
  var _success = false;

  Future<void> _run() async {
    if (_loading || widget.onPressed == null) return;
    setState(() => _loading = true);
    final started = DateTime.now();
    try {
      await widget.onPressed!();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _success = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    } finally {
      final elapsed = DateTime.now().difference(started);
      if (elapsed.inMilliseconds < 250 && mounted && _loading) {
        await Future<void>.delayed(
          Duration(milliseconds: 250 - elapsed.inMilliseconds),
        );
        if (mounted && _loading) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final enabled = widget.onPressed != null && !_loading;
    return PressableScale(
      enabled: enabled,
      onTap: _run,
      child: SizedBox(
        width: widget.expand ? double.infinity : null,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusButton),
            color: enabled ? t.accentMint : t.accentMint.withValues(alpha: 0.4),
            boxShadow: enabled ? t.shadowPrimaryButton : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: _loading || _success ? 0 : 1,
                duration: const Duration(milliseconds: 120),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize:
                      widget.expand ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              if (_success)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.elasticOut,
                  builder: (context, v, _) {
                    return Transform.scale(
                      scale: v,
                      child: Icon(AppIcons.check(filled: true),
                          color: Colors.white, size: 24),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
