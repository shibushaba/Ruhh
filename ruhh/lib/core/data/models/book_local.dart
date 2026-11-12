import 'package:isar/isar.dart';

part 'book_local.g.dart';

enum BookStatus { wantToRead, reading, read }

@collection
class BookLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;

  /// Open Library work key, e.g. `/works/OL17930368W`.
  String? openLibraryKey;
  late String title;
  String? author;
  String? coverUrl;
  int? firstPublishYear;
  String? description;

  @Enumerated(EnumType.name)
  late BookStatus status;

  /// Pages read (progress). Null means unset.
  int? pageCount;

  double? userRating;
  String note = '';
  DateTime? finishedAt;
  late DateTime addedAt;
}
