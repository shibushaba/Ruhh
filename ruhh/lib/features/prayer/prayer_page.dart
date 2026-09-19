import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/prayer/prayer_calendar_page.dart';
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
    final tab = widget.initialTab.clamp(0, 2);
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
    final t = context.ruhh;

    return NBModuleScaffold(
      title: 'Prayer',
      wrapBody: false,
      moduleTabLabels: const ['Today', 'Calendar', 'Stats'],
      moduleTabIndex: index,
      onModuleTab: _onTab,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Today\'s prayers',
        onPressed: () {
          _onTab(0);
        },
        child: Icon(AppIcons.plus(filled: true)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PrayerSettingsPage(),
            ),
          ),
        ),
      ],
      body: PageView(
        controller: _pages,
        onPageChanged: (i) =>
            ref.read(prayerTabIndexProvider.notifier).state = i,
        children: const [
          PrayerHomePage(),
          PrayerCalendarPage(),
          PrayerStatsPage(),
        ],
      ),
    );
  }
}

class PrayerStatsRedirect extends ConsumerWidget {
  const PrayerStatsRedirect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prayerTabIndexProvider.notifier).state = 2;
      context.go('/prayer?tab=2');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
