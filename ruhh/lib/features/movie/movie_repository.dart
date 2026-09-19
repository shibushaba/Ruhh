import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/movie/tmdb_service.dart';
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
          ..addedAt = DateTime.now());
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

  Future<MovieLocal> addManual({
    required String title,
    required WatchStatus status,
    String mediaType = 'movie',
  }) async {
    final m = MovieLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..title = title
      ..mediaType = mediaType
      ..watchStatus = status
      ..userReview = ''
      ..liked = false
      ..favorite = false
      ..addedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.movieLocals.put(m));
    return m;
  }
}

final tmdbServiceProvider = Provider((ref) => TmdbService());

final movieRepositoryProvider = FutureProvider<MovieRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  return MovieRepository(
    isar,
    user.supabaseId ?? user.id.toString(),
    ref.watch(tmdbServiceProvider),
  );
});

final movieRefreshProvider = StateProvider<int>((ref) => 0);

void bumpMovieRefresh(WidgetRef ref) {
  ref.read(movieRefreshProvider.notifier).state++;
}

String watchStatusLabel(WatchStatus s) => switch (s) {
      WatchStatus.wantToWatch => 'Watchlist',
      WatchStatus.watching => 'Watching',
      WatchStatus.watched => 'Watched',
    };
