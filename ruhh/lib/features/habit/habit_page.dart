import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/focus/focus_page.dart';
import 'package:ruhh/features/habit/habit_home_page.dart';
import 'package:ruhh/features/habit/habit_settings_page.dart';
import 'package:ruhh/features/habit/habit_stats_page.dart';
import 'package:ruhh/features/island/island_page.dart';
import 'package:ruhh/features/todo/todos_page.dart';

final habitTabIndexProvider = StateProvider<int>((ref) => 0);

class HabitPage extends ConsumerStatefulWidget {
  const HabitPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends ConsumerState<HabitPage> {
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab.clamp(0, 5);
    _pages = PageController(initialPage: tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitTabIndexProvider.notifier).state = tab;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onTab(int i) {
    ref.read(habitTabIndexProvider.notifier).state = i;
    _pages.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(habitTabIndexProvider, (prev, next) {
      if (_pages.hasClients && _pages.page?.round() != next) {
        _pages.jumpToPage(next);
      }
    });
    final index = ref.watch(habitTabIndexProvider);

    return NBModuleScaffold(
      title: 'Habits',
      floatingActionButton: index == 0
          ? FloatingActionButton(
              backgroundColor: NBColors.habit,
              onPressed: () => context.push('/habit/new'),
              child: const Icon(Icons.add, color: NBColors.black),
            )
          : null,
      body: PageView(
        controller: _pages,
        onPageChanged: (i) =>
            ref.read(habitTabIndexProvider.notifier).state = i,
        children: const [
          HabitHomePage(),
          TodosPage(),
          FocusPage(),
          HabitStatsPage(),
          IslandPage(),
          HabitSettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Todos'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Focus'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.landscape_outlined), label: 'Island'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
