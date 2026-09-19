import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';

/// Aladhan calendar API (Maw9oot method 4).
class AladhanPrayerService {
  static const _base = 'https://api.aladhan.com/v1';

  static Future<int> syncYear({
    required Isar isar,
    required String userId,
    required double latitude,
    required double longitude,
    required int year,
  }) async {
    final uri = Uri.parse(
      '$_base/calendar/$year?latitude=$latitude&longitude=$longitude&method=4',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Aladhan sync failed (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    var count = 0;

    await isar.writeTxn(() async {
      final existing = await isar.prayerTimeLocals
          .filter()
          .userIdEqualTo(userId)
          .findAll();
      for (final e in existing) {
        if (e.day.year == year) {
          await isar.prayerTimeLocals.delete(e.id);
        }
      }

      for (final monthList in data.values) {
        if (monthList is! List) continue;
        for (final dayEntry in monthList) {
          final m = dayEntry as Map<String, dynamic>;
          final greg = (m['date'] as Map)['gregorian'] as Map;
          final hijri = (m['date'] as Map)['hijri'] as Map;
          final gregDate = greg['date'] as String; // dd-MM-yyyy
          final parts = gregDate.split('-');
          final day = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          final timings = m['timings'] as Map<String, dynamic>;
          final hijriStr = hijri['date'] as String?;

          for (final entry in _timingKeys.entries) {
            final raw = timings[entry.key] as String? ?? '';
            final time = raw.length >= 5 ? raw.substring(0, 5) : raw;
            await isar.prayerTimeLocals.put(
              PrayerTimeLocal()
                ..userId = userId
                ..day = day
                ..prayer = entry.value
                ..time = time
                ..hijriDate = hijriStr,
            );
            count++;
          }
        }
      }
    });
    return count;
  }

  static const _timingKeys = {
    'Fajr': PrayerName.fajr,
    'Dhuhr': PrayerName.dhuhr,
    'Asr': PrayerName.asr,
    'Maghrib': PrayerName.maghrib,
    'Isha': PrayerName.isha,
  };
}
