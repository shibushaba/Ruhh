import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/prayer/aladhan_prayer_service.dart';
import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Maw9oot default sync coordinates (Algeria).
const maw9ootDefaultLat = 36.402482;
const maw9ootDefaultLng = 3.323412;

class PrayerRepository {
  PrayerRepository(this._isar, this._userId);

  final Isar _isar;
  final String _userId;

  String get _latKey => 'prayer_lat_$_userId';
  String get _lngKey => 'prayer_lng_$_userId';
  String get _pointsKey => 'prayer_points_$_userId';
  String get _streakKey => 'prayer_streak_$_userId';
  String get _groupKey => 'prayer_group_pct_$_userId';
  String get _dailyReminderKey => 'prayer_daily_reminder_$_userId';
  String get _dailyTimeKey => 'prayer_daily_time_$_userId';
  String get _postPrayerKey => 'prayer_post_reminder_$_userId';
  String get _postDelayKey => 'prayer_post_delay_$_userId';

  Future<void> saveLocation(double lat, double lng) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_latKey, lat);
    await p.setDouble(_lngKey, lng);
  }

  Future<(double, double)> location() async {
    final p = await SharedPreferences.getInstance();
    return (
      p.getDouble(_latKey) ?? maw9ootDefaultLat,
      p.getDouble(_lngKey) ?? maw9ootDefaultLng,
    );
  }

  Future<int> syncPrayerTimes({int? year}) async {
    final (lat, lng) = await location();
    final y = year ?? DateTime.now().year;
    return AladhanPrayerService.syncYear(
      isar: _isar,
      userId: _userId,
      latitude: lat,
      longitude: lng,
      year: y,
    );
  }

  Future<bool> hasSyncedTimes() async {
    final count = await _isar.prayerTimeLocals
        .filter()
        .userIdEqualTo(_userId)
        .count();
    return count > 0;
  }

  Future<Map<PrayerName, String>> displayTimesForDay(DateTime day) async {
    final d = _dayOnly(day);
    final stored = await _isar.prayerTimeLocals
        .filter()
        .userIdEqualTo(_userId)
        .dayEqualTo(d)
        .findAll();
    if (stored.length >= 5) {
      return {for (final t in stored) t.prayer: t.time};
    }
    final adhan = await timesFor(day);
    final fmt = DateFormat('HH:mm');
    return {
      PrayerName.fajr: fmt.format(adhan.fajr),
      PrayerName.dhuhr: fmt.format(adhan.dhuhr),
      PrayerName.asr: fmt.format(adhan.asr),
      PrayerName.maghrib: fmt.format(adhan.maghrib),
      PrayerName.isha: fmt.format(adhan.isha),
    };
  }

  Future<PrayerTimes> timesFor(DateTime day) async {
    final (lat, lng) = await location();
    final coords = Coordinates(lat, lng);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes(coords, DateComponents.from(day), params);
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
    final oldStatus = existing?.status ?? PrayerStatus.none;

    final log = existing ??
        (PrayerLogLocal()
          ..remoteId = const Uuid().v4()
          ..userId = _userId
          ..day = d
          ..prayer = prayer);
    log.status = status;
    await _isar.writeTxn(() => _isar.prayerLogLocals.put(log));

    await _applyPointsDelta(oldStatus, status);
    await _recalculateMetrics();
  }

  int _pointsDelta(PrayerStatus status) => switch (status) {
        PrayerStatus.withGroup => 2,
        PrayerStatus.onTimeAlone => 1,
        PrayerStatus.lateAlone => -2,
        PrayerStatus.missed => -4,
        PrayerStatus.qadha => 0,
        PrayerStatus.none => 0,
      };

  Future<void> _applyPointsDelta(
    PrayerStatus oldStatus,
    PrayerStatus newStatus,
  ) async {
    final p = await SharedPreferences.getInstance();
    var points = p.getInt(_pointsKey) ?? 0;
    points -= _pointsDelta(oldStatus);
    points += _pointsDelta(newStatus);
    await p.setInt(_pointsKey, points);
  }

  Future<void> _recalculateMetrics() async {
    final p = await SharedPreferences.getInstance();
    final streak = await calculateStreak();
    final groupPct = await groupPercentage();
    await p.setInt(_streakKey, streak);
    await p.setInt(_groupKey, groupPct);
  }

  Future<int> calculateStreak() async {
    var streak = 0;
    var current = _dayOnly(DateTime.now());
    while (await _isValidStreakDay(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<bool> _isValidStreakDay(DateTime day) async {
    final logs = await logsForDay(day);
    for (final p in PrayerName.values) {
      final s = logs[p]?.status ?? PrayerStatus.none;
      if (s != PrayerStatus.withGroup && s != PrayerStatus.onTimeAlone) {
        return false;
      }
    }
    return true;
  }

  Future<int> groupPercentage() async {
    final all = await _isar.prayerLogLocals
        .filter()
        .userIdEqualTo(_userId)
        .findAll();
    if (all.isEmpty) return 0;
    final group =
        all.where((l) => l.status == PrayerStatus.withGroup).length;
    return ((group / all.length) * 100).round();
  }

  Future<int> points() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_pointsKey) ?? 0;
  }

  Future<int> streak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_streakKey) ?? 0;
  }

  Future<int> groupPercent() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_groupKey) ?? 0;
  }

  Future<Map<PrayerName, bool>> dailyChallengeFor(DateTime day) async {
    final logs = await logsForDay(day);
    return {
      for (final p in PrayerName.values)
        p: _challengeSuccess(logs[p]?.status ?? PrayerStatus.none),
    };
  }

  bool _challengeSuccess(PrayerStatus s) =>
      s == PrayerStatus.withGroup || s == PrayerStatus.onTimeAlone;

  Future<Map<int, PrayerStatus>> weeklyFajrChallenge(DateTime anchor) async {
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    final map = <int, PrayerStatus>{};
    for (var i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final logs = await logsForDay(d);
      map[i] = logs[PrayerName.fajr]?.status ?? PrayerStatus.none;
    }
    return map;
  }

  Future<List<List<PrayerLogLocal>>> logsGridForMonth(int year, int month) async {
    final daysInMonth =
        DateTime(year, month + 1, 1).subtract(const Duration(days: 1)).day;
    final logs = await logsInMonth(year, month);
    final byDay = <int, List<PrayerLogLocal>>{};
    for (final l in logs) {
      byDay.putIfAbsent(l.day.day, () => []).add(l);
    }
    return List.generate(
      daysInMonth,
      (i) => byDay[i + 1] ?? [],
    );
  }

  Future<PrayerName?> nextPending({DateTime? day}) async {
    final target = day ?? DateTime.now();
    final logs = await logsForDay(target);
    final ordered = PrayerName.values;
    final now = DateTime.now();
    for (final p in ordered) {
      final status = logs[p]?.status ?? PrayerStatus.none;
      if (_challengeSuccess(status) ||
          status == PrayerStatus.lateAlone ||
          status == PrayerStatus.missed) {
        continue;
      }
      if (_dayOnly(target).isBefore(_dayOnly(now)) || p == PrayerName.fajr) {
        return p;
      }
    }
    return PrayerName.fajr;
  }

  Future<int> missedCount() async {
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

  // Settings prefs
  Future<bool> dailyReminderEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_dailyReminderKey) ??
      false;

  Future<void> setDailyReminderEnabled(bool v) async {
    await (await SharedPreferences.getInstance()).setBool(_dailyReminderKey, v);
  }

  Future<String> dailyReminderTime() async =>
      (await SharedPreferences.getInstance()).getString(_dailyTimeKey) ??
      '00:00';

  Future<void> setDailyReminderTime(String hhmm) async {
    await (await SharedPreferences.getInstance()).setString(_dailyTimeKey, hhmm);
  }

  Future<bool> postPrayerReminderEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_postPrayerKey) ?? false;

  Future<void> setPostPrayerReminderEnabled(bool v) async {
    await (await SharedPreferences.getInstance()).setBool(_postPrayerKey, v);
  }

  Future<int> postPrayerDelayMinutes() async =>
      int.tryParse(
            (await SharedPreferences.getInstance()).getString(_postDelayKey) ??
                '15',
          ) ??
          15;

  Future<void> setPostPrayerDelayMinutes(int minutes) async {
    await (await SharedPreferences.getInstance())
        .setString(_postDelayKey, '$minutes');
  }

  static DateTime _dayOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static String label(PrayerName p) => switch (p) {
        PrayerName.fajr => 'Fajr',
        PrayerName.dhuhr => 'Dhuhr',
        PrayerName.asr => 'Asr',
        PrayerName.maghrib => 'Maghrib',
        PrayerName.isha => 'Isha',
      };

  /// Maw9oot [PrayerStatus.displayName] strings.
  static String statusLabel(PrayerStatus s) => switch (s) {
        PrayerStatus.none => 'None',
        PrayerStatus.missed => 'Missed',
        PrayerStatus.lateAlone => 'Late Alone',
        PrayerStatus.withGroup => 'With Group',
        PrayerStatus.onTimeAlone => 'On Time Alone',
        PrayerStatus.qadha => 'Qadha',
      };

  /// Statuses shown in the home bottom sheet (Maw9oot order, no None).
  static const sheetStatuses = [
    PrayerStatus.missed,
    PrayerStatus.lateAlone,
    PrayerStatus.withGroup,
    PrayerStatus.onTimeAlone,
  ];

  /// Maw9oot badge / grid colors.
  static Color statusColor(PrayerStatus s) => switch (s) {
        PrayerStatus.missed => const Color(0xFFf14143),
        PrayerStatus.lateAlone => const Color(0xFFFF5722),
        PrayerStatus.withGroup => const Color(0xFF13B601),
        PrayerStatus.onTimeAlone => const Color(0xFF1EB4EB),
        PrayerStatus.qadha => const Color(0xFFA855F7),
        PrayerStatus.none => const Color(0xFFf2eeff),
      };

  /// Right-column tint on home prayer rows (Maw9oot PrayerButton).
  static Color statusRowTint(PrayerStatus s) => switch (s) {
        PrayerStatus.missed => const Color(0xFFffe5e5),
        PrayerStatus.lateAlone => const Color(0xFFfff1eb),
        PrayerStatus.withGroup => const Color(0xFFe5f4d9),
        PrayerStatus.onTimeAlone => const Color(0xFFdff8ff),
        PrayerStatus.qadha => const Color(0xFFf3e8ff),
        PrayerStatus.none => const Color(0xFFf2eeff),
      };

  /// Prayer name accent (Maw9oot Prayer enum).
  static Color prayerAccent(PrayerName p) => switch (p) {
        PrayerName.fajr => const Color(0xFFd3f8e2),
        PrayerName.dhuhr => const Color(0xFFe4c1f9),
        PrayerName.asr => const Color(0xFFf694c1),
        PrayerName.maghrib => const Color(0xFFede7b1),
        PrayerName.isha => const Color(0xFFa9def9),
      };

  static IconData statusIcon(PrayerStatus s) => switch (s) {
        PrayerStatus.missed => Icons.cancel_outlined,
        PrayerStatus.lateAlone => Icons.schedule,
        PrayerStatus.withGroup => Icons.groups_outlined,
        PrayerStatus.onTimeAlone => Icons.person_outline,
        PrayerStatus.qadha => Icons.replay,
        PrayerStatus.none => Icons.circle_outlined,
      };

  static IconData prayerIcon(PrayerName p) => switch (p) {
        PrayerName.fajr => Icons.wb_twilight,
        PrayerName.dhuhr => Icons.wb_sunny_outlined,
        PrayerName.asr => Icons.wb_cloudy,
        PrayerName.maghrib => Icons.wb_twilight_outlined,
        PrayerName.isha => Icons.nights_stay_outlined,
      };

  /// Stats grid cell colors (Maw9oot PrayerGrid.getStatusColor).
  static Color gridColor(PrayerStatus s) {
    if (s == PrayerStatus.none) return Colors.grey;
    if (s == PrayerStatus.lateAlone) return const Color(0xFFfe7838);
    if (s == PrayerStatus.missed) return const Color(0xFFf44336);
    if (s == PrayerStatus.withGroup) return const Color(0xFF13b601);
    if (s == PrayerStatus.onTimeAlone) return const Color(0xFF1eb4eb);
    return Colors.grey;
  }

  // --- Daily tracker (Section 4–6) ---

  String get todayKey => dateKeyFrom(DateTime.now());

  Stream<void> watchDailyTracker() {
    return _isar.dailyPrayerLogLocals
        .watchLazy(fireImmediately: false)
        .map((_) {});
  }

  Future<void> ensureTodayLog() async {
    await _ensureLocal(todayKey);
  }

  Future<Map<String, DailyPrayerLog>> allDailyLogsMap() async {
    final locals = await _isar.dailyPrayerLogLocals
        .filter()
        .userIdEqualTo(_userId)
        .findAll();
    return {
      for (final l in locals) l.dateKey: finalizePastDay(fromLocal(l), todayKey: todayKey),
    };
  }

  Future<DailyPrayerLog> dailyLogFor(String dateKey) async {
    final local = await _localFor(dateKey);
    if (local == null) {
      if (dateKey.compareTo(todayKey) < 0) {
        return syntheticMissedDay(dateKey);
      }
      final ensured = await _ensureLocal(dateKey);
      return fromLocal(ensured);
    }
    return finalizePastDay(fromLocal(local), todayKey: todayKey);
  }

  /// Next salāh to highlight: latest unlogged whose adhan has passed, else next upcoming.
  Future<PrayerName?> nextUnloggedPrayerByTime({DateTime? now}) async {
    final clock = now ?? DateTime.now();
    final day = _dayOnly(clock);
    final log = await dailyLogFor(todayKey);
    final times = await displayTimesForDay(day);

    PrayerName? latestPassedUnmarked;
    PrayerName? firstFutureUnmarked;

    for (final p in prayerOrder) {
      if (log.statuses[p] == TrackerPrayerStatus.prayed) continue;
      final hhmm = times[p];
      if (hhmm == null || hhmm.length < 4) continue;
      final parts = hhmm.split(':');
      if (parts.length < 2) continue;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) continue;
      final at = DateTime(day.year, day.month, day.day, h, m);
      if (!at.isAfter(clock)) {
        latestPassedUnmarked = p;
      } else if (firstFutureUnmarked == null) {
        firstFutureUnmarked = p;
      }
    }

    return latestPassedUnmarked ?? firstFutureUnmarked;
  }

  Future<DailyPrayerLog> toggleTrackerPrayer(
    String dateKey,
    PrayerName prayer,
  ) async {
    final local = await _ensureLocal(dateKey);
    var log = finalizePastDay(fromLocal(local), todayKey: todayKey);
    final isToday = dateKey == todayKey;
    var status = log.statuses[prayer]!;
    if (isToday) {
      status = status == TrackerPrayerStatus.prayed
          ? TrackerPrayerStatus.unmarked
          : TrackerPrayerStatus.prayed;
    } else {
      status = status == TrackerPrayerStatus.prayed
          ? TrackerPrayerStatus.missed
          : TrackerPrayerStatus.prayed;
    }
    final next = Map<PrayerName, TrackerPrayerStatus>.from(log.statuses)
      ..[prayer] = status;
    log = log.copyWith(statuses: next);
    applyToLocal(log, local);
    await _isar.writeTxn(() => _isar.dailyPrayerLogLocals.put(local));
    return finalizePastDay(log, todayKey: todayKey);
  }

  Future<DailyPrayerLog> setExcusedDay(String dateKey, bool excused) async {
    final local = await _ensureLocal(dateKey);
    var log = fromLocal(local).copyWith(isExcusedDay: excused);
    applyToLocal(log, local);
    await _isar.writeTxn(() => _isar.dailyPrayerLogLocals.put(local));
    return finalizePastDay(log, todayKey: todayKey);
  }

  Future<DailyPrayerLogLocal> _ensureLocal(String dateKey) async {
    final existing = await _localFor(dateKey);
    if (existing != null) return existing;

    return _isar.writeTxn(() async {
      final again = await _isar.dailyPrayerLogLocals
          .filter()
          .userIdEqualTo(_userId)
          .dateKeyEqualTo(dateKey)
          .findFirst();
      if (again != null) return again;

      final legacy = await logsForDay(parseDateKey(dateKey));
      if (legacy.isNotEmpty) {
        final statuses = emptyStatuses();
        for (final p in prayerOrder) {
          final s = legacy[p]?.status ?? PrayerStatus.none;
          statuses[p] = switch (s) {
            PrayerStatus.withGroup ||
            PrayerStatus.onTimeAlone ||
            PrayerStatus.lateAlone ||
            PrayerStatus.qadha =>
              TrackerPrayerStatus.prayed,
            PrayerStatus.missed => TrackerPrayerStatus.missed,
            PrayerStatus.none => TrackerPrayerStatus.unmarked,
          };
        }
        final local = DailyPrayerLogLocal()
          ..remoteId = const Uuid().v4()
          ..userId = _userId
          ..dateKey = dateKey;
        applyToLocal(
          DailyPrayerLog(
            id: local.remoteId,
            dateKey: dateKey,
            statuses: statuses,
          ),
          local,
        );
        await _isar.dailyPrayerLogLocals.put(local);
        return local;
      }

      final local = DailyPrayerLogLocal()
        ..remoteId = const Uuid().v4()
        ..userId = _userId
        ..dateKey = dateKey
        ..isExcusedDay = false;
      for (final p in prayerOrder) {
        _setTrackerStatus(local, p, TrackerPrayerStatus.unmarked);
      }
      await _isar.dailyPrayerLogLocals.put(local);
      return local;
    });
  }

  Future<DailyPrayerLogLocal?> _localFor(String dateKey) =>
      _isar.dailyPrayerLogLocals
          .filter()
          .userIdEqualTo(_userId)
          .dateKeyEqualTo(dateKey)
          .findFirst();

  void _setTrackerStatus(
    DailyPrayerLogLocal local,
    PrayerName prayer,
    TrackerPrayerStatus status,
  ) {
    switch (prayer) {
      case PrayerName.fajr:
        local.fajr = status;
      case PrayerName.dhuhr:
        local.dhuhr = status;
      case PrayerName.asr:
        local.asr = status;
      case PrayerName.maghrib:
        local.maghrib = status;
      case PrayerName.isha:
        local.isha = status;
    }
  }

  PrayerSummary computeSummary(Map<String, DailyPrayerLog> logs) {
    return PrayerSummary(
      currentStreak: currentStreak(logs, todayKey),
      longestStreak: longestStreak(logs, todayKey),
    );
  }
}

class PrayerSummary {
  const PrayerSummary({
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;
}

final prayerRepositoryProvider = FutureProvider<PrayerRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  final repo = PrayerRepository(isar, user.supabaseId ?? user.id.toString());
  await repo.ensureTodayLog();
  return repo;
});

final dailyPrayerLogsProvider = StreamProvider<Map<String, DailyPrayerLog>>((ref) async* {
  ref.watch(prayerRefreshProvider);
  final repo = await ref.watch(prayerRepositoryProvider.future);
  yield await repo.allDailyLogsMap();
  await for (final _ in repo.watchDailyTracker()) {
    yield await repo.allDailyLogsMap();
  }
});

final prayerRefreshProvider = StateProvider<int>((ref) => 0);

void bumpPrayerRefresh(WidgetRef ref) {
  ref.read(prayerRefreshProvider.notifier).state++;
  scheduleCloudSyncFromWidget(ref);
}
