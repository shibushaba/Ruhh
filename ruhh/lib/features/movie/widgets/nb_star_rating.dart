import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

class NBStarRating extends StatelessWidget {
  const NBStarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 28,
    this.readOnly = false,
    this.accent = const Color(0xFFF59E0B),
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;
  final bool readOnly;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final stars = List.generate(5, (i) {
      final star = i + 1;
      final filled = star <= value.clamp(1, 5);
      return GestureDetector(
        onTap: readOnly || onChanged == null ? null : () => onChanged!(star),
        child: Icon(
          filled ? Icons.star : Icons.star_border,
          size: size,
          color: filled ? accent : RuhhTokens.light.textTertiary,
        ),
      );
    });
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
