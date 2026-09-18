import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

class NBTextField extends StatelessWidget {
  const NBTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.suffix,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class NBChip extends StatelessWidget {
  const NBChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = NBColors.prayer,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: NBColors.black, width: NBMetrics.borderWidth),
          borderRadius: BorderRadius.circular(NBMetrics.radius),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: NBColors.shadow,
                    offset: NBMetrics.shadowOffset,
                  ),
                ]
              : null,
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

class NBProgressBar extends StatelessWidget {
  const NBProgressBar({
    super.key,
    required this.progress,
    this.color = NBColors.budget,
  });

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Container(
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: NBColors.black, width: NBMetrics.borderWidth),
        borderRadius: BorderRadius.circular(NBMetrics.radius),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(NBMetrics.radius - 1),
            ),
          ),
        ),
      ),
    );
  }
}
