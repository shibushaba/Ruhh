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

String movieCategoryEmoji(MovieCategoryLocal cat) {
  final e = cat.emoji.trim();
  if (e.isNotEmpty) return e;
  return movieCategoryEmojiForName(cat.name);
}

/// Emoji-only movie category chips (horizontal row).
class MovieCategoryEmojiChipRow extends StatelessWidget {
  const MovieCategoryEmojiChipRow({
    super.key,
    required this.categories,
    required this.selectedRemoteId,
    required this.onSelected,
  });

  final List<MovieCategoryLocal> categories;
  final String? selectedRemoteId;
  final ValueChanged<MovieCategoryLocal> onSelected;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final selected = selectedRemoteId == cat.remoteId;
          final accent = movieCategoryAccent(cat);
          return Tooltip(
            message: cat.name,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(cat),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.85)
                        : movieCategoryFill(accent, alpha: 0.2),
                    border: Border.all(
                      color: selected ? accent : fg.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    movieCategoryEmoji(cat),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
