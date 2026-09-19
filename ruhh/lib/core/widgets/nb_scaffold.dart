import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/services/overlay_launch.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_fab_location.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

/// Standard module page chrome with soft header + optional module tabs.
class NBModuleScaffold extends ConsumerWidget {
  const NBModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.moduleTabLabels,
    this.moduleTabIndex,
    this.onModuleTab,
    this.floatingActionButton,
    this.showBackButton = false,
    this.wrapBody = true,
    @Deprecated('Unused') this.bottom,
    @Deprecated('Use moduleTabLabels') this.bottomNavigationBar,
    @Deprecated('Removed') this.glassBackground = false,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final List<String>? moduleTabLabels;
  final int? moduleTabIndex;
  final ValueChanged<int>? onModuleTab;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool wrapBody;
  final bool glassBackground;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.ruhh;
    final labels = moduleTabLabels;
    final tabIndex = moduleTabIndex ?? 0;
    final onTab = onModuleTab;

    Widget pageBody = wrapBody ? NBPageBody(child: body) : body;

    final trailing = <Widget>[
      if (ref.watch(overlaySupportedProvider))
        RuhhIconCircleButton(
          icon: Icons.bolt_outlined,
          onPressed: () => openQuickAction(context, ref),
        ),
      const SizedBox(width: 8),
      RuhhProfileAvatar(onTap: () => context.push('/settings')),
      if (actions != null) ...actions!,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: kFabAboveBottomNavLocation,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (showBackButton)
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                Expanded(
                  child: RuhhScreenHeader(title: title, actions: trailing),
                ),
              ],
            ),
          ),
          if (labels != null && labels.length > 1 && onTab != null)
            RuhhModuleTabStrip(
              labels: labels,
              selectedIndex: tabIndex.clamp(0, labels.length - 1),
              onSelected: onTab,
            ),
          Expanded(child: pageBody),
        ],
      ),
    );
  }
}

class NBStatusChip extends StatelessWidget {
  const NBStatusChip({
    super.key,
    required this.label,
    this.pastel,
  });

  final String label;
  final Color? pastel;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pastel ?? t.accentSlatePastel,
        borderRadius: BorderRadius.circular(t.radiusChip),
      ),
      child: Text(
        label,
        style: t.micro(Theme.of(context).textTheme),
      ),
    );
  }
}
