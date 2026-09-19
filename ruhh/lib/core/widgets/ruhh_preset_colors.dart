import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/habit/tracker/habit_appearance.dart';
import 'package:ruhh/features/movie/tracker/movie_defaults.dart';

/// Distinct accents for budget categories, charts, and trends.
const kCategoryColorChoices = <Color>[
  Color(0xFFE65100),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFFAD1457),
  Color(0xFF7C3AED),
  Color(0xFF4527A0),
  Color(0xFF1565C0),
  Color(0xFF0EA5E9),
  Color(0xFF00838F),
  Color(0xFF059669),
  Color(0xFF22C55E),
  Color(0xFF84CC16),
  Color(0xFFF59E0B),
  Color(0xFFEF6C00),
  Color(0xFF6A1B9A),
  Color(0xFF546E7A),
  Color(0xFF78716C),
  Color(0xFF000000),
];

int defaultNewCategoryColorValue({required bool isIncome}) {
  return (isIncome ? NBMetrics.incomeGreen : kCategoryColorChoices.first)
      .toARGB32();
}

/// All preset swatches used across budget, habit, and movie pickers.
List<Color> ruhhAllPresetColors() {
  final seen = <int>{};
  final out = <Color>[];
  void add(Color c) {
    final v = c.toARGB32();
    if (seen.add(v)) out.add(c);
  }

  for (final c in kCategoryColorChoices) {
    add(c);
  }
  for (final c in kHabitColorChoices) {
    add(c);
  }
  for (final c in movieCategoryPalette) {
    add(c);
  }
  for (final c in defaultMovieCategoryColors) {
    add(c);
  }
  return out;
}

Color ruhhCheckOnColor(Color fill) {
  return fill.computeLuminance() > 0.45 ? Colors.black : Colors.white;
}
