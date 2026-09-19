import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

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
    final t = context.ruhh;
    final choices = [
      if (selected.isNotEmpty && !kCategoryEmojiChoices.contains(selected))
        selected,
      ...kCategoryEmojiChoices,
    ];
    return RuhhSoftCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: choices.map((emoji) {
          final on = selected == emoji;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(emoji),
              borderRadius: BorderRadius.circular(t.radiusChip),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(t.radiusChip),
                  color: on
                      ? t.accentMintPastel
                      : t.surfaceSecondary.withValues(alpha: 0.5),
                  border: on
                      ? Border.all(color: t.accentMint, width: 2)
                      : null,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
