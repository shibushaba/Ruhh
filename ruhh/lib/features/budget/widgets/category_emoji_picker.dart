import 'package:flutter/material.dart';
import 'package:ruhh/core/widgets/ruhh_emoji_picker.dart';

const kCategoryEmojiChoices = <String>[
  '🍔', '🍕', '🍜', '🍱', '🥗', '🍦', '☕', '🧃', '🍺',
  '🛒', '🛍️', '💳', '📦', '🚌', '🚗', '🛵', '✈️', '🚆',
  '🏠', '🏢', '📄', '💡', '🔌', '🏥', '💊', '🩺', '🧴',
  '🎬', '🎮', '🎵', '🎨', '⚽', '🏋️', '🧘', '🎁', '🎉',
  '📚', '💼', '💰', '📈', '📊', '🏷️', '👕', '💅', '✂️',
  '🐾', '🐕', '🌸', '🌿', '🔧', '💻', '📱', '☎️', '🎯',
  '🔔', '🔑', '🌍', '❤️', '⭐', '🧸', '🍳', '🧹', '🎓',
];

class CategoryEmojiPicker extends StatelessWidget {
  const CategoryEmojiPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return RuhhEmojiPicker(
      selected: selected,
      onSelected: onSelected,
      inCard: true,
    );
  }
}
