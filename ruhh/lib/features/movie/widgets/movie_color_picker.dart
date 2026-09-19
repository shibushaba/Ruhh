import 'package:flutter/material.dart';
import 'package:ruhh/core/widgets/ruhh_color_picker.dart';

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
    return RuhhColorPicker(
      selectedArgb: selected.toARGB32(),
      onSelected: (v) => onSelected(Color(v)),
      inCard: true,
    );
  }
}
