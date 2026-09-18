import 'package:flutter/material.dart';
import 'package:neubrutalism_ui/neubrutalism_ui.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

class NBButton extends StatelessWidget {
  const NBButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = NBColors.prayer,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return SizedBox(
      width: expand ? double.infinity : null,
      child: NeuTextButton(
        enableAnimation: onPressed != null,
        onPressed: onPressed,
        buttonColor: color,
        borderColor: NBColors.black,
        shadowColor: NBColors.shadow,
        borderWidth: NBMetrics.borderWidth,
        offset: NBMetrics.shadowOffset,
        borderRadius: BorderRadius.circular(NBMetrics.radius),
        buttonHeight: 52,
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
                        child: Icon(icon, size: 18, color: NBColors.black),
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
