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

  @Enumerated(EnumType.name)
  late WatchStatus watchStatus;

  late String mediaType;
  String? overview;
  late DateTime addedAt;
}
