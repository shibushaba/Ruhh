import 'package:isar/isar.dart';

part 'movie_category_local.g.dart';

@collection
class MovieCategoryLocal {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String userId;
  late String name;
  late int colorValue;
  bool isCustom = false;
  bool isArchived = false;
  late int sortOrder;
}
