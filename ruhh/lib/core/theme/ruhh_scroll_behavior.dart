import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Scrollable content without visible scrollbars (wheel, drag, and touch still work).
class RuhhScrollBehavior extends MaterialScrollBehavior {
  const RuhhScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}

const kRuhhScrollbarTheme = ScrollbarThemeData(
  thumbVisibility: WidgetStatePropertyAll(false),
  trackVisibility: WidgetStatePropertyAll(false),
  thickness: WidgetStatePropertyAll(0),
  crossAxisMargin: 0,
  mainAxisMargin: 0,
);
