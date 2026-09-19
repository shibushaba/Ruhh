import 'package:flutter/material.dart';

/// Legacy NB* names — portfolio-aligned surfaces.
abstract final class NBColors {
  static const black = Color(0xFF0A0A0A);
  static const white = Color(0xFFF5F5F5);
  static const shadow = Color(0x80000000);
  static const offWhite = white;

  static const budget = Color(0xFF38BDF8);
  static const habit = Color(0xFF4ADE80);
  static const prayer = Color(0xFFA78BFA);
  static const movie = Color(0xFFFB7185);

  static Color canvas(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF050505)
          : const Color(0xFFEBEBEB);

  static Color glassFill(Brightness brightness) => surfaceFill(brightness);

  static Color surfaceFill(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF0A0A0A) : white;

  static Color mutedText(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFFAAAAAA)
          : const Color(0xFF666666);

  static Color moduleAccent(Color moduleTint) => moduleTint;

  static Color glassBorder(Brightness brightness) =>
      brightness == Brightness.dark ? white : black;

  static Color glassHighlight(Brightness brightness) => Colors.transparent;
}

abstract final class NBMetrics {
  static const borderWidth = 1.0;
  static const radius = 0.0;

  static const incomeGreen = Color(0xFF22C55E);
  static const expenseRed = Color(0xFFEF4444);
  static const warningAmber = Color(0xFFF59E0B);
  static const shadowOffset = Offset.zero;
}
