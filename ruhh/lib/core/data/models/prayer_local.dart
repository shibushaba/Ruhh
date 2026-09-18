import 'package:isar/isar.dart';

part 'prayer_local.g.dart';

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

enum PrayerStatus { none, missed, lateAlone, withGroup, onTimeAlone, qadha }

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
