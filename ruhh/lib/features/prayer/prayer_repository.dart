import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PrayerRepository {
  PrayerRepository(this._isar, this._userId);

  final Isar _isar;
  final String _userId;

  static const _latKey = 'prayer_lat';
  static const _lngKey = 'prayer_lng';
  static const _pointsKey = 'prayer_points';
  static const _streakKey = 'prayer_streak';

  Future<void> saveLocation(double lat, double lng) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_latKey, lat);
    await p.setDouble(_lngKey, lng);
  }

  Future<Coordinates> coordinates() async {
    final p = await SharedPreferences.getInstance();
    final lat = p.getDouble(_latKey) ?? 21.4225;
    final lng = p.getDouble(_lngKey) ?? 39.8262;
    return Coordinates(lat, lng);
  }

  Future<PrayerTimes> timesFor(DateTime day) async {
    final coords = await coordinates();
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes(
      coords,
      DateComponents.from(day),
      params,
    );
  }

  Future<Map<PrayerName, PrayerLogLocal>> logsForDay(DateTime day) async {
    final d = _dayOnly(day);
    final logs = await _isar.prayerLogLocals
        .filter()
        .userIdEqualTo(_userId)
        .dayEqualTo(d)
        .findAll();
    return {for (final l in logs) l.prayer: l};
  }

  Future<void> setStatus(
    PrayerName prayer,
    PrayerStatus status, {
    DateTime? day,
  }) async {
    final d = _dayOnly(day ?? DateTime.now());
    final existing = await _isar.prayerLogLocals
        .filter()
        .userIdEqualTo(_userId)
        .dayEqualTo(d)
        .prayerEqualTo(prayer)
        .findFirst();
    final log = existing ??
        (PrayerLogLocal()
          ..remoteId = const Uuid().v4()
          ..userId = _userId
          ..day = d
          ..prayer = prayer);
    log.status = status;
    await _isar.writeTxn(() => _isar.prayerLogLocals.put(log));

    if (_dayOnly(d) == _dayOnly(DateTime.now())) {
      await _applyPoints(status);
    }
  }

  Future<void> _applyPoints(PrayerStatus status) async {
    final p = await SharedPreferences.getInstance();
    var points = p.getInt(_pointsKey) ?? 0;
    points += switch (status) {
      PrayerStatus.withGroup => 2,
      PrayerStatus.onTimeAlone => 1,
      PrayerStatus.lateAlone => -2,
      PrayerStatus.missed => -4,
      PrayerStatus.qadha => 0,
      PrayerStatus.none => 0,
    };
    await p.setInt(_pointsKey, points);
  }

  Future<int> points() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_pointsKey) ?? 0;
  }

  Future<int> streak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_streakKey) ?? 0;
  }

  Future<PrayerName?> nextPending({DateTime? day}) async {
    final target = day ?? DateTime.now();
    final times = await timesFor(target);
    final logs = await logsForDay(target);
    final ordered = [
      (PrayerName.fajr, times.fajr),
      (PrayerName.dhuhr, times.dhuhr),
      (PrayerName.asr, times.asr),
      (PrayerName.maghrib, times.maghrib),
      (PrayerName.isha, times.isha),
    ];
    final now = DateTime.now();
    for (final entry in ordered) {
      final status = logs[entry.$1]?.status ?? PrayerStatus.none;
      if (_isCompleted(status)) continue;
      if (_dayOnly(target).isBefore(_dayOnly(now)) ||
          now.isAfter(entry.$2) ||
          entry.$1 == PrayerName.fajr) {
        return entry.$1;
      }
    }
    return PrayerName.fajr;
  }

  Future<int> qadhaCount() async {
    return _isar.prayerLogLocals
        .filter()
        .userIdEqualTo(_userId)
        .statusEqualTo(PrayerStatus.missed)
        .count();
  }

  Future<List<PrayerLogLocal>> logsInMonth(int year, int month) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return _isar.prayerLogLocals
        .filter()
        .userIdEqualTo(_userId)
        .dayGreaterThan(start.subtract(const Duration(days: 1)))
        .dayLessThan(end)
        .findAll();
  }

  static bool _isCompleted(PrayerStatus s) =>
      s == PrayerStatus.onTimeAlone ||
      s == PrayerStatus.withGroup ||
      s == PrayerStatus.qadha ||
      s == PrayerStatus.lateAlone;

  static DateTime _dayOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static String label(PrayerName p) => switch (p) {
        PrayerName.fajr => 'Fajr',
        PrayerName.dhuhr => 'Dhuhr',
        PrayerName.asr => 'Asr',
        PrayerName.maghrib => 'Maghrib',
        PrayerName.isha => 'Isha',
      };

  static String statusLabel(PrayerStatus s) => switch (s) {
        PrayerStatus.none => 'Not logged',
        PrayerStatus.missed => 'Missed',
        PrayerStatus.lateAlone => 'Late alone',
        PrayerStatus.withGroup => 'With group',
        PrayerStatus.onTimeAlone => 'On time alone',
        PrayerStatus.qadha => 'Qadha',
      };

  static Color statusColor(PrayerStatus s) => switch (s) {
        PrayerStatus.missed => const Color(0xFFEF4444),
        PrayerStatus.lateAlone => const Color(0xFFF97316),
        PrayerStatus.withGroup => const Color(0xFF22C55E),
        PrayerStatus.onTimeAlone => const Color(0xFF14B8A6),
        PrayerStatus.qadha => const Color(0xFFA855F7),
        PrayerStatus.none => const Color(0xFF9CA3AF),
      };
}

final prayerRepositoryProvider = FutureProvider<PrayerRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  return PrayerRepository(isar, user.supabaseId ?? user.id.toString());
});
