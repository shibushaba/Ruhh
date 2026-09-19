import 'package:flutter/material.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

class NBButton extends StatelessWidget {
  const NBButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.expand = true,
    this.icon,
    this.primary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool expand;
  final IconData? icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      Widget button = RuhhPrimaryButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        expand: expand,
      );
      if (color != null) {
        button = Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: color),
          ),
          child: button,
        );
      }
      return button;
    }
    return RuhhSecondaryButton(
      label: label,
      onPressed: onPressed,
      expand: expand,
    );
  }
}
