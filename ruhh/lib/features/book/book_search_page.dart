import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/book/book_repository.dart';
import 'package:ruhh/features/book/open_library_service.dart';

class BookSearchPage extends ConsumerStatefulWidget {
  const BookSearchPage({super.key});

  @override
  ConsumerState<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends ConsumerState<BookSearchPage> {
  final _query = TextEditingController();
  final _manualTitle = TextEditingController();
  final _manualAuthor = TextEditingController();
  List<OpenLibraryBook> _hits = [];
  bool _searching = false;
  String? _error;
  bool _manualMode = false;

  @override
  void dispose() {
    _query.dispose();
    _manualTitle.dispose();
    _manualAuthor.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final repo = await ref.read(bookRepositoryProvider.future);
      final hits = await repo.openLibrary.search(q);
      if (!mounted) return;
      setState(() {
        _hits = hits;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _searching = false;
      });
    }
  }

  Future<void> _addHit(OpenLibraryBook hit) async {
    final repo = await ref.read(bookRepositoryProvider.future);
    await repo.addFromOpenLibrary(hit);
    bumpBookRefresh(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added “${hit.title}”')),
    );
  }

  Future<void> _addManual() async {
    final title = _manualTitle.text.trim();
    if (title.isEmpty) return;
    final repo = await ref.read(bookRepositoryProvider.future);
    await repo.addManual(
      title: title,
      author: _manualAuthor.text.trim(),
    );
    bumpBookRefresh(ref);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return NBModuleScaffold(
      title: _manualMode ? 'Manual book' : 'Find books',
      actions: [
        TextButton(
          onPressed: () => setState(() => _manualMode = !_manualMode),
          child: Text(_manualMode ? 'Search' : 'Manual'),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_manualMode) ...[
            NBTextField(controller: _manualTitle, label: 'Title'),
            const SizedBox(height: 12),
            NBTextField(controller: _manualAuthor, label: 'Author (optional)'),
            const SizedBox(height: 16),
            NBButton(
              label: 'Add to shelf',
              onPressed: _addManual,
            ),
          ] else ...[
            NBTextField(
              controller: _query,
              label: 'Search Open Library',
              suffix: IconButton(
                icon: Icon(AppIcons.magnifyingGlass()),
                onPressed: _searching ? null : _search,
              ),
            ),
            const SizedBox(height: 12),
            NBButton(
              label: _searching ? 'Searching…' : 'Search',
              onPressed: _searching ? null : _search,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: NBMetrics.expenseRed)),
            ],
            const SizedBox(height: 16),
            ..._hits.map((hit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RuhhSoftCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _MiniCover(url: hit.coverUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hit.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (hit.author != null)
                              Text(
                                hit.author!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add',
                        onPressed: () => _addHit(hit),
                        icon: Icon(AppIcons.plus(filled: true)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        width: 40,
        height: 56,
        color: NBColors.book.withValues(alpha: 0.2),
        child: Icon(AppIcons.book(), size: 18, color: NBColors.book),
      );
    }
    return Image.network(
      url!,
      width: 40,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 40,
        height: 56,
        color: NBColors.book.withValues(alpha: 0.2),
      ),
    );
  }
}
