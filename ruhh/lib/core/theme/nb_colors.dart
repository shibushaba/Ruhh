import 'package:flutter/material.dart';

/// Monochrome neo-brutal palette — high contrast for legibility.
abstract final class NBColors {
  static const black = Color(0xFF0A0A0A);
  static const shadow = Color(0xFF0A0A0A);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFE8E8E8);
  static const darkBg = Color(0xFF0F0F0F);
  static const darkSurface = Color(0xFF1C1C1C);

  static const budget = Color(0xFFE0E0E0);
  static const habit = Color(0xFFCFCFCF);
  static const prayer = Color(0xFFB8B8B8);
  static const movie = Color(0xFF9E9E9E);

  static Color canvas(Brightness brightness) =>
      brightness == Brightness.dark ? darkBg : offWhite;

  static Color glassFill(Brightness brightness) => surfaceFill(brightness);

  static Color surfaceFill(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : white;

  static Color mutedText(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFFB0B0B0)
          : const Color(0xFF404040);

  static Color moduleAccent(Color moduleTint) => moduleTint;

  static Color glassBorder(Brightness brightness) =>
      brightness == Brightness.dark ? white : black;

  static Color glassHighlight(Brightness brightness) => Colors.transparent;
}

abstract final class NBMetrics {
  static const borderWidth = 2.0;
  static const radius = 8.0;
  static const shadowOffset = Offset(3, 3);
}
