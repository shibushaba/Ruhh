import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/movie/movie_watchlist_page.dart';

final movieTabIndexProvider = StateProvider<int>((ref) => 0);

class MoviePage extends ConsumerStatefulWidget {
  const MoviePage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends ConsumerState<MoviePage> {
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab.clamp(0, 1);
    _pages = PageController(initialPage: tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(movieTabIndexProvider.notifier).state = tab;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onTab(int i) {
    ref.read(movieTabIndexProvider.notifier).state = i;
    _pages.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(movieTabIndexProvider, (prev, next) {
      if (_pages.hasClients && _pages.page?.round() != next) {
        _pages.jumpToPage(next);
      }
    });
    final index = ref.watch(movieTabIndexProvider);
    final t = context.ruhh;

    return NBModuleScaffold(
      title: 'Movies',
      wrapBody: false,
      moduleTabLabels: const ['Watchlist', 'Watched'],
      moduleTabIndex: index,
      onModuleTab: _onTab,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add movie',
        onPressed: () => context.push('/movie/add'),
        child: Icon(AppIcons.plus(filled: true)),
      ),
      actions: [
        IconButton(
          tooltip: 'Categories',
          icon: Icon(AppIcons.slidersHorizontal()),
          onPressed: () => context.push('/movie/categories'),
        ),
      ],
      body: PageView(
        controller: _pages,
        onPageChanged: (i) =>
            ref.read(movieTabIndexProvider.notifier).state = i,
        children: const [
          MovieWatchlistPage(),
          MovieWatchedPage(),
        ],
      ),
    );
  }
}
