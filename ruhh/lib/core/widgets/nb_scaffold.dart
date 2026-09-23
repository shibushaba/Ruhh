import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/services/overlay_launch.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_fab_location.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';

/// Parent route when the stack cannot pop (sibling GoRouter locations).
String? ruhhParentRoute(String matchedLocation) {
  if (matchedLocation == '/analytics') return '/home';
  if (matchedLocation.startsWith('/settings/')) return '/settings';
  return null;
}

bool ruhhShouldShowBack(
  BuildContext context, {
  bool moduleTabCanBack = false,
}) {
  if (moduleTabCanBack) return true;
  if (context.canPop()) return true;
  final loc = GoRouterState.of(context).matchedLocation;
  return ruhhParentRoute(loc) != null;
}

void ruhhNavigateBack(
  BuildContext context, {
  VoidCallback? onModuleTabBack,
}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  if (onModuleTabBack != null) {
    onModuleTabBack();
    return;
  }
  final parent = ruhhParentRoute(GoRouterState.of(context).matchedLocation);
  if (parent != null) {
    context.go(parent);
  }
}

/// Back control when this route can pop or has a known parent section.
Widget? ruhhBackLeading(
  BuildContext context, {
  VoidCallback? onPressed,
  VoidCallback? onModuleTabBack,
}) {
  final show = onPressed != null ||
      ruhhShouldShowBack(context, moduleTabCanBack: onModuleTabBack != null);
  if (!show) return null;
  return IconButton(
    onPressed: onPressed ?? () => ruhhNavigateBack(context, onModuleTabBack: onModuleTabBack),
    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
    tooltip: 'Back',
  );
}

/// App bar with portfolio styling and automatic back when [GoRouter] can pop.
PreferredSizeWidget ruhhAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    automaticallyImplyLeading: false,
    leading: ruhhBackLeading(context),
    title: Text(title),
    actions: actions,
    bottom: bottom,
  );
}

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
    this.hideBackButton = false,
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
  final bool hideBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.ruhh;
    final labels = moduleTabLabels;
    final tabIndex = moduleTabIndex ?? 0;
    final onTab = onModuleTab;
    final tabCanBack =
        labels != null && labels.length > 1 && tabIndex > 0 && onTab != null;

    void onModuleTabBack() => onTab!(tabIndex - 1);

    final shellScrollBottom = ruhhModuleShellBottomInset(
      context,
      hasFab: floatingActionButton != null,
    );

    Widget pageBody = wrapBody
        ? NBPageBody(child: body)
        : RuhhShellScrollInsets(
            bottom: shellScrollBottom,
            child: body,
          );

    final showBack = !hideBackButton &&
        (showBackButton ||
            ruhhShouldShowBack(context, moduleTabCanBack: tabCanBack));

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
                if (showBack)
                  IconButton(
                    onPressed: () => ruhhNavigateBack(
                      context,
                      onModuleTabBack: tabCanBack ? onModuleTabBack : null,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    tooltip: 'Back',
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
