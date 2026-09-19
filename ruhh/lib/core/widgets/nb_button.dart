import 'package:flutter/material.dart';
import 'package:neubrutalism_ui/neubrutalism_ui.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

class NBButton extends StatelessWidget {
  const NBButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = color ?? (isDark ? NBColors.white : NBColors.black);
    final onFill = isDark ? NBColors.black : NBColors.white;
    final border = NBColors.glassBorder(Theme.of(context).brightness);
    final labelStyle =
        Theme.of(context).textTheme.labelLarge?.copyWith(color: onFill);

    return SizedBox(
      width: expand ? double.infinity : null,
      child: NeuTextButton(
        enableAnimation: onPressed != null,
        onPressed: onPressed,
        buttonColor: fill,
        borderColor: border,
        shadowColor: NBColors.shadow,
        borderWidth: NBMetrics.borderWidth,
        offset: NBMetrics.shadowOffset,
        borderRadius: BorderRadius.circular(NBMetrics.radius),
        buttonHeight: 48,
        buttonWidth: expand ? double.infinity : 160,
        text: icon == null
            ? Text(label, style: labelStyle)
            : Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(icon, size: 18, color: onFill),
                      ),
                    ),
                    TextSpan(text: label, style: labelStyle),
                  ],
                ),
              ),
      ),
    );
  }
}
