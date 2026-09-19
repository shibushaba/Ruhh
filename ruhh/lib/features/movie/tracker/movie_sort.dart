import 'package:ruhh/core/data/models/movie_local.dart';

bool isMovieWatchlist(MovieLocal m) =>
    m.watchStatus == WatchStatus.wantToWatch ||
    m.watchStatus == WatchStatus.watching;

bool isMovieWatched(MovieLocal m) => m.watchStatus == WatchStatus.watched;

/// Watchlist: priority desc, then dateAdded desc.
List<MovieLocal> sortWatchlistMovies(List<MovieLocal> movies) {
  final list = List<MovieLocal>.from(movies);
  list.sort((a, b) {
    final byPriority = b.priority.compareTo(a.priority);
    if (byPriority != 0) return byPriority;
    return b.addedAt.compareTo(a.addedAt);
  });
  return list;
}

/// Watched: dateWatched desc (uses [MovieLocal.watchedAt]).
List<MovieLocal> sortWatchedMovies(List<MovieLocal> movies) {
  final list = List<MovieLocal>.from(movies);
  list.sort((a, b) {
    final aw = a.watchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bw = b.watchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bw.compareTo(aw);
  });
  return list;
}

List<MovieLocal> filterMoviesByCategory(
  List<MovieLocal> movies,
  String? categoryRemoteId,
) {
  if (categoryRemoteId == null || categoryRemoteId.isEmpty) return movies;
  return movies
      .where((m) => m.categoryRemoteId == categoryRemoteId)
      .toList(growable: false);
}
