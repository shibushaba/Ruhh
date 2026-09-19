import 'package:isar/isar.dart';

part 'prayer_local.g.dart';

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

enum PrayerStatus { none, missed, lateAlone, withGroup, onTimeAlone, qadha }

/// Simple daily tracker statuses (Section 4).
enum TrackerPrayerStatus { unmarked, prayed, missed, excused }

@collection
class PrayerLogLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;
  late DateTime day;

  @Enumerated(EnumType.name)
  late PrayerName prayer;

  @Enumerated(EnumType.name)
  late PrayerStatus status;
}

@collection
class PrayerTimeLocal {
  Id id = Isar.autoIncrement;

  late String userId;
  late DateTime day;

  @Enumerated(EnumType.name)
  late PrayerName prayer;

  /// Display time HH:mm (from Aladhan or adhan fallback).
  late String time;

  String? hijriDate;
}

@collection
class DailyPrayerLogLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;

  /// YYYY-MM-DD
  @Index(composite: [CompositeIndex('userId')], unique: true, replace: true)
  late String dateKey;

  bool isExcusedDay = false;

  @Enumerated(EnumType.name)
  TrackerPrayerStatus fajr = TrackerPrayerStatus.unmarked;

  @Enumerated(EnumType.name)
  TrackerPrayerStatus dhuhr = TrackerPrayerStatus.unmarked;

  @Enumerated(EnumType.name)
  TrackerPrayerStatus asr = TrackerPrayerStatus.unmarked;

  @Enumerated(EnumType.name)
  TrackerPrayerStatus maghrib = TrackerPrayerStatus.unmarked;

  @Enumerated(EnumType.name)
  TrackerPrayerStatus isha = TrackerPrayerStatus.unmarked;
}
