import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

/// Distinct accents for charts, trends, and category chips.
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
    final t = context.ruhh;
    return RuhhSoftCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kCategoryColorChoices.map((color) {
          final value = color.toARGB32();
          final on = selected == value;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(value),
              borderRadius: BorderRadius.circular(t.radiusChip),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(t.radiusChip),
                  border: on
                      ? Border.all(color: t.textPrimary, width: 2.5)
                      : Border.all(color: t.divider, width: 1),
                ),
                child: on
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: _checkIconColor(color),
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static Color _checkIconColor(Color fill) {
    final lum = fill.computeLuminance();
    return lum > 0.45 ? Colors.black : Colors.white;
  }
}
