import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/book/book_list_page.dart';

final bookTabIndexProvider = StateProvider<int>((ref) => 0);

class BookPage extends ConsumerStatefulWidget {
  const BookPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<BookPage> createState() => _BookPageState();
}

class _BookPageState extends ConsumerState<BookPage> {
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab.clamp(0, 1);
    _pages = PageController(initialPage: tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookTabIndexProvider.notifier).state = tab;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onTab(int i) {
    ref.read(bookTabIndexProvider.notifier).state = i;
    _pages.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bookTabIndexProvider, (prev, next) {
      if (_pages.hasClients && _pages.page?.round() != next) {
        _pages.jumpToPage(next);
      }
    });
    final index = ref.watch(bookTabIndexProvider);

    return NBModuleScaffold(
      title: 'Books',
      wrapBody: false,
      moduleTabLabels: const ['Want to read', 'Read'],
      moduleTabIndex: index,
      onModuleTab: _onTab,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add book',
        onPressed: () => context.push('/book/add'),
        child: Icon(AppIcons.plus(filled: true)),
      ),
      body: PageView(
        controller: _pages,
        onPageChanged: (i) =>
            ref.read(bookTabIndexProvider.notifier).state = i,
        children: const [
          BookWantToReadPage(),
          BookReadPage(),
        ],
      ),
    );
  }
}
