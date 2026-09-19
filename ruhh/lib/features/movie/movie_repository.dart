import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/movie_category_local.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/movie/tmdb_service.dart';
import 'package:ruhh/features/movie/tracker/movie_defaults.dart';
import 'package:ruhh/features/movie/tracker/movie_sort.dart';
import 'package:uuid/uuid.dart';

class MovieLibraryStats {
  const MovieLibraryStats({
    required this.want,
    required this.watching,
    required this.watched,
    required this.favorites,
    required this.rated,
  });

  final int want;
  final int watching;
  final int watched;
  final int favorites;
  final int rated;
}

class MovieRepository {
  MovieRepository(this._isar, this._userId, this._tmdb);

  final Isar _isar;
  final String _userId;
  final TmdbService _tmdb;

  Stream<List<MovieLocal>> watchLibrary() async* {
    yield await all();
    await for (final _ in _isar.movieLocals.watchLazy(fireImmediately: false)) {
      yield await all();
    }
  }

  Future<List<MovieLocal>> all() => _isar.movieLocals
      .filter()
      .userIdEqualTo(_userId)
      .sortByAddedAtDesc()
      .findAll();

  Future<List<MovieLocal>> byStatus(WatchStatus status) => _isar.movieLocals
      .filter()
      .userIdEqualTo(_userId)
      .watchStatusEqualTo(status)
      .sortByAddedAtDesc()
      .findAll();

  Future<List<MovieLocal>> favorites() => _isar.movieLocals
      .filter()
      .userIdEqualTo(_userId)
      .favoriteEqualTo(true)
      .findAll();

  Future<MovieLocal?> byTmdb(int tmdbId, String mediaType) =>
      _isar.movieLocals
          .filter()
          .userIdEqualTo(_userId)
          .tmdbIdEqualTo(tmdbId)
          .mediaTypeEqualTo(mediaType)
          .findFirst();

  Future<MovieLibraryStats> stats() async {
    final all = await this.all();
    return MovieLibraryStats(
      want: all.where((m) => m.watchStatus == WatchStatus.wantToWatch).length,
      watching: all.where((m) => m.watchStatus == WatchStatus.watching).length,
      watched: all.where((m) => m.watchStatus == WatchStatus.watched).length,
      favorites: all.where((m) => m.favorite).length,
      rated: all.where((m) => m.userRating != null).length,
    );
  }

  Future<MovieLocal> logFromTmdb(
    Map<String, dynamic> item, {
    required WatchStatus status,
    double? rating,
    String review = '',
    bool liked = false,
    bool favorite = false,
  }) async {
    await ensureTrackerDefaults();
    final tmdbId = item['id'] as int?;
    final mediaType = TmdbService.mediaTypeOf(item);
    MovieLocal? existing;
    if (tmdbId != null) {
      existing = await byTmdb(tmdbId, mediaType);
    }
    final m = existing ??
        (MovieLocal()
          ..remoteId = const Uuid().v4()
          ..userId = _userId
          ..addedAt = DateTime.now()
          ..trackerNote = review
          ..priority = 3
          ..categoryRemoteId = '');
    m
      ..tmdbId = tmdbId
      ..title = TmdbService.titleOf(item)
      ..posterPath = item['poster_path'] as String?
      ..backdropPath = item['backdrop_path'] as String?
      ..overview = item['overview'] as String?
      ..mediaType = mediaType
      ..releaseDate = TmdbService.releaseOf(item)
      ..voteAverage = (item['vote_average'] as num?)?.toDouble()
      ..watchStatus = status
      ..userRating = rating
      ..userReview = review
      ..liked = liked
      ..favorite = favorite
      ..watchedAt = status == WatchStatus.watched ? DateTime.now() : m.watchedAt;
    if (m.categoryRemoteId.isEmpty) {
      final other = await defaultCategory();
      if (other != null) m.categoryRemoteId = other.remoteId;
    }
    if (m.trackerNote.isEmpty && review.isNotEmpty) {
      m.trackerNote = review;
    } else if (existing == null && review.isNotEmpty) {
      m.trackerNote = review;
    }
    await _isar.writeTxn(() => _isar.movieLocals.put(m));
    return m;
  }

  Future<void> setStatus(MovieLocal movie, WatchStatus status) async {
    movie.watchStatus = status;
    if (status == WatchStatus.watched) {
      movie.watchedAt = DateTime.now();
    }
    await _isar.writeTxn(() => _isar.movieLocals.put(movie));
  }

  Future<void> updateEntry(
    MovieLocal movie, {
    WatchStatus? status,
    double? rating,
    String? review,
    bool? liked,
    bool? favorite,
  }) async {
    if (status != null) {
      movie.watchStatus = status;
      if (status == WatchStatus.watched) movie.watchedAt = DateTime.now();
    }
    if (rating != null) movie.userRating = rating;
    if (review != null) movie.userReview = review;
    if (liked != null) movie.liked = liked;
    if (favorite != null) movie.favorite = favorite;
    await _isar.writeTxn(() => _isar.movieLocals.put(movie));
  }

  Future<void> remove(MovieLocal movie) async {
    await _isar.writeTxn(() => _isar.movieLocals.delete(movie.id));
  }

  Future<int> watchedThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    return _isar.movieLocals
        .filter()
        .userIdEqualTo(_userId)
        .watchStatusEqualTo(WatchStatus.watched)
        .watchedAtGreaterThan(start.subtract(const Duration(days: 1)))
        .count();
  }

  TmdbService get tmdb => _tmdb;

  String posterUrl(String? path) => TmdbService.posterUrl(path);

  Future<List<Map<String, dynamic>>> searchTmdb(String q) =>
      _tmdb.searchMulti(q);

  /// Title search over the user's library (overlay / quick mark watched).
  Future<List<MovieLocal>> searchLocalTitles(
    String query, {
    int limit = 8,
    WatchStatus? excludeStatus,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final movies = await all();
    return movies
        .where((m) {
          if (excludeStatus != null && m.watchStatus == excludeStatus) {
            return false;
          }
          return m.title.toLowerCase().contains(q);
        })
        .take(limit)
        .toList();
  }

  Future<MovieLocal> addManual({
    required String title,
    required WatchStatus status,
    String mediaType = 'movie',
    int priority = 3,
    String? categoryRemoteId,
    String note = '',
  }) async {
    await ensureTrackerDefaults();
    final catId =
        categoryRemoteId ?? (await defaultCategory())?.remoteId ?? '';
    final m = MovieLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..title = title
      ..mediaType = mediaType
      ..watchStatus = status
      ..userReview = ''
      ..trackerNote = note
      ..liked = false
      ..favorite = false
      ..addedAt = DateTime.now()
      ..priority = priority.clamp(1, 5)
      ..categoryRemoteId = catId;
    if (status == WatchStatus.watched) {
      m.watchedAt = DateTime.now();
    }
    await _isar.writeTxn(() => _isar.movieLocals.put(m));
    return m;
  }

  // --- Tracker (manual watchlist) ---

  Future<void> ensureTrackerDefaults() async {
    var cats = await _isar.movieCategoryLocals
        .filter()
        .userIdEqualTo(_userId)
        .findAll();
    if (cats.isEmpty) {
      await _isar.writeTxn(() async {
        for (var i = 0; i < defaultMovieCategoryNames.length; i++) {
          final c = MovieCategoryLocal()
            ..remoteId = const Uuid().v4()
            ..userId = _userId
            ..name = defaultMovieCategoryNames[i]
            ..colorValue = movieCategoryColorForName(defaultMovieCategoryNames[i])
                .toARGB32()
            ..isCustom = false
            ..isArchived = false
            ..sortOrder = i;
          await _isar.movieCategoryLocals.put(c);
        }
      });
      cats = await _isar.movieCategoryLocals
          .filter()
          .userIdEqualTo(_userId)
          .findAll();
    }
    await _isar.writeTxn(() async {
      for (final c in cats) {
        if (c.isCustom) continue;
        final idx = defaultMovieCategoryNames.indexOf(c.name);
        if (idx < 0) continue;
        final expected =
            movieCategoryColorForName(c.name).toARGB32();
        if (c.colorValue != expected) {
          c.colorValue = expected;
          await _isar.movieCategoryLocals.put(c);
        }
      }
    });
    MovieCategoryLocal? other;
    for (final c in cats) {
      if (c.name == 'Other') {
        other = c;
        break;
      }
    }
    other ??= cats.isNotEmpty ? cats.first : null;
    final otherId = other?.remoteId ?? '';
    final movies = await all();
    var dirty = false;
    for (final m in movies) {
      if (m.categoryRemoteId.isEmpty && otherId.isNotEmpty) {
        m.categoryRemoteId = otherId;
        dirty = true;
      }
      if (m.priority < 1 || m.priority > 5) {
        m.priority = 3;
        dirty = true;
      }
    }
    if (dirty) {
      await _isar.writeTxn(() => _isar.movieLocals.putAll(movies));
    }
  }

  Stream<List<MovieCategoryLocal>> watchCategories() async* {
    yield await categoriesAll();
    await for (final _
        in _isar.movieCategoryLocals.watchLazy(fireImmediately: false)) {
      yield await categoriesAll();
    }
  }

  Future<List<MovieCategoryLocal>> categoriesAll() => _isar.movieCategoryLocals
      .filter()
      .userIdEqualTo(_userId)
      .sortBySortOrder()
      .findAll();

  Future<List<MovieCategoryLocal>> categoriesActive() async {
    final all = await categoriesAll();
    return all.where((c) => !c.isArchived).toList();
  }

  Future<MovieCategoryLocal?> categoryByRemoteId(String remoteId) =>
      _isar.movieCategoryLocals
          .filter()
          .userIdEqualTo(_userId)
          .remoteIdEqualTo(remoteId)
          .findFirst();

  Future<MovieCategoryLocal?> categoryByName(String name) =>
      _isar.movieCategoryLocals
          .filter()
          .userIdEqualTo(_userId)
          .nameEqualTo(name)
          .findFirst();

  Future<MovieCategoryLocal?> defaultCategory() => categoryByName('Other');

  Future<MovieCategoryLocal> createCategory({
    required String name,
    required Color color,
    bool isCustom = true,
  }) async {
    final all = await categoriesActive();
    final c = MovieCategoryLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..name = name.trim()
      ..colorValue = color.toARGB32()
      ..isCustom = isCustom
      ..isArchived = false
      ..sortOrder = all.length;
    await _isar.writeTxn(() => _isar.movieCategoryLocals.put(c));
    return c;
  }

  Future<void> updateCategory(
    MovieCategoryLocal cat, {
    String? name,
    Color? color,
  }) async {
    if (name != null) cat.name = name.trim();
    if (color != null) cat.colorValue = color.toARGB32();
    await _isar.writeTxn(() => _isar.movieCategoryLocals.put(cat));
  }

  Future<void> archiveCategory(MovieCategoryLocal cat) async {
    cat.isArchived = true;
    await _isar.writeTxn(() => _isar.movieCategoryLocals.put(cat));
  }

  Future<int> movieCountForCategory(String categoryRemoteId) => _isar.movieLocals
      .filter()
      .userIdEqualTo(_userId)
      .categoryRemoteIdEqualTo(categoryRemoteId)
      .count();

  Stream<List<MovieLocal>> watchWatchlist() async* {
    yield await watchlistMovies();
    await for (final _ in _isar.movieLocals.watchLazy(fireImmediately: false)) {
      yield await watchlistMovies();
    }
  }

  Stream<List<MovieLocal>> watchWatchedList() async* {
    yield await watchedMovies();
    await for (final _ in _isar.movieLocals.watchLazy(fireImmediately: false)) {
      yield await watchedMovies();
    }
  }

  Future<List<MovieLocal>> watchlistMovies() async {
    final movies = await all();
    return sortWatchlistMovies(movies.where(isMovieWatchlist).toList());
  }

  Future<List<MovieLocal>> watchedMovies() async {
    final movies = await all();
    return sortWatchedMovies(movies.where(isMovieWatched).toList());
  }

  Future<MovieLocal?> movieByRemoteId(String remoteId) => _isar.movieLocals
      .filter()
      .userIdEqualTo(_userId)
      .remoteIdEqualTo(remoteId)
      .findFirst();

  Future<MovieLocal> saveTrackerMovie({
    String? remoteId,
    required String title,
    required int priority,
    required String categoryRemoteId,
    String note = '',
    WatchStatus status = WatchStatus.wantToWatch,
  }) async {
    await ensureTrackerDefaults();
    MovieLocal m;
    if (remoteId != null) {
      m = (await movieByRemoteId(remoteId)) ??
          (throw StateError('Movie not found'));
    } else {
      m = MovieLocal()
        ..remoteId = const Uuid().v4()
        ..userId = _userId
        ..addedAt = DateTime.now()
        ..mediaType = 'manual'
        ..liked = false
        ..favorite = false
        ..userReview = '';
    }
    m
      ..title = title.trim()
      ..priority = priority.clamp(1, 5)
      ..categoryRemoteId = categoryRemoteId
      ..trackerNote = note
      ..watchStatus = status;
    if (status == WatchStatus.watched && m.watchedAt == null) {
      m.watchedAt = DateTime.now();
    }
    await _isar.writeTxn(() => _isar.movieLocals.put(m));
    return m;
  }

  Future<MovieLocal> markWatched(MovieLocal movie) async {
    movie.watchStatus = WatchStatus.watched;
    movie.watchedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.movieLocals.put(movie));
    return movie;
  }

  Future<MovieLocal> moveToWatchlist(MovieLocal movie) async {
    movie.watchStatus = WatchStatus.wantToWatch;
    movie.watchedAt = null;
    await _isar.writeTxn(() => _isar.movieLocals.put(movie));
    return movie;
  }

  Future<void> undoMarkWatched(MovieLocal movie) async {
    movie.watchStatus = WatchStatus.wantToWatch;
    movie.watchedAt = null;
    await _isar.writeTxn(() => _isar.movieLocals.put(movie));
  }
}

final tmdbServiceProvider = Provider((ref) => TmdbService());

final movieRepositoryProvider = FutureProvider<MovieRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  final repo = MovieRepository(
    isar,
    user.supabaseId ?? user.id.toString(),
    ref.watch(tmdbServiceProvider),
  );
  await repo.ensureTrackerDefaults();
  return repo;
});

final movieRefreshProvider = StateProvider<int>((ref) => 0);

void bumpMovieRefresh(WidgetRef ref) {
  ref.read(movieRefreshProvider.notifier).state++;
  scheduleCloudSyncFromWidget(ref);
}

String watchStatusLabel(WatchStatus s) => switch (s) {
      WatchStatus.wantToWatch => 'Watchlist',
      WatchStatus.watching => 'Watching',
      WatchStatus.watched => 'Watched',
    };
