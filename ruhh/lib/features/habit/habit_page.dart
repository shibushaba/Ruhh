import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/habit/habit_home_page.dart';
import 'package:ruhh/features/habit/habit_list_page.dart';
import 'package:ruhh/features/habit/habit_settings_page.dart';
import 'package:ruhh/features/habit/habit_stats_page.dart';

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
    final tab = widget.initialTab.clamp(0, 2);
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
    final t = context.ruhh;

    return NBModuleScaffold(
      title: 'Habits',
      wrapBody: false,
      moduleTabLabels: const ['Today', 'Habits', 'Stats'],
      moduleTabIndex: index,
      onModuleTab: _onTab,
      floatingActionButton: FloatingActionButton(
        tooltip: 'New habit',
        onPressed: () => context.push('/habit/new'),
        child: Icon(AppIcons.plus(filled: true)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const HabitSettingsPage(),
            ),
          ),
        ),
      ],
      body: PageView(
        controller: _pages,
        onPageChanged: (i) =>
            ref.read(habitTabIndexProvider.notifier).state = i,
        children: const [
          HabitHomePage(),
          HabitListPage(),
          HabitStatsPage(),
        ],
      ),
    );
  }
}
