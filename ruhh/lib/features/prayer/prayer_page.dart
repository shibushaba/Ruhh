import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/prayer/prayer_home_page.dart';
import 'package:ruhh/features/prayer/prayer_settings_page.dart';
import 'package:ruhh/features/prayer/prayer_stats_page.dart';

final prayerTabIndexProvider = StateProvider<int>((ref) => 0);

class PrayerPage extends ConsumerStatefulWidget {
  const PrayerPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends ConsumerState<PrayerPage> {
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab;
    _pages = PageController(initialPage: tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prayerTabIndexProvider.notifier).state = tab;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onTab(int i) {
    ref.read(prayerTabIndexProvider.notifier).state = i;
    _pages.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(prayerTabIndexProvider, (prev, next) {
      if (_pages.hasClients && _pages.page?.round() != next) {
        _pages.jumpToPage(next);
      }
    });
    final index = ref.watch(prayerTabIndexProvider);

    return NBModuleScaffold(
      title: 'Prayer',
      body: PageView(
        controller: _pages,
        onPageChanged: (i) =>
            ref.read(prayerTabIndexProvider.notifier).state = i,
        children: const [
          PrayerHomePage(),
          PrayerStatsPage(),
          PrayerSettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Deep link to stats tab (legacy `/prayer/stats`).
class PrayerStatsRedirect extends ConsumerWidget {
  const PrayerStatsRedirect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prayerTabIndexProvider.notifier).state = 1;
      context.go('/prayer?tab=1');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
