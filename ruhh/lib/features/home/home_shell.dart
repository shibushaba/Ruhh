import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: NBColors.canvas(Theme.of(context).brightness),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(loc),
        onDestinationSelected: (i) => context.go(_pathFor(i)),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  int _indexFor(String path) {
    if (path.startsWith('/settings')) return 1;
    return 0;
  }

  String _pathFor(int index) => switch (index) {
        0 => '/home',
        _ => '/settings',
      };
}
