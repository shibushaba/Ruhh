import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/book_local.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_dialog.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';
import 'package:ruhh/features/book/book_repository.dart';

final wantToReadBooksProvider = StreamProvider<List<BookLocal>>((ref) async* {
  final repo = await ref.watch(bookRepositoryProvider.future);
  yield* repo.watchWantToRead();
});

final readBooksProvider = StreamProvider<List<BookLocal>>((ref) async* {
  final repo = await ref.watch(bookRepositoryProvider.future);
  yield* repo.watchFinished();
});

class BookWantToReadPage extends ConsumerWidget {
  const BookWantToReadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(wantToReadBooksProvider);
    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (books) {
        if (books.isEmpty) {
          return const _EmptyBooks(
            title: 'No books yet',
            subtitle: 'Search Open Library to build your shelf',
          );
        }
        return ListView.builder(
          padding: ruhhListPadding(
            context,
            base: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return _BookCard(
              book: book,
              actionLabel: 'Read',
              onAction: () async {
                final repo = await ref.read(bookRepositoryProvider.future);
                await repo.markRead(book);
                bumpBookRefresh(ref);
              },
              onEdit: () => context.push('/book/edit/${book.remoteId}'),
              onDelete: () => _delete(context, ref, book),
            );
          },
        );
      },
    );
  }
}

class BookReadPage extends ConsumerWidget {
  const BookReadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(readBooksProvider);
    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (books) {
        if (books.isEmpty) {
          return const _EmptyBooks(
            title: 'Nothing finished',
            subtitle: 'Mark a book as read from Want to read',
          );
        }
        return ListView.builder(
          padding: ruhhListPadding(
            context,
            base: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return _BookCard(
              book: book,
              actionLabel: 'Shelf',
              onAction: () async {
                final repo = await ref.read(bookRepositoryProvider.future);
                await repo.moveToWantToRead(book);
                bumpBookRefresh(ref);
              },
              onEdit: () => context.push('/book/edit/${book.remoteId}'),
              onDelete: () => _delete(context, ref, book),
            );
          },
        );
      },
    );
  }
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  BookLocal book,
) async {
  final ok = await showNBConfirmDialog(
    context: context,
    title: 'Remove book?',
    message: book.title,
    confirmLabel: 'Remove',
    destructive: true,
  );
  if (ok != true) return;
  final repo = await ref.read(bookRepositoryProvider.future);
  await repo.remove(book);
  bumpBookRefresh(ref);
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.actionLabel,
    required this.onAction,
    required this.onEdit,
    required this.onDelete,
  });

  final BookLocal book;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final year = book.firstPublishYear;
    final subtitle = [
      if (book.author != null && book.author!.isNotEmpty) book.author,
      if (year != null) '$year',
      if (book.pageCount != null) 'p.${book.pageCount}',
      if (book.status == BookStatus.reading) 'reading',
    ].join(' · ');

    return Padding(
      padding: EdgeInsets.only(bottom: t.spaceStackGap),
      child: RuhhSoftCard(
        padding: const EdgeInsets.all(12),
        onTap: onEdit,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(url: book.coverUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: onAction,
                        child: Text(actionLabel),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        icon: Icon(AppIcons.pencilSimple(), size: 18),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: onDelete,
                        icon: Icon(AppIcons.trash(), size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = Size(56, 80);
    final radius = BorderRadius.circular(6);
    if (url == null || url!.isEmpty) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: NBColors.book.withValues(alpha: 0.2),
          borderRadius: radius,
        ),
        child: Icon(AppIcons.book(filled: true), color: NBColors.book),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url!,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size.width,
          height: size.height,
          color: NBColors.book.withValues(alpha: 0.2),
          child: Icon(AppIcons.book(), color: NBColors.book),
        ),
      ),
    );
  }
}

class _EmptyBooks extends StatelessWidget {
  const _EmptyBooks({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.emptyBookDuotone(), size: 48, color: NBColors.book),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
