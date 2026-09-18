import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

/// Standard module page chrome: bold title + optional actions.
class NBModuleScaffold extends StatelessWidget {
  const NBModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title.toUpperCase()),
        actions: actions,
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class NBStatusChip extends StatelessWidget {
  const NBStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.selected = false,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: NBColors.black, width: NBMetrics.borderWidth),
          boxShadow: selected
              ? const [BoxShadow(color: NBColors.shadow, offset: NBMetrics.shadowOffset)]
              : null,
        ),
        child: Text(label, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
