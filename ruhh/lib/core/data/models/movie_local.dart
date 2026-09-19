import 'package:isar/isar.dart';

part 'movie_local.g.dart';

enum WatchStatus { wantToWatch, watching, watched }

@collection
class MovieLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;

  int? tmdbId;
  late String title;
  String? posterPath;
  String? backdropPath;

  @Enumerated(EnumType.name)
  late WatchStatus watchStatus;

  late String mediaType;
  String? overview;
  String? releaseDate;
  double? voteAverage;
  double? userRating;
  late String userReview;
  late bool liked;
  late bool favorite;
  DateTime? watchedAt;
  late DateTime addedAt;

  /// 1–5 watch priority (5 = highest). Section 4.
  int priority = 3;

  String categoryRemoteId = '';

  /// Tracker note (separate from TMDB review text when used).
  String trackerNote = '';
}
