import 'package:isar/isar.dart';

part 'habit_local.g.dart';

enum HabitKind { positive, negative, quantitative }

enum HabitInterval { daily, weekly, monthly, weekdays, everyXDays }

enum ScheduleUnit { days, weeks, months }

@collection
class HabitLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;

  late String name;
  late int colorValue;
  late String icon;

  @Enumerated(EnumType.name)
  late HabitKind kind;

  @Enumerated(EnumType.name)
  late HabitInterval interval;

  late int targetFrequency;
  late List<int> scheduleWeekdays;
  late int scheduleEvery;

  @Enumerated(EnumType.name)
  late ScheduleUnit scheduleUnit;

  late int targetPerDay;
  late double incrementAmount;
  late String unitLabel;
  late String description;

  /// Legacy field; mirrors [interval].name for sync.
  late String frequency;

  int? reminderMinute;
  late List<int> restDays;
  late String vacationsJson;
  late String remindersJson;
  late bool archived;
  late int sortOrder;
  late DateTime createdAt;

  /// Days of month when [interval] == monthly (e.g. [1, 15]).
  List<int> scheduleMonthDays = const [];

  /// Anchor for custom interval counting (YYYY-MM-DD); empty = use [createdAt].
  String scheduleStartDateKey = '';
}

enum HabitLogStatus { pending, completed, missed, excused }

@collection
class HabitLogLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;
  late String habitRemoteId;

  @Index(composite: [CompositeIndex('habitRemoteId')], unique: true, replace: true)
  late String dateKey;

  @Enumerated(EnumType.name)
  HabitLogStatus status = HabitLogStatus.pending;

  double? currentValue;
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
