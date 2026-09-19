import 'package:flutter/material.dart';
import 'package:ruhh/core/widgets/ruhh_color_picker.dart';
import 'package:ruhh/core/widgets/ruhh_preset_colors.dart';

export 'package:ruhh/core/widgets/ruhh_preset_colors.dart'
    show defaultNewCategoryColorValue, kCategoryColorChoices;

class CategoryColorPicker extends StatelessWidget {
  const CategoryColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return RuhhColorPicker(
      selectedArgb: selected,
      onSelected: onSelected,
      inCard: true,
    );
  }
}
