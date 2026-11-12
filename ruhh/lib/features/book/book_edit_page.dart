import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/book_local.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/book/book_repository.dart';
import 'package:ruhh/features/movie/widgets/nb_star_rating.dart';

class BookEditPage extends ConsumerStatefulWidget {
  const BookEditPage({super.key, required this.remoteId});

  final String remoteId;

  @override
  ConsumerState<BookEditPage> createState() => _BookEditPageState();
}

class _BookEditPageState extends ConsumerState<BookEditPage> {
  BookLocal? _book;
  bool _loading = true;
  BookStatus _status = BookStatus.wantToRead;
  final _pagesCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = await ref.read(bookRepositoryProvider.future);
    final book = await repo.byRemoteId(widget.remoteId);
    if (!mounted) return;
    setState(() {
      _book = book;
      if (book != null) {
        _status = book.status;
        _pagesCtrl.text = book.pageCount?.toString() ?? '';
        _noteCtrl.text = book.note;
        _rating = (book.userRating ?? 0).round().clamp(0, 5);
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pagesCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final book = _book;
    if (book == null) return;
    final pages = int.tryParse(_pagesCtrl.text.trim());
    final repo = await ref.read(bookRepositoryProvider.future);
    await repo.updateBook(
      book: book,
      status: _status,
      pageCount: pages,
      userRating: _rating > 0 ? _rating : null,
      note: _noteCtrl.text,
    );
    bumpBookRefresh(ref);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const NBModuleScaffold(
        title: 'Edit book',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final book = _book;
    if (book == null) {
      return const NBModuleScaffold(
        title: 'Edit book',
        body: Center(child: Text('Book not found')),
      );
    }

    return NBModuleScaffold(
      title: 'Edit book',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(book.title, style: Theme.of(context).textTheme.titleLarge),
          if (book.author != null && book.author!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(book.author!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          Text('Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RuhhSegmentedChips(
            labels: const ['Want', 'Reading', 'Read'],
            selectedIndex: switch (_status) {
              BookStatus.wantToRead => 0,
              BookStatus.reading => 1,
              BookStatus.read => 2,
            },
            onSelected: (i) => setState(() {
              _status = switch (i) {
                1 => BookStatus.reading,
                2 => BookStatus.read,
                _ => BookStatus.wantToRead,
              };
            }),
          ),
          const SizedBox(height: 16),
          NBTextField(
            controller: _pagesCtrl,
            label: 'Pages read',
            keyboardType: TextInputType.number,
            hint: 'e.g. 120',
          ),
          const SizedBox(height: 16),
          Text('Rating', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_rating == 0)
            Text(
              'Tap a star to rate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.ruhh.textSecondary,
                  ),
            ),
          NBStarRating(
            value: _rating == 0 ? 1 : _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          if (_rating > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _rating = 0),
                child: const Text('Clear rating'),
              ),
            ),
          const SizedBox(height: 8),
          NBTextField(controller: _noteCtrl, label: 'Notes'),
          const SizedBox(height: 24),
          NBButton(label: 'Save', onPressed: _save),
        ],
      ),
    );
  }
}
