import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
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
    final t = context.ruhh;
    final choices = [
      if (!kHabitColorChoices.any((c) => c.toARGB32() == selected)) Color(selected),
      ...kHabitColorChoices,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices.map((color) {
        final value = color.toARGB32();
        final on = selected == value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(value),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: on ? t.textPrimary : t.divider,
                  width: on ? 2.5 : 1,
                ),
              ),
              child: on
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: habitColorCheckIcon(color),
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final accent = Color(accentArgb);
    final options = [
      if (kHabitIconOptions.every((e) => e.$1 != selected))
        (selected, habitIconData(selected)),
      ...kHabitIconOptions,
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((e) {
        final on = selected == e.$1;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(e.$1),
            borderRadius: BorderRadius.circular(t.radiusChip + 4),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(t.radiusChip + 4),
                color: on
                    ? accent.withValues(alpha: 0.45)
                    : t.surfaceSecondary.withValues(alpha: 0.55),
                border: on
                    ? Border.all(color: accent, width: 2)
                    : Border.all(color: t.divider, width: 1),
              ),
              child: Icon(
                e.$2,
                size: 22,
                color: on ? habitColorCheckIcon(accent) : t.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
