import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App-wide push: fade + 4% scale up, 280ms easeOutCubic.
class RuhhFadeScalePage<T> extends CustomTransitionPage<T> {
  RuhhFadeScalePage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
}

Page<T> ruhhPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return RuhhFadeScalePage<T>(
    key: state.pageKey,
    child: child,
  );
}
