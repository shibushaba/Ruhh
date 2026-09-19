import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/movie/tracker/movie_defaults.dart';

class MovieColorPalettePicker extends StatelessWidget {
  const MovieColorPalettePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in movieCategoryPalette)
          GestureDetector(
            onTap: () => onSelected(c),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c,
                border: Border.all(
                  color: selected == c ? NBColors.black : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}