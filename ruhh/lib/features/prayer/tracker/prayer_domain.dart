import 'package:ruhh/core/data/models/prayer_local.dart';

/// Domain model for pure calculations (Section 4).
class DailyPrayerLog {
  const DailyPrayerLog({
    required this.id,
    required this.dateKey,
    required this.statuses,
    this.isExcusedDay = false,
  });

  final String id;
  final String dateKey;
  final Map<PrayerName, TrackerPrayerStatus> statuses;
  final bool isExcusedDay;

  DailyPrayerLog copyWith({
    Map<PrayerName, TrackerPrayerStatus>? statuses,
    bool? isExcusedDay,
  }) {
    return DailyPrayerLog(
      id: id,
      dateKey: dateKey,
      statuses: statuses ?? this.statuses,
      isExcusedDay: isExcusedDay ?? this.isExcusedDay,
    );
  }
}

const prayerOrder = PrayerName.values;

Map<PrayerName, TrackerPrayerStatus> emptyStatuses() => {
      for (final p in prayerOrder) p: TrackerPrayerStatus.unmarked,
    };

DailyPrayerLog syntheticMissedDay(String dateKey, {String id = ''}) {
  return DailyPrayerLog(
    id: id,
    dateKey: dateKey,
    statuses: {
      for (final p in prayerOrder) p: TrackerPrayerStatus.missed,
    },
  );
}

DailyPrayerLog fromLocal(DailyPrayerLogLocal local) {
  return DailyPrayerLog(
    id: local.remoteId,
    dateKey: local.dateKey,
    isExcusedDay: local.isExcusedDay,
    statuses: {
      PrayerName.fajr: local.fajr,
      PrayerName.dhuhr: local.dhuhr,
      PrayerName.asr: local.asr,
      PrayerName.maghrib: local.maghrib,
      PrayerName.isha: local.isha,
    },
  );
}

void applyToLocal(DailyPrayerLog log, DailyPrayerLogLocal local) {
  local
    ..isExcusedDay = log.isExcusedDay
    ..fajr = log.statuses[PrayerName.fajr]!
    ..dhuhr = log.statuses[PrayerName.dhuhr]!
    ..asr = log.statuses[PrayerName.asr]!
    ..maghrib = log.statuses[PrayerName.maghrib]!
    ..isha = log.statuses[PrayerName.isha]!;
}

String dateKeyFrom(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
