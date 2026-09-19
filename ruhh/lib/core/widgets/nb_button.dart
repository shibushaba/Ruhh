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
    if (primary && color == null) {
      return RuhhPrimaryButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        expand: expand,
      );
    }
    return RuhhSecondaryButton(
      label: label,
      onPressed: onPressed,
      expand: expand,
    );
  }
}
