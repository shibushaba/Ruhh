import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

/// Bottom scroll inset for tab bodies under [NBModuleScaffold] (`wrapBody: false`).
class RuhhShellScrollInsets extends InheritedWidget {
  const RuhhShellScrollInsets({
    super.key,
    required this.bottom,
    required super.child,
  });

  final double bottom;

  static RuhhShellScrollInsets? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RuhhShellScrollInsets>();
  }

  @override
  bool updateShouldNotify(RuhhShellScrollInsets oldWidget) {
    return oldWidget.bottom != bottom;
  }
}

double ruhhEffectiveScrollBottomInset(BuildContext context) {
  return ruhhScrollBottomInset(
    context,
    shellInset: RuhhShellScrollInsets.maybeOf(context)?.bottom,
  );
}

EdgeInsets ruhhListPadding(
  BuildContext context, {
  EdgeInsets base = EdgeInsets.zero,
}) {
  return base.copyWith(
    bottom: base.bottom + ruhhEffectiveScrollBottomInset(context),
  );
}

/// Footer spacer so the last row clears the floating nav (and module FAB when present).
class RuhhNavClearance extends StatelessWidget {
  const RuhhNavClearance({super.key, this.extra = 0});

  final double extra;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ruhhEffectiveScrollBottomInset(context) + extra,
    );
  }
}

/// Adds bottom scroll inset for [RefreshIndicator] → scrollable chains.
Widget ruhhApplyScrollBottomInset({
  required BuildContext context,
  required Widget child,
  required double bottomInset,
}) {
  if (bottomInset <= 0) return child;

  if (child is RefreshIndicator) {
    final ri = child;
    return RefreshIndicator(
      key: ri.key,
      color: ri.color,
      backgroundColor: ri.backgroundColor,
      onRefresh: ri.onRefresh,
      notificationPredicate: ri.notificationPredicate,
      displacement: ri.displacement,
      edgeOffset: ri.edgeOffset,
      semanticsLabel: ri.semanticsLabel,
      semanticsValue: ri.semanticsValue,
      strokeWidth: ri.strokeWidth,
      triggerMode: ri.triggerMode,
      child: ruhhApplyScrollBottomInset(
        context: context,
        child: ri.child,
        bottomInset: bottomInset,
      ),
    );
  }

  return child;
}
