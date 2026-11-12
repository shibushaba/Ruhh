import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/book_local.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/core/services/local_data_sync.dart';
import 'package:ruhh/core/services/overlay_runtime.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/book/open_library_service.dart';
import 'package:uuid/uuid.dart';

class BookRepository {
  BookRepository(this._isar, this._userId, this._openLibrary);

  final Isar _isar;
  final String _userId;
  final OpenLibraryService _openLibrary;

  OpenLibraryService get openLibrary => _openLibrary;

  void _markCloudBackupNeeded() => notifyLocalDataChanged();

  Future<List<BookLocal>> _allForUser() async {
    final all = await _isar.bookLocals.where().findAll();
    return all.where((b) => b.userId == _userId).toList();
  }

  Future<List<BookLocal>> wantToRead() async {
    final list = await _allForUser();
    return list
        .where((b) =>
            b.status == BookStatus.wantToRead ||
            b.status == BookStatus.reading)
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  Future<List<BookLocal>> finished() async {
    final list = await _allForUser();
    return list.where((b) => b.status == BookStatus.read).toList()
      ..sort((a, b) => (b.finishedAt ?? b.addedAt)
          .compareTo(a.finishedAt ?? a.addedAt));
  }

  Future<int> finishedThisMonth() async {
    final now = DateTime.now();
    final list = await finished();
    return list.where((b) {
      final at = b.finishedAt;
      return at != null && at.year == now.year && at.month == now.month;
    }).length;
  }

  Future<BookLocal?> byRemoteId(String remoteId) async {
    for (final b in await _allForUser()) {
      if (b.remoteId == remoteId) return b;
    }
    return null;
  }

  Future<BookLocal?> byOpenLibraryKey(String key) async {
    for (final b in await _allForUser()) {
      if (b.openLibraryKey == key) return b;
    }
    return null;
  }

  Future<BookLocal> addFromOpenLibrary(OpenLibraryBook hit) async {
    final existing = hit.key.isEmpty
        ? null
        : await byOpenLibraryKey(hit.key);
    if (existing != null) return existing;

    final book = BookLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..openLibraryKey = hit.key.isEmpty ? null : hit.key
      ..title = hit.title.trim()
      ..author = hit.author
      ..coverUrl = hit.coverUrl
      ..firstPublishYear = hit.firstPublishYear
      ..status = BookStatus.wantToRead
      ..note = ''
      ..addedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.bookLocals.put(book));
    _markCloudBackupNeeded();
    return book;
  }

  Future<BookLocal> addManual({
    required String title,
    String? author,
    String? note,
  }) async {
    final book = BookLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..title = title.trim()
      ..author = author?.trim().isEmpty == true ? null : author?.trim()
      ..status = BookStatus.wantToRead
      ..note = note?.trim() ?? ''
      ..addedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.bookLocals.put(book));
    _markCloudBackupNeeded();
    return book;
  }

  Future<void> updateBook({
    required BookLocal book,
    required BookStatus status,
    int? pageCount,
    int? userRating,
    String note = '',
  }) async {
    book.status = status;
    book.pageCount = pageCount;
    book.userRating = userRating?.toDouble();
    book.note = note.trim();
    if (status == BookStatus.read) {
      book.finishedAt ??= DateTime.now();
    } else {
      book.finishedAt = null;
    }
    await _isar.writeTxn(() => _isar.bookLocals.put(book));
    _markCloudBackupNeeded();
  }

  Future<void> markRead(BookLocal book) async {
    book.status = BookStatus.read;
    book.finishedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.bookLocals.put(book));
    _markCloudBackupNeeded();
  }

  Future<void> moveToWantToRead(BookLocal book) async {
    book.status = BookStatus.wantToRead;
    book.finishedAt = null;
    await _isar.writeTxn(() => _isar.bookLocals.put(book));
    _markCloudBackupNeeded();
  }

  Future<void> remove(BookLocal book) async {
    await _isar.writeTxn(() => _isar.bookLocals.delete(book.id));
    _markCloudBackupNeeded();
  }

  Stream<List<BookLocal>> watchWantToRead() async* {
    yield await wantToRead();
    yield* _isar.bookLocals.watchLazy().asyncMap((_) => wantToRead());
  }

  Stream<List<BookLocal>> watchFinished() async* {
    yield await finished();
    yield* _isar.bookLocals.watchLazy().asyncMap((_) => finished());
  }
}

final openLibraryServiceProvider = Provider((ref) => OpenLibraryService());

final bookRepositoryProvider = FutureProvider<BookRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  return BookRepository(
    isar,
    user.supabaseId ?? user.id.toString(),
    ref.watch(openLibraryServiceProvider),
  );
});

final bookRefreshProvider = StateProvider<int>((ref) => 0);

void bumpBookRefresh(WidgetRef ref, {bool scheduleCloudSync = true}) {
  ref.read(bookRefreshProvider.notifier).state++;
  if (scheduleCloudSync && !ruhhOverlayIsolate) {
    scheduleCloudSyncFromWidget(ref);
  }
}
