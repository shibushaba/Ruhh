import 'package:flutter/material.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/features/budget/widgets/category_color_picker.dart';

/// Default emoji when [CategoryLocal.emoji] is empty (seed names + fallbacks).
String defaultCategoryEmoji(String name) {
  switch (name.trim().toLowerCase()) {
    case 'food':
      return '🍔';
    case 'medical':
      return '🏥';
    case 'transport':
      return '🚌';
    case 'rent':
      return '🏠';
    case 'utilities':
    case 'bills':
      return '💡';
    case 'fun':
    case 'entertainment':
      return '🎬';
    case 'shopping':
      return '🛍️';
    case 'education':
      return '📚';
    case 'salary':
    case 'income':
      return '💰';
    case 'investment':
      return '📈';
    case 'gifts':
      return '🎁';
    default:
      return '🏷️';
  }
}

String categoryEmoji(CategoryLocal cat) {
  final e = cat.emoji.trim();
  if (e.isNotEmpty) return e;
  return defaultCategoryEmoji(cat.name);
}

String categoryChipLabel(CategoryLocal cat) => '${categoryEmoji(cat)} ${cat.name}';

/// Accent for trends, progress bars, and list leading rings.
Color categoryAccentColor(CategoryLocal cat) {
  final stored = Color(cat.colorValue);
  if (cat.colorValue == NBColors.budget.toARGB32()) {
    return cat.isIncome ? NBMetrics.incomeGreen : kCategoryColorChoices.first;
  }
  return stored;
}

Color categoryAccentColorOrFallback(CategoryLocal? cat, int index) {
  if (cat != null) return categoryAccentColor(cat);
  return kCategoryColorChoices[index % kCategoryColorChoices.length];
}

Widget categoryLeadingAvatar(
  BuildContext context,
  CategoryLocal cat, {
  double radius = 18,
}) {
  final t = Theme.of(context).extension<RuhhTokens>()!;
  final emoji = categoryEmoji(cat);
  final accent = categoryAccentColor(cat);
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: accent, width: 2),
    ),
    child: CircleAvatar(
      radius: radius,
      backgroundColor: t.surfaceSecondary,
      child: Text(emoji, style: TextStyle(fontSize: radius * 0.95)),
    ),
  );
}

/// Emoji-only category chips in one horizontally scrollable row.
class CategoryEmojiChipRow extends StatelessWidget {
  const CategoryEmojiChipRow({
    super.key,
    required this.categories,
    required this.selectedRemoteId,
    required this.onSelected,
  });

  final List<CategoryLocal> categories;
  final String? selectedRemoteId;
  final ValueChanged<CategoryLocal> onSelected;

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
          final accent = categoryAccentColor(cat);
          return Tooltip(
            message: cat.name,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(cat),
                borderRadius: BorderRadius.circular(NBMetrics.radius),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.85)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected ? accent : fg,
                      width: NBMetrics.borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(NBMetrics.radius),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: NBColors.shadow,
                              offset: NBMetrics.shadowOffset,
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    categoryEmoji(cat),
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
