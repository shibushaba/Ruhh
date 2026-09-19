import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/movie/movie_discover_page.dart';
import 'package:ruhh/features/movie/movie_home_page.dart';
import 'package:ruhh/features/movie/movie_library_page.dart';
import 'package:ruhh/features/movie/movie_search_page.dart';

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
    final tab = widget.initialTab.clamp(0, 3);
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

    return NBModuleScaffold(
      title: 'Movies',
      body: PageView(
        controller: _pages,
        onPageChanged: (i) =>
            ref.read(movieTabIndexProvider.notifier).state = i,
        children: const [
          MovieHomePage(),
          MovieDiscoverPage(),
          MovieSearchPage(),
          MovieLibraryPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), label: 'Library'),
        ],
      ),
    );
  }
}
