import 'package:flutter/material.dart';
import 'package:ruhh/core/data/models/movie_category_local.dart';
import 'package:ruhh/features/movie/tracker/movie_defaults.dart';

Color movieCategoryAccent(MovieCategoryLocal? category) {
  if (category == null) {
    return defaultMovieCategoryColors.last;
  }
  final stored = Color(category.colorValue);
  if (category.isCustom) return stored;
  return movieCategoryColorForName(category.name);
}

Color movieCategoryFill(Color accent, {double alpha = 0.14}) =>
    accent.withValues(alpha: alpha);

Color movieCategoryOnAccent(Color accent) =>
    accent.computeLuminance() > 0.55 ? Colors.black : Colors.white;
