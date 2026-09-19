import 'package:isar/isar.dart';

part 'todo_local.g.dart';

enum TodoPriority { none, low, medium, high }

@collection
class TodoLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;
  late String text;
  late bool done;

  /// yyyy-MM-dd or empty for someday
  late String dateKey;
  int? minutesOfDay;
  @Enumerated(EnumType.name)
  late TodoPriority priority;
  late DateTime createdAt;
  DateTime? doneAt;
}
