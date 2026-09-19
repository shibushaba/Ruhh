import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/features/movie/tracker/movie_sort.dart';

MovieLocal _m({
  required String id,
  required int priority,
  required DateTime addedAt,
  DateTime? watchedAt,
  WatchStatus status = WatchStatus.wantToWatch,
}) {
  return MovieLocal()
    ..remoteId = id
    ..userId = 'u'
    ..title = id
    ..mediaType = 'movie'
    ..watchStatus = status
    ..userReview = ''
    ..trackerNote = ''
    ..liked = false
    ..favorite = false
    ..addedAt = addedAt
    ..watchedAt = watchedAt
    ..priority = priority
    ..categoryRemoteId = 'cat';
}

void main() {
  test('watchlist sorts by priority desc then addedAt desc', () {
    final sorted = sortWatchlistMovies([
      _m(id: 'a', priority: 3, addedAt: DateTime(2024, 1, 1)),
      _m(id: 'b', priority: 5, addedAt: DateTime(2023, 1, 1)),
      _m(id: 'c', priority: 5, addedAt: DateTime(2024, 6, 1)),
      _m(id: 'd', priority: 2, addedAt: DateTime(2025, 1, 1)),
    ]);
    expect(sorted.map((m) => m.remoteId).toList(), ['c', 'b', 'a', 'd']);
  });

  test('watched sorts by watchedAt desc', () {
    final sorted = sortWatchedMovies([
      _m(
        id: 'old',
        priority: 3,
        addedAt: DateTime(2020),
        watchedAt: DateTime(2024, 1, 1),
        status: WatchStatus.watched,
      ),
      _m(
        id: 'new',
        priority: 1,
        addedAt: DateTime(2020),
        watchedAt: DateTime(2024, 6, 1),
        status: WatchStatus.watched,
      ),
    ]);
    expect(sorted.first.remoteId, 'new');
  });
}
