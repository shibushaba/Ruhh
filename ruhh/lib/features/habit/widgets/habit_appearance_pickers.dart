import 'package:flutter/material.dart';
import 'package:ruhh/core/widgets/ruhh_color_picker.dart';
import 'package:ruhh/core/widgets/ruhh_emoji_picker.dart';
import 'package:ruhh/features/habit/tracker/habit_appearance.dart';

class HabitColorPicker extends StatelessWidget {
  const HabitColorPicker({
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
      inCard: false,
    );
  }
}

class HabitIconPicker extends StatelessWidget {
  const HabitIconPicker({
    super.key,
    required this.selected,
    required this.accentArgb,
    required this.onSelected,
  });

  final String selected;
  final int accentArgb;
  final ValueChanged<String> onSelected;

  String get _emojiSelected {
    if (habitIconIsEmoji(selected)) return selected;
    return habitLegacyIconToEmoji(selected);
  }

  @override
  Widget build(BuildContext context) {
    return RuhhEmojiPicker(
      selected: _emojiSelected,
      onSelected: onSelected,
      inCard: false,
      accent: Color(accentArgb),
    );
  }
}
