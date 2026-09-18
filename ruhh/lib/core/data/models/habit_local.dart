import 'package:isar/isar.dart';

part 'habit_local.g.dart';

@collection
class HabitLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;

  late String name;
  late int colorValue;
  late String frequency;
  late int targetPerDay;
  int? reminderMinute;
  late bool archived;
  late DateTime createdAt;
}

@collection
class HabitCompletionLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String habitRemoteId;
  late String userId;
  late DateTime day;
  late double value;
}
