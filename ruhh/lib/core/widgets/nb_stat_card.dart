import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

class NBStatCard extends StatelessWidget {
  const NBStatCard({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.progress,
  });

  final String label;
  final String value;
  final Color? accent;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return RuhhStatProgressCard(
      label: label,
      value: value,
      progress: progress ?? 0,
      accent: accent,
      compact: true,
    );
  }
}
