import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';

/// Standard module page chrome.
class NBModuleScaffold extends StatelessWidget {
  const NBModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.wrapBody = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool wrapBody;

  @override
  Widget build(BuildContext context) {
    final canvas = NBColors.canvas(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        bottom: bottom,
      ),
      body: wrapBody ? NBPageBody(child: body) : body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: NBColors.surfaceFill(Theme.of(context).brightness),
                border: Border(
                  top: BorderSide(
                    color: NBColors.glassBorder(Theme.of(context).brightness),
                    width: NBMetrics.borderWidth,
                  ),
                ),
              ),
              child: bottomNavigationBar,
            ),
    );
  }
}

class NBStatusChip extends StatelessWidget {
  const NBStatusChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: fg, width: 2),
        borderRadius: BorderRadius.circular(NBMetrics.radius),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
