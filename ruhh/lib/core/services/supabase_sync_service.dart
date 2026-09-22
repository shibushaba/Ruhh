import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/data/models/focus_session_local.dart';
import 'package:ruhh/core/data/models/movie_category_local.dart';
import 'package:ruhh/core/data/models/todo_local.dart';
import 'package:ruhh/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/budget/widgets/category_display.dart';
import 'package:ruhh/features/budget/ledger/budget_category_ids.dart';
import 'package:ruhh/features/budget/ledger/budget_month_key.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:uuid/uuid.dart';

/// Postgres `int` is signed 32-bit; Flutter [Color.value] is unsigned 32-bit ARGB.
const _kSignedInt32Max = 2147483647;
const _kUnsigned32Range = 4294967296;

int _colorValueForCloudSync(int colorValue) {
  if (colorValue <= _kSignedInt32Max) return colorValue;
  return colorValue - _kUnsigned32Range;
}

int _colorValueFromCloudSync(num? value, {int fallback = 0}) {
  if (value == null) return fallback;
  final v = value.toInt();
  if (v < 0) return v + _kUnsigned32Range;
  return v;
}

/// Outcome of [SupabaseSyncService.syncUser] (login restore + background sync).
class SyncUserResult {
  const SyncUserResult({
    required this.restoredEntityCount,
    required this.startedWithEmptyLocal,
    this.pullFailed = false,
    this.noCloudBackup = false,
  });

  final int restoredEntityCount;
  final bool startedWithEmptyLocal;
  final bool pullFailed;
  final bool noCloudBackup;

  bool get restoredFromCloud => restoredEntityCount > 0;
}

class CloudSyncPullFailedException implements Exception {
  CloudSyncPullFailedException([this.message = 'Could not download cloud backup']);

  final String message;

  @override
  String toString() => message;
}

class SupabaseSyncService {
  SupabaseSyncService(this._isar);

  final Isar _isar;

  Future<SyncUserResult> syncUser(UserLocal user, String pinHash) async {
    final userId = user.supabaseId;
    if (userId == null || userId.isEmpty) {
      return const SyncUserResult(
        restoredEntityCount: 0,
        startedWithEmptyLocal: false,
      );
    }

    await _migrateLegacyUserIds(user, userId);

    final legacyIsarId = user.id;
    final localCount = await _countLocalSyncedEntities(userId, legacyIsarId);
    final startedEmpty = localCount == 0;

    // Reinstall / new device: local DB is empty but cloud may still have data.
    // Never push before a successful pull; never push empty over non-empty cloud.
    if (localCount == 0) {
      if (SupabaseService.client == null) {
        return SyncUserResult(
          restoredEntityCount: 0,
          startedWithEmptyLocal: true,
          noCloudBackup: true,
        );
      }

      final remote = await SupabaseService.pull(
        userId: userId,
        pinHash: pinHash,
      );
      if (remote == null) {
        throw CloudSyncPullFailedException();
      }

      final remoteCount = _countRemoteEntities(remote);
      final hasPrefs = remote['preferences'] is Map;
      if (remoteCount > 0 || hasPrefs) {
        await _importPayload(
          userId,
          remote,
          allowDeleteReconcile: false,
          legacyIsarId: legacyIsarId,
        );
        if (remoteCount > 0) {
          await _rehydrateDerivedLocalState(userId, legacyIsarId);
          return SyncUserResult(
            restoredEntityCount: remoteCount,
            startedWithEmptyLocal: true,
          );
        }
      }

      if (remoteCount == 0) {
        final payload = await _exportPayload(user, userId);
        await _uploadPayload(userId: userId, pinHash: pinHash, payload: payload);
        return SyncUserResult(
          restoredEntityCount: 0,
          startedWithEmptyLocal: true,
          noCloudBackup: true,
        );
      }

      return SyncUserResult(
        restoredEntityCount: 0,
        startedWithEmptyLocal: true,
      );
    }

    await _pullCloudTransactionsIfLocalEmpty(
      userId: userId,
      pinHash: pinHash,
      legacyIsarId: legacyIsarId,
    );
    await _mergeCloudTransactionsIfRemoteRicher(
      userId: userId,
      pinHash: pinHash,
      legacyIsarId: legacyIsarId,
    );

    final payload = await _exportPayload(user, userId);
    await _uploadPayload(userId: userId, pinHash: pinHash, payload: payload);

    final remote = await SupabaseService.pull(userId: userId, pinHash: pinHash);
    if (remote == null) {
      throw CloudSyncPullFailedException();
    }

    final remoteCount = _countRemoteEntities(remote);
    final allowDeleteReconcile = !(localCount > 0 && remoteCount == 0);

    await _importPayload(
      userId,
      remote,
      allowDeleteReconcile: allowDeleteReconcile,
      legacyIsarId: legacyIsarId,
    );
    await _rehydrateDerivedLocalState(userId, legacyIsarId);
    return SyncUserResult(
      restoredEntityCount: remoteCount,
      startedWithEmptyLocal: startedEmpty,
    );
  }

  /// Upload local state to Supabase without downloading (fast path after edits).
  Future<void> pushUserChanges(UserLocal user, String pinHash) async {
    final userId = user.supabaseId;
    if (userId == null || userId.isEmpty) return;
    if (SupabaseService.client == null) return;

    await _migrateLegacyUserIds(user, userId);

    final legacyIsarId = user.id;
    final localCount = await _countLocalSyncedEntities(userId, legacyIsarId);
    if (localCount == 0) {
      await syncUser(user, pinHash);
      return;
    }

    await _pullCloudTransactionsIfLocalEmpty(
      userId: userId,
      pinHash: pinHash,
      legacyIsarId: legacyIsarId,
    );
    await _mergeCloudTransactionsIfRemoteRicher(
      userId: userId,
      pinHash: pinHash,
      legacyIsarId: legacyIsarId,
    );

    final payload = await _exportPayload(user, userId);
    await _uploadPayload(userId: userId, pinHash: pinHash, payload: payload);
  }

  Future<void> _uploadPayload({
    required String userId,
    required String pinHash,
    required Map<String, dynamic> payload,
  }) async {
    final result = await SupabaseService.push(
      userId: userId,
      pinHash: pinHash,
      payload: payload,
    );
    if (!result.ok) {
      throw CloudSyncPullFailedException(
        result.errorMessage ?? 'Could not upload to cloud backup',
      );
    }
  }

  /// Habit tracker UI reads [HabitLogLocal]; cloud syncs completions only.
  /// Prayer home reads [DailyPrayerLogLocal]; cloud syncs legacy [PrayerLogLocal].
  Future<void> _rehydrateDerivedLocalState(String userId, Id legacyIsarId) async {
    await _rehydrateHabitLogsFromCompletions(userId, legacyIsarId);
    await _rehydrateDailyPrayerLogsFromLegacy(userId, legacyIsarId);
  }

  Future<void> _rehydrateHabitLogsFromCompletions(
    String userId,
    Id legacyIsarId,
  ) async {
    final habits = await _habitsForUser(userId, legacyIsarId);
    final habitByRemote = {for (final h in habits) h.remoteId: h};
    final completions = await _completionsForUser(userId, legacyIsarId);

    await _isar.writeTxn(() async {
      for (final c in completions) {
        final habit = habitByRemote[c.habitRemoteId];
        if (habit == null) continue;
        final dateKey = habitDateKey(c.day);
        final existing = await _isar.habitLogLocals
            .filter()
            .userIdEqualTo(userId)
            .habitRemoteIdEqualTo(habit.remoteId)
            .dateKeyEqualTo(dateKey)
            .findFirst();
        if (existing != null) continue;

        final target = habitGoalTarget(habit);
        final completed = isHabitGoal(habit)
            ? c.value >= target
            : c.value >= 1;
        final row = HabitLogLocal()
          ..remoteId = const Uuid().v4()
          ..userId = userId
          ..habitRemoteId = habit.remoteId
          ..dateKey = dateKey
          ..currentValue = isHabitGoal(habit) ? c.value : null
          ..status =
              completed ? HabitLogStatus.completed : HabitLogStatus.pending;
        await _isar.habitLogLocals.put(row);
      }
    });
  }

  Future<void> _rehydrateDailyPrayerLogsFromLegacy(
    String userId,
    Id legacyIsarId,
  ) async {
    final legacyRows = await _prayersForUser(userId, legacyIsarId);
    if (legacyRows.isEmpty) return;

    final byDay = <String, List<PrayerLogLocal>>{};
    for (final row in legacyRows) {
      final key = dateKeyFrom(row.day);
      byDay.putIfAbsent(key, () => []).add(row);
    }

    await _isar.writeTxn(() async {
      for (final entry in byDay.entries) {
        final dateKey = entry.key;
        final existing = await _isar.dailyPrayerLogLocals
            .filter()
            .userIdEqualTo(userId)
            .dateKeyEqualTo(dateKey)
            .findFirst();
        if (existing != null) continue;

        final statuses = emptyStatuses();
        for (final p in prayerOrder) {
          final match = entry.value.where((r) => r.prayer == p).toList();
          if (match.isEmpty) continue;
          final s = match.first.status;
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
          ..userId = userId
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
      }
    });
  }

  static const _syncListKeys = [
    'transactions',
    'objectives',
    'category_budget_limits',
    'habits',
    'habit_completions',
    'prayer_logs',
    'movies',
  ];

  bool _ownsUserId(String recordUserId, String canonical, Id legacyIsarId) {
    return recordUserId == canonical || recordUserId == legacyIsarId.toString();
  }

  int _countRemoteEntities(Map<String, dynamic> remote) {
    var n = 0;
    for (final key in _syncListKeys) {
      n += (remote[key] as List? ?? []).length;
    }
    return n;
  }

  Future<int> _countLocalSyncedEntities(String userId, Id legacyIsarId) async {
    final txs = await _transactionsForUser(userId, legacyIsarId);
    final habits = await _habitsForUser(userId, legacyIsarId);
    final completions = await _completionsForUser(userId, legacyIsarId);
    final prayers = await _prayersForUser(userId, legacyIsarId);
    final movies = await _moviesForUser(userId, legacyIsarId);
    final objectives = await _objectivesForUser(userId, legacyIsarId);
    final limits = await _categoryLimitsForUser(userId, legacyIsarId);
    return txs.length +
        habits.length +
        completions.length +
        prayers.length +
        movies.length +
        objectives.length +
        limits.length;
  }

  Future<void> _migrateLegacyUserIds(UserLocal user, String canonical) async {
    final legacy = user.id.toString();
    if (legacy == canonical) return;

    await _isar.writeTxn(() async {
      for (final t in await _isar.transactionLocals.where().findAll()) {
        if (t.userId == legacy) {
          t.userId = canonical;
          await _isar.transactionLocals.put(t);
        }
      }
      for (final h in await _isar.habitLocals.where().findAll()) {
        if (h.userId == legacy) {
          h.userId = canonical;
          await _isar.habitLocals.put(h);
        }
      }
      for (final c in await _isar.habitCompletionLocals.where().findAll()) {
        if (c.userId == legacy) {
          c.userId = canonical;
          await _isar.habitCompletionLocals.put(c);
        }
      }
      for (final p in await _isar.prayerLogLocals.where().findAll()) {
        if (p.userId == legacy) {
          p.userId = canonical;
          await _isar.prayerLogLocals.put(p);
        }
      }
      for (final m in await _isar.movieLocals.where().findAll()) {
        if (m.userId == legacy) {
          m.userId = canonical;
          await _isar.movieLocals.put(m);
        }
      }
      for (final o in await _isar.objectiveLocals.where().findAll()) {
        if (o.userId == legacy) {
          o.userId = canonical;
          await _isar.objectiveLocals.put(o);
        }
      }
      for (final l in await _isar.categoryBudgetLimitLocals.where().findAll()) {
        if (l.userId == legacy) {
          l.userId = canonical;
          await _isar.categoryBudgetLimitLocals.put(l);
        }
      }
    });
  }

  Future<void> _pullCloudTransactionsIfLocalEmpty({
    required String userId,
    required String pinHash,
    required Id legacyIsarId,
  }) async {
    if (SupabaseService.client == null) return;

    final localTxs = await _transactionsForUser(userId, legacyIsarId);
    if (localTxs.isNotEmpty) return;

    final remote = await SupabaseService.pull(userId: userId, pinHash: pinHash);
    if (remote == null) return;

    final remoteTxCount = (remote['transactions'] as List? ?? []).length;
    if (remoteTxCount == 0) return;

    await _importPayload(
      userId,
      remote,
      allowDeleteReconcile: false,
      legacyIsarId: legacyIsarId,
    );
    await _rehydrateDerivedLocalState(userId, legacyIsarId);
  }

  /// Phone had partial ledger; cloud still has full history (e.g. SQL import).
  Future<void> _mergeCloudTransactionsIfRemoteRicher({
    required String userId,
    required String pinHash,
    required Id legacyIsarId,
  }) async {
    if (SupabaseService.client == null) return;

    final localTxs = await _transactionsForUser(userId, legacyIsarId);
    final remote = await SupabaseService.pull(userId: userId, pinHash: pinHash);
    if (remote == null) return;

    final remoteTxCount = (remote['transactions'] as List? ?? []).length;
    if (remoteTxCount == 0) return;
    if (remoteTxCount <= localTxs.length) return;

    await _importPayload(
      userId,
      remote,
      allowDeleteReconcile: false,
      legacyIsarId: legacyIsarId,
    );
    await _rehydrateDerivedLocalState(userId, legacyIsarId);
  }

  Future<List<TransactionLocal>> _transactionsForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.transactionLocals.where().findAll();
    return all.where((t) => _ownsUserId(t.userId, userId, legacyIsarId)).toList();
  }

  Future<List<HabitLocal>> _habitsForUser(String userId, Id legacyIsarId) async {
    final all = await _isar.habitLocals.where().findAll();
    return all.where((h) => _ownsUserId(h.userId, userId, legacyIsarId)).toList();
  }

  Future<List<HabitCompletionLocal>> _completionsForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.habitCompletionLocals.where().findAll();
    return all.where((c) => _ownsUserId(c.userId, userId, legacyIsarId)).toList();
  }

  Future<List<PrayerLogLocal>> _prayersForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.prayerLogLocals.where().findAll();
    return all.where((p) => _ownsUserId(p.userId, userId, legacyIsarId)).toList();
  }

  Future<List<DailyPrayerLogLocal>> _dailyPrayersForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.dailyPrayerLogLocals.where().findAll();
    return all.where((d) => _ownsUserId(d.userId, userId, legacyIsarId)).toList();
  }

  PrayerStatus _legacyPrayerStatusFromTracker(TrackerPrayerStatus status) {
    return switch (status) {
      TrackerPrayerStatus.prayed => PrayerStatus.onTimeAlone,
      TrackerPrayerStatus.missed => PrayerStatus.missed,
      TrackerPrayerStatus.excused => PrayerStatus.qadha,
      TrackerPrayerStatus.unmarked => PrayerStatus.none,
    };
  }

  TrackerPrayerStatus _trackerStatusFromLocal(DailyPrayerLogLocal local, PrayerName p) {
    return switch (p) {
      PrayerName.fajr => local.fajr,
      PrayerName.dhuhr => local.dhuhr,
      PrayerName.asr => local.asr,
      PrayerName.maghrib => local.maghrib,
      PrayerName.isha => local.isha,
    };
  }

  /// Daily tracker is the source of truth in the app UI; map to legacy rows for cloud.
  List<PrayerLogLocal> _prayerLogsFromDailyTracker(
    String userId,
    List<DailyPrayerLogLocal> dailies,
  ) {
    final out = <PrayerLogLocal>[];
    for (final d in dailies) {
      final day = parseDateKey(d.dateKey);
      for (final p in prayerOrder) {
        final tracker = _trackerStatusFromLocal(d, p);
        final legacy = _legacyPrayerStatusFromTracker(tracker);
        if (legacy == PrayerStatus.none) continue;
        out.add(
          PrayerLogLocal()
            ..remoteId = _prayerLogRemoteId(userId, d.dateKey, p)
            ..userId = userId
            ..day = day
            ..prayer = p
            ..status = legacy,
        );
      }
    }
    return out;
  }

  Future<List<PrayerLogLocal>> _prayerLogsForExport(
    String userId,
    Id legacyIsarId,
  ) async {
    final dailies = await _dailyPrayersForUser(userId, legacyIsarId);
    if (dailies.isNotEmpty) {
      return _prayerLogsFromDailyTracker(userId, dailies);
    }
    return _prayersForUser(userId, legacyIsarId);
  }

  Future<List<MovieLocal>> _moviesForUser(String userId, Id legacyIsarId) async {
    final all = await _isar.movieLocals.where().findAll();
    return all.where((m) => _ownsUserId(m.userId, userId, legacyIsarId)).toList();
  }

  Future<List<ObjectiveLocal>> _objectivesForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.objectiveLocals.where().findAll();
    return all.where((o) => _ownsUserId(o.userId, userId, legacyIsarId)).toList();
  }

  Future<List<CategoryBudgetLimitLocal>> _categoryLimitsForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.categoryBudgetLimitLocals.where().findAll();
    return all
        .where((l) => _ownsUserId(l.userId, userId, legacyIsarId))
        .toList();
  }

  Future<Map<String, dynamic>> _exportPayload(UserLocal user, String userId) async {
    final legacyIsarId = user.id;
    final txs = await _transactionsForUser(userId, legacyIsarId);
    final habits = await _habitsForUser(userId, legacyIsarId);
    final completions = await _completionsForUser(userId, legacyIsarId);
    final prayers = await _prayerLogsForExport(userId, legacyIsarId);
    final movies = await _moviesForUser(userId, legacyIsarId);
    final objectives = await _objectivesForUser(userId, legacyIsarId);
    final categoryLimits = await _categoryLimitsForUser(userId, legacyIsarId);

    return {
      'preferences': {
        'onboarding_complete': user.onboardingComplete,
        'budget_enabled': user.budgetEnabled,
      },
      'transactions': txs.map(_transactionJson).toList(),
      'objectives': objectives.map(_objectiveJson).toList(),
      'category_budget_limits': categoryLimits.map(_categoryLimitJson).toList(),
      'habits': habits.map(_habitJson).toList(),
      'habit_completions': completions.map(_completionJson).toList(),
      'prayer_logs': prayers.map(_prayerJson).toList(),
      'movies': movies.map(_movieJson).toList(),
    };
  }

  Future<void> _importPayload(
    String userId,
    Map<String, dynamic> remote, {
    required bool allowDeleteReconcile,
    required Id legacyIsarId,
  }) async {
    await _isar.writeTxn(() async {
      final prefs = remote['preferences'];
      if (prefs is Map) {
        final user = await _isar.userLocals
            .filter()
            .supabaseIdEqualTo(userId)
            .findFirst();
        if (user != null) {
          user.onboardingComplete =
              prefs['onboarding_complete'] as bool? ?? user.onboardingComplete;
          user.budgetEnabled =
              prefs['budget_enabled'] as bool? ?? user.budgetEnabled;
          await _isar.userLocals.put(user);
        }
      }

      for (final row in (remote['transactions'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final occurredAt = DateTime.parse(m['occurred_at'] as String);
        final isIncome = m['is_income'] as bool? ?? false;
        final title = m['title'] as String? ?? m['category'] as String? ?? '';
        final category = m['category'] as String? ?? '';
        final ledgerType = _ledgerTypeFromRemote(
          isIncome: isIncome,
          title: title,
          category: category,
          remoteLedger: m['ledger_type'] as String?,
          isAuto: m['is_auto_generated'] as bool? ?? false,
        );
        final tx = TransactionLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..amount = (m['amount'] as num).toDouble()
          ..isIncome = isIncome
          ..ledgerType = ledgerType
          ..title = title
          ..category = category
          ..categoryRemoteId =
              m['category_remote_id'] as String? ?? _categoryRemoteFallback(category)
          ..account = m['account'] as String? ?? 'Cash'
          ..note = m['note'] as String? ?? ''
          ..occurredAt = occurredAt
          ..monthKey = budgetMonthKey(occurredAt)
          ..isAutoGenerated = m['is_auto_generated'] as bool? ?? false
          ..scheduleType = BudgetScheduleType.values.byName(
            m['schedule_type'] as String? ?? 'normal',
          )
          ..paid = m['paid'] as bool? ?? true
          ..recurrence = m['recurrence'] as String? ?? 'none'
          ..periodLength = m['period_length'] as int? ?? 1
          ..recurrenceEnd = m['recurrence_end'] != null
              ? DateTime.tryParse(m['recurrence_end'] as String)
              : null
          ..objectiveRemoteId = m['objective_remote_id'] as String?;
        final existing = await _isar.transactionLocals
            .filter()
            .remoteIdEqualTo(tx.remoteId)
            .findFirst();
        if (existing != null) tx.id = existing.id;
        await _isar.transactionLocals.put(tx);
      }

      await _purgeLocalsMissingFromRemote(
        enabled: allowDeleteReconcile,
        remote: remote,
        listKey: 'transactions',
        locals: (await _transactionsForUser(userId, legacyIsarId))
            .map((e) => (remoteId: e.remoteId, id: e.id)),
        deleteById: _isar.transactionLocals.delete,
      );

      for (final row in (remote['objectives'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final o = ObjectiveLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..name = m['name'] as String
          ..targetAmount = (m['target_amount'] as num).toDouble()
          ..kind = m['kind'] as String? ?? 'savings'
          ..walletName = m['wallet_name'] as String? ?? 'Cash'
          ..colorValue = _colorValueFromCloudSync(m['color_value'])
          ..pinned = m['pinned'] as bool? ?? true
          ..archived = m['archived'] as bool? ?? false
          ..endDate = m['end_date'] != null
              ? DateTime.tryParse(m['end_date'] as String)
              : null
          ..sortOrder = m['sort_order'] as int? ?? 0;
        final existing = await _isar.objectiveLocals
            .filter()
            .remoteIdEqualTo(o.remoteId)
            .findFirst();
        if (existing != null) o.id = existing.id;
        await _isar.objectiveLocals.put(o);
      }

      await _purgeLocalsMissingFromRemote(
        enabled: allowDeleteReconcile,
        remote: remote,
        listKey: 'objectives',
        locals: (await _objectivesForUser(userId, legacyIsarId))
            .map((e) => (remoteId: e.remoteId, id: e.id)),
        deleteById: _isar.objectiveLocals.delete,
      );

      for (final row in (remote['category_budget_limits'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final l = CategoryBudgetLimitLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..budgetRemoteId = m['budget_remote_id'] as String
          ..categoryName = m['category_name'] as String
          ..limitAmount = (m['limit_amount'] as num).toDouble()
          ..monthKey = m['month_key'] as String? ?? 'recurring'
          ..rolloverEnabled = m['rollover_enabled'] as bool? ?? false
          ..categoryRemoteId = m['category_remote_id'] as String? ?? '';
        final existing = await _isar.categoryBudgetLimitLocals
            .filter()
            .remoteIdEqualTo(l.remoteId)
            .findFirst();
        if (existing != null) l.id = existing.id;
        await _isar.categoryBudgetLimitLocals.put(l);
      }

      await _purgeLocalsMissingFromRemote(
        enabled: allowDeleteReconcile,
        remote: remote,
        listKey: 'category_budget_limits',
        locals: (await _categoryLimitsForUser(userId, legacyIsarId))
            .map((e) => (remoteId: e.remoteId, id: e.id)),
        deleteById: _isar.categoryBudgetLimitLocals.delete,
      );

      for (final row in (remote['habits'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final h = HabitLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..name = m['name'] as String
          ..colorValue = _colorValueFromCloudSync(
            m['color_value'],
            fallback: 0xFFF97316,
          )
          ..icon = m['icon'] as String? ?? 'target'
          ..kind = HabitKind.values.byName(m['kind'] as String? ?? 'positive')
          ..interval = HabitInterval.values.byName(
            m['interval'] as String? ?? m['frequency'] as String? ?? 'daily',
          )
          ..targetFrequency = (m['target_frequency'] as num?)?.toInt() ?? 1
          ..scheduleWeekdays = _intList(m['schedule_weekdays'])
          ..scheduleEvery = (m['schedule_every'] as num?)?.toInt() ?? 2
          ..scheduleUnit = ScheduleUnit.values.byName(
            m['schedule_unit'] as String? ?? 'days',
          )
          ..targetPerDay = (m['target_per_day'] as num?)?.toInt() ?? 1
          ..incrementAmount = (m['increment_amount'] as num?)?.toDouble() ?? 1
          ..unitLabel = m['unit_label'] as String? ?? ''
          ..description = m['description'] as String? ?? ''
          ..frequency = m['frequency'] as String? ?? 'daily'
          ..reminderMinute = (m['reminder_minute'] as num?)?.toInt()
          ..restDays = _intList(m['rest_days'])
          ..vacationsJson = m['vacations_json'] as String? ?? '[]'
          ..remindersJson = m['reminders_json'] as String? ?? '[]'
          ..archived = m['archived'] as bool? ?? false
          ..sortOrder = (m['sort_order'] as num?)?.toInt() ?? 0
          ..scheduleMonthDays = _intList(m['schedule_month_days'])
          ..scheduleStartDateKey = m['schedule_start_date_key'] as String? ?? ''
          ..createdAt = DateTime.tryParse(m['created_at'] as String? ?? '') ??
              DateTime.tryParse(m['updated_at'] as String? ?? '') ??
              DateTime.now();
        final existing =
            await _isar.habitLocals.filter().remoteIdEqualTo(h.remoteId).findFirst();
        if (existing != null) h.id = existing.id;
        await _isar.habitLocals.put(h);
      }

      await _purgeLocalsMissingFromRemote(
        enabled: allowDeleteReconcile,
        remote: remote,
        listKey: 'habits',
        locals: (await _habitsForUser(userId, legacyIsarId))
            .map((e) => (remoteId: e.remoteId, id: e.id)),
        deleteById: _isar.habitLocals.delete,
      );

      for (final row in (remote['habit_completions'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final c = HabitCompletionLocal()
          ..remoteId = m['id'] as String
          ..habitRemoteId = m['habit_id'] as String
          ..userId = userId
          ..day = DateTime.parse(m['day'] as String)
          ..value = (m['value'] as num?)?.toDouble() ?? 1;
        final existing = await _isar.habitCompletionLocals
            .filter()
            .remoteIdEqualTo(c.remoteId)
            .findFirst();
        if (existing != null) c.id = existing.id;
        await _isar.habitCompletionLocals.put(c);
      }

      await _purgeLocalsMissingFromRemote(
        enabled: allowDeleteReconcile,
        remote: remote,
        listKey: 'habit_completions',
        locals: (await _completionsForUser(userId, legacyIsarId))
            .map((e) => (remoteId: e.remoteId, id: e.id)),
        deleteById: _isar.habitCompletionLocals.delete,
      );

      for (final row in (remote['prayer_logs'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final p = PrayerLogLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..day = DateTime.parse(m['day'] as String)
          ..prayer = PrayerName.values.byName(m['prayer'] as String)
          ..status = PrayerStatus.values.byName(m['status'] as String);
        final existing = await _isar.prayerLogLocals
            .filter()
            .remoteIdEqualTo(p.remoteId)
            .findFirst();
        if (existing != null) p.id = existing.id;
        await _isar.prayerLogLocals.put(p);
      }

      await _purgeLocalsMissingFromRemote(
        enabled: allowDeleteReconcile,
        remote: remote,
        listKey: 'prayer_logs',
        locals: (await _prayersForUser(userId, legacyIsarId))
            .map((e) => (remoteId: e.remoteId, id: e.id)),
        deleteById: _isar.prayerLogLocals.delete,
      );

      for (final row in (remote['movies'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final mv = MovieLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..tmdbId = m['tmdb_id'] as int?
          ..title = m['title'] as String
          ..posterPath = m['poster_path'] as String?
          ..backdropPath = m['backdrop_path'] as String?
          ..mediaType = m['media_type'] as String? ?? 'movie'
          ..watchStatus = WatchStatus.values.byName(m['watch_status'] as String)
          ..overview = m['overview'] as String?
          ..releaseDate = m['release_date'] as String?
          ..voteAverage = (m['vote_average'] as num?)?.toDouble()
          ..userRating = (m['user_rating'] as num?)?.toDouble()
          ..userReview = m['user_review'] as String? ?? ''
          ..liked = m['liked'] as bool? ?? false
          ..favorite = m['favorite'] as bool? ?? false
          ..watchedAt = DateTime.tryParse(m['watched_at'] as String? ?? '')
          ..categoryRemoteId = m['category_remote_id'] as String? ?? ''
          ..priority = (m['priority'] as num?)?.toInt() ?? 3
          ..trackerNote = m['tracker_note'] as String? ?? ''
          ..addedAt = DateTime.tryParse(m['updated_at'] as String? ?? '') ??
              DateTime.now();
        final existing =
            await _isar.movieLocals.filter().remoteIdEqualTo(mv.remoteId).findFirst();
        if (existing != null) mv.id = existing.id;
        await _isar.movieLocals.put(mv);
      }

      await _purgeLocalsMissingFromRemote(
        enabled: allowDeleteReconcile,
        remote: remote,
        listKey: 'movies',
        locals: (await _moviesForUser(userId, legacyIsarId))
            .map((e) => (remoteId: e.remoteId, id: e.id)),
        deleteById: _isar.movieLocals.delete,
      );

      await _ensureCategoriesForImportedTransactions(userId, legacyIsarId);
    });
  }

  Future<void> _ensureCategoriesForImportedTransactions(
    String userId,
    Id legacyIsarId,
  ) async {
    final txs = await _transactionsForUser(userId, legacyIsarId);
    if (txs.isEmpty) return;

    final existing = await _isar.categoryLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    final byRemote = {for (final c in existing) c.remoteId: c};
    final byNameLower = {for (final c in existing) c.name.toLowerCase(): c};
    var sortOrder = existing.length;

    for (final t in txs) {
      if (t.isIncome || !budgetTransactionInLedger(t)) continue;
      final name = t.category.trim().isEmpty ? t.title.trim() : t.category.trim();
      if (name.isEmpty) continue;

      final remoteId = t.categoryRemoteId.isNotEmpty
          ? t.categoryRemoteId
          : _categoryRemoteFallback(name);

      if (byRemote.containsKey(remoteId)) continue;
      final nameHit = byNameLower[name.toLowerCase()];
      if (nameHit != null) {
        if (nameHit.remoteId != remoteId && remoteId.isNotEmpty) {
          byRemote.remove(nameHit.remoteId);
          nameHit.remoteId = remoteId;
          await _isar.categoryLocals.put(nameHit);
          byRemote[remoteId] = nameHit;
        }
        continue;
      }

      final cat = CategoryLocal()
        ..remoteId = remoteId
        ..userId = userId
        ..name = name
        ..isIncome = false
        ..colorValue = _importCategoryColor(sortOrder)
        ..sortOrder = sortOrder
        ..emoji = defaultCategoryEmoji(name)
        ..isCustom = true
        ..isArchived = false;
      sortOrder++;
      await _isar.categoryLocals.put(cat);
      byRemote[remoteId] = cat;
      byNameLower[name.toLowerCase()] = cat;
    }
  }

  int _importCategoryColor(int index) {
    const palette = [
      NBColors.budget,
      Color(0xFFE65100),
      Color(0xFF1565C0),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFFAD1457),
      Color(0xFF4527A0),
      Color(0xFF546E7A),
      Color(0xFFEF6C00),
      Color(0xFF5D4037),
    ];
    return palette[index % palette.length].toARGB32();
  }

  Set<String> _remoteIdsFromPayload(Map<String, dynamic> remote, String listKey) {
    return {
      for (final row in (remote[listKey] as List? ?? []))
        (row as Map<String, dynamic>)['id'] as String,
    };
  }

  Future<void> _purgeLocalsMissingFromRemote({
    required bool enabled,
    required Map<String, dynamic> remote,
    required String listKey,
    required Iterable<({String remoteId, Id id})> locals,
    required Future<bool> Function(Id id) deleteById,
  }) async {
    if (!enabled) return;
    final remoteIds = _remoteIdsFromPayload(remote, listKey);
    for (final local in locals) {
      if (!remoteIds.contains(local.remoteId)) {
        await deleteById(local.id);
      }
    }
  }

  Map<String, dynamic> _transactionJson(TransactionLocal t) => {
        'id': t.remoteId,
        'amount': t.amount,
        'is_income': t.isIncome,
        'ledger_type': t.ledgerType.name,
        'category_remote_id': t.categoryRemoteId,
        'is_auto_generated': t.isAutoGenerated,
        'title': t.title.isNotEmpty ? t.title : t.category,
        'category': t.category,
        'account': t.account,
        'note': t.note,
        'occurred_at': t.occurredAt.toUtc().toIso8601String(),
        'schedule_type': t.scheduleType.name,
        'paid': t.paid,
        'recurrence': t.recurrence,
        'period_length': t.periodLength,
        'recurrence_end': t.recurrenceEnd?.toUtc().toIso8601String(),
        'objective_remote_id': t.objectiveRemoteId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> _objectiveJson(ObjectiveLocal o) => {
        'id': o.remoteId,
        'name': o.name,
        'target_amount': o.targetAmount,
        'kind': o.kind,
        'wallet_name': o.walletName,
        'color_value': _colorValueForCloudSync(o.colorValue),
        'pinned': o.pinned,
        'archived': o.archived,
        'end_date': o.endDate?.toUtc().toIso8601String(),
        'sort_order': o.sortOrder,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> _categoryLimitJson(CategoryBudgetLimitLocal l) => {
        'id': l.remoteId,
        'budget_remote_id': l.budgetRemoteId,
        'category_name': l.categoryName,
        'limit_amount': l.limitAmount,
        'month_key': l.monthKey,
        'rollover_enabled': l.rolloverEnabled,
        'category_remote_id': l.categoryRemoteId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> _habitJson(HabitLocal h) => {
        'id': h.remoteId,
        'name': h.name,
        'color_value': _colorValueForCloudSync(h.colorValue),
        'icon': h.icon,
        'kind': h.kind.name,
        'interval': h.interval.name,
        'target_frequency': h.targetFrequency,
        'schedule_weekdays': h.scheduleWeekdays,
        'schedule_every': h.scheduleEvery,
        'schedule_unit': h.scheduleUnit.name,
        'target_per_day': h.targetPerDay,
        'increment_amount': h.incrementAmount,
        'unit_label': h.unitLabel,
        'description': h.description,
        'frequency': h.frequency,
        'reminder_minute': h.reminderMinute,
        'rest_days': h.restDays,
        'vacations_json': h.vacationsJson,
        'reminders_json': h.remindersJson,
        'archived': h.archived,
        'sort_order': h.sortOrder,
        'schedule_month_days': h.scheduleMonthDays,
        'schedule_start_date_key': h.scheduleStartDateKey,
        'created_at': h.createdAt.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> _completionJson(HabitCompletionLocal c) => {
        'id': c.remoteId,
        'habit_id': c.habitRemoteId,
        'day': c.day.toIso8601String().split('T').first,
        'value': c.value,
      };

  Map<String, dynamic> _prayerJson(PrayerLogLocal p) => {
        'id': _prayerLogRemoteId(p.userId, dateKeyFrom(p.day), p.prayer),
        'day': p.day.toIso8601String().split('T').first,
        'prayer': p.prayer.name,
        'status': p.status.name,
      };

  /// Supabase `prayer_logs.id` is UUID — never use composite strings like `uuid_fajr`.
  String _prayerLogRemoteId(String userId, String dateKey, PrayerName prayer) {
    return const Uuid().v5(
      Uuid.NAMESPACE_URL,
      'ruhh-prayer-log|$userId|$dateKey|${prayer.name}',
    );
  }

  Map<String, dynamic> _movieJson(MovieLocal m) => {
        'id': m.remoteId,
        'tmdb_id': m.tmdbId,
        'title': m.title,
        'poster_path': m.posterPath,
        'backdrop_path': m.backdropPath,
        'media_type': m.mediaType,
        'watch_status': m.watchStatus.name,
        'overview': m.overview,
        'release_date': m.releaseDate,
        'vote_average': m.voteAverage,
        'user_rating': m.userRating,
        'user_review': m.userReview,
        'liked': m.liked,
        'favorite': m.favorite,
        'watched_at': m.watchedAt?.toUtc().toIso8601String(),
        'category_remote_id': m.categoryRemoteId,
        'priority': m.priority,
        'tracker_note': m.trackerNote,
        'updated_at': m.addedAt.toUtc().toIso8601String(),
      };

  List<int> _intList(dynamic value) {
    if (value is List) {
      return value.map((e) => (e as num).toInt()).toList();
    }
    return [];
  }

  BudgetLedgerType _ledgerTypeFromRemote({
    required bool isIncome,
    required String title,
    required String category,
    required String? remoteLedger,
    required bool isAuto,
  }) {
    if (remoteLedger != null && remoteLedger.isNotEmpty) {
      try {
        return BudgetLedgerType.values.byName(remoteLedger);
      } catch (_) {}
    }
    if (isAuto &&
        (title.toLowerCase().contains('salary') ||
            category.toLowerCase() == 'salary')) {
      return BudgetLedgerType.salary;
    }
    if (!isIncome) return BudgetLedgerType.expense;
    return BudgetLedgerType.credit;
  }

  String _categoryRemoteFallback(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'salary':
        return BudgetCategoryIds.salary;
      case 'food':
        return BudgetCategoryIds.food;
      default:
        return '';
    }
  }

  String _canonicalUserId(UserLocal user) {
    final cloud = user.supabaseId;
    if (cloud != null && cloud.isNotEmpty) return cloud;
    return user.id.toString();
  }

  /// Full local backup for CSV export (includes entities not stored in Supabase).
  Future<Map<String, dynamic>> exportFileBackupPayload(
    UserLocal user, {
    Map<String, dynamic>? deviceSettings,
  }) async {
    final userId = _canonicalUserId(user);
    await _migrateLegacyUserIds(user, userId);
    final legacyIsarId = user.id;

    final base = await _exportPayload(user, userId);
    final wallets = await _walletsForUser(userId, legacyIsarId);
    final categories = await _categoriesForUser(userId, legacyIsarId);
    final periods = await _budgetPeriodsForUser(userId, legacyIsarId);
    final salary = await _standingSalaryForUser(userId, legacyIsarId);
    final habitLogs = await _habitLogsForUser(userId, legacyIsarId);
    final dailyPrayers = await _dailyPrayersForUser(userId, legacyIsarId);
    final movieCategories = await _movieCategoriesForUser(userId, legacyIsarId);
    final todos = await _todosForUser(userId, legacyIsarId);
    final focusSessions = await _focusSessionsForUser(userId, legacyIsarId);

    return {
      ...base,
      'backup_format_version': RuhhBackupFormat.version,
      'source_username': user.username,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      if (deviceSettings != null) 'device_settings': deviceSettings,
      'wallets': wallets.map(_walletJson).toList(),
      'categories': categories.map(_categoryJson).toList(),
      'budget_periods': periods.map(_budgetPeriodJson).toList(),
      'standing_salary': salary == null ? null : _standingSalaryJson(salary),
      'habit_logs': habitLogs.map(_habitLogJson).toList(),
      'daily_prayer_logs': dailyPrayers.map(_dailyPrayerJson).toList(),
      'movie_categories': movieCategories.map(_movieCategoryJson).toList(),
      'todos': todos.map(_todoJson).toList(),
      'focus_sessions': focusSessions.map(_focusSessionJson).toList(),
    };
  }

  /// Replaces all data for [user] from a [exportFileBackupPayload] map.
  Future<int> importFileBackupPayload(
    UserLocal user,
    Map<String, dynamic> payload,
  ) async {
    final version = payload['backup_format_version'] as int? ?? 0;
    if (version != RuhhBackupFormat.version) {
      throw FormatException(
        'Unsupported backup version $version (expected ${RuhhBackupFormat.version}).',
      );
    }

    final userId = _canonicalUserId(user);
    await _migrateLegacyUserIds(user, userId);
    final legacyIsarId = user.id;

    await _purgeAllUserLocalData(userId, legacyIsarId);

    final cloudShape = Map<String, dynamic>.from(payload)
      ..remove('backup_format_version')
      ..remove('source_username')
      ..remove('exported_at')
      ..remove('device_settings')
      ..remove('wallets')
      ..remove('categories')
      ..remove('budget_periods')
      ..remove('standing_salary')
      ..remove('habit_logs')
      ..remove('daily_prayer_logs')
      ..remove('movie_categories')
      ..remove('todos')
      ..remove('focus_sessions');

    await _importPayload(
      userId,
      cloudShape,
      allowDeleteReconcile: true,
      legacyIsarId: legacyIsarId,
    );

    await _importFileBackupExtras(userId, legacyIsarId, payload);
    await _rehydrateDerivedLocalState(userId, legacyIsarId);

    return _countImportedEntities(payload);
  }

  int _countImportedEntities(Map<String, dynamic> payload) {
    var n = _countRemoteEntities(payload);
    for (final key in _fileBackupListKeys) {
      n += (payload[key] as List? ?? []).length;
    }
    if (payload['standing_salary'] != null) n++;
    return n;
  }

  static const _fileBackupListKeys = [
    'wallets',
    'categories',
    'budget_periods',
    'habit_logs',
    'daily_prayer_logs',
    'movie_categories',
    'todos',
    'focus_sessions',
  ];

  Future<void> _purgeAllUserLocalData(String userId, Id legacyIsarId) async {
    await _isar.writeTxn(() async {
      for (final t in await _transactionsForUser(userId, legacyIsarId)) {
        await _isar.transactionLocals.delete(t.id);
      }
      for (final o in await _objectivesForUser(userId, legacyIsarId)) {
        await _isar.objectiveLocals.delete(o.id);
      }
      for (final l in await _categoryLimitsForUser(userId, legacyIsarId)) {
        await _isar.categoryBudgetLimitLocals.delete(l.id);
      }
      for (final h in await _habitsForUser(userId, legacyIsarId)) {
        await _isar.habitLocals.delete(h.id);
      }
      for (final c in await _completionsForUser(userId, legacyIsarId)) {
        await _isar.habitCompletionLocals.delete(c.id);
      }
      for (final p in await _prayersForUser(userId, legacyIsarId)) {
        await _isar.prayerLogLocals.delete(p.id);
      }
      for (final m in await _moviesForUser(userId, legacyIsarId)) {
        await _isar.movieLocals.delete(m.id);
      }
      for (final w in await _walletsForUser(userId, legacyIsarId)) {
        await _isar.walletLocals.delete(w.id);
      }
      for (final c in await _categoriesForUser(userId, legacyIsarId)) {
        await _isar.categoryLocals.delete(c.id);
      }
      for (final p in await _budgetPeriodsForUser(userId, legacyIsarId)) {
        await _isar.budgetPeriodLocals.delete(p.id);
      }
      final salary = await _standingSalaryForUser(userId, legacyIsarId);
      if (salary != null) await _isar.standingSalaryLocals.delete(salary.id);
      for (final hl in await _habitLogsForUser(userId, legacyIsarId)) {
        await _isar.habitLogLocals.delete(hl.id);
      }
      for (final d in await _dailyPrayersForUser(userId, legacyIsarId)) {
        await _isar.dailyPrayerLogLocals.delete(d.id);
      }
      for (final mc in await _movieCategoriesForUser(userId, legacyIsarId)) {
        await _isar.movieCategoryLocals.delete(mc.id);
      }
      for (final t in await _todosForUser(userId, legacyIsarId)) {
        await _isar.todoLocals.delete(t.id);
      }
      for (final f in await _focusSessionsForUser(userId, legacyIsarId)) {
        await _isar.focusSessionLocals.delete(f.id);
      }
    });
  }

  Future<void> _importFileBackupExtras(
    String userId,
    Id legacyIsarId,
    Map<String, dynamic> payload,
  ) async {
    await _isar.writeTxn(() async {
      for (final row in (payload['wallets'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final remoteId = m['id'] as String;
        final w = WalletLocal()
          ..remoteId = remoteId
          ..userId = userId
          ..name = m['name'] as String
          ..currency = m['currency'] as String? ?? 'INR'
          ..colorValue = (m['color_value'] as num?)?.toInt() ?? 0
          ..sortOrder = (m['sort_order'] as num?)?.toInt() ?? 0
          ..openingBalance = (m['opening_balance'] as num?)?.toDouble() ?? 0;
        final existing =
            await _isar.walletLocals.filter().remoteIdEqualTo(remoteId).findFirst();
        if (existing != null) w.id = existing.id;
        await _isar.walletLocals.put(w);
      }

      for (final row in (payload['categories'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final remoteId = m['id'] as String;
        final c = CategoryLocal()
          ..remoteId = remoteId
          ..userId = userId
          ..name = m['name'] as String
          ..isIncome = m['is_income'] as bool? ?? false
          ..colorValue = (m['color_value'] as num?)?.toInt() ?? 0
          ..sortOrder = (m['sort_order'] as num?)?.toInt() ?? 0
          ..iconKey = m['icon_key'] as String? ?? 'category'
          ..emoji = m['emoji'] as String? ?? ''
          ..isCustom = m['is_custom'] as bool? ?? false
          ..isArchived = m['is_archived'] as bool? ?? false;
        final existing = await _isar.categoryLocals
            .filter()
            .remoteIdEqualTo(remoteId)
            .findFirst();
        if (existing != null) c.id = existing.id;
        await _isar.categoryLocals.put(c);
      }

      for (final row in (payload['budget_periods'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final remoteId = m['id'] as String;
        final p = BudgetPeriodLocal()
          ..remoteId = remoteId
          ..userId = userId
          ..name = m['name'] as String
          ..limitAmount = (m['limit_amount'] as num).toDouble()
          ..period = m['period'] as String? ?? 'monthly'
          ..startsAt = DateTime.parse(m['starts_at'] as String)
          ..colorValue = (m['color_value'] as num?)?.toInt() ?? 0
          ..archived = m['archived'] as bool? ?? false;
        final existing = await _isar.budgetPeriodLocals
            .filter()
            .remoteIdEqualTo(remoteId)
            .findFirst();
        if (existing != null) p.id = existing.id;
        await _isar.budgetPeriodLocals.put(p);
      }

      final salaryRow = payload['standing_salary'];
      if (salaryRow is Map<String, dynamic>) {
        final existingSalary = await _standingSalaryForUser(userId, legacyIsarId);
        final s = existingSalary ?? StandingSalaryLocal()..userId = userId;
        s.amount = (salaryRow['amount'] as num?)?.toDouble() ?? 0;
        s.effectiveFromMonthKey =
            salaryRow['effective_from_month_key'] as String? ?? '';
        await _isar.standingSalaryLocals.put(s);
      }

      for (final row in (payload['habit_logs'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final remoteId = m['id'] as String;
        final h = HabitLogLocal()
          ..remoteId = remoteId
          ..userId = userId
          ..habitRemoteId = m['habit_remote_id'] as String
          ..dateKey = m['date_key'] as String
          ..status = HabitLogStatus.values.byName(
            m['status'] as String? ?? 'pending',
          )
          ..currentValue = (m['current_value'] as num?)?.toDouble();
        final existing = await _isar.habitLogLocals
            .filter()
            .remoteIdEqualTo(remoteId)
            .findFirst();
        if (existing != null) h.id = existing.id;
        await _isar.habitLogLocals.put(h);
      }

      for (final row in (payload['daily_prayer_logs'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final remoteId = m['id'] as String;
        final d = DailyPrayerLogLocal()
          ..remoteId = remoteId
          ..userId = userId
          ..dateKey = m['date_key'] as String
          ..isExcusedDay = m['is_excused_day'] as bool? ?? false
          ..fajr = TrackerPrayerStatus.values.byName(
            m['fajr'] as String? ?? 'unmarked',
          )
          ..dhuhr = TrackerPrayerStatus.values.byName(
            m['dhuhr'] as String? ?? 'unmarked',
          )
          ..asr = TrackerPrayerStatus.values.byName(
            m['asr'] as String? ?? 'unmarked',
          )
          ..maghrib = TrackerPrayerStatus.values.byName(
            m['maghrib'] as String? ?? 'unmarked',
          )
          ..isha = TrackerPrayerStatus.values.byName(
            m['isha'] as String? ?? 'unmarked',
          );
        final existing = await _isar.dailyPrayerLogLocals
            .filter()
            .remoteIdEqualTo(remoteId)
            .findFirst();
        if (existing != null) d.id = existing.id;
        await _isar.dailyPrayerLogLocals.put(d);
      }

      for (final row in (payload['movie_categories'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final remoteId = m['id'] as String;
        final mc = MovieCategoryLocal()
          ..remoteId = remoteId
          ..userId = userId
          ..name = m['name'] as String
          ..colorValue = (m['color_value'] as num?)?.toInt() ?? 0
          ..emoji = m['emoji'] as String? ?? ''
          ..isCustom = m['is_custom'] as bool? ?? false
          ..isArchived = m['is_archived'] as bool? ?? false
          ..sortOrder = (m['sort_order'] as num?)?.toInt() ?? 0;
        final existing = await _isar.movieCategoryLocals
            .filter()
            .remoteIdEqualTo(remoteId)
            .findFirst();
        if (existing != null) mc.id = existing.id;
        await _isar.movieCategoryLocals.put(mc);
      }

      for (final row in (payload['todos'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final remoteId = m['id'] as String;
        final t = TodoLocal()
          ..remoteId = remoteId
          ..userId = userId
          ..text = m['text'] as String
          ..done = m['done'] as bool? ?? false
          ..dateKey = m['date_key'] as String? ?? ''
          ..minutesOfDay = (m['minutes_of_day'] as num?)?.toInt()
          ..priority = TodoPriority.values.byName(
            m['priority'] as String? ?? 'none',
          )
          ..createdAt = DateTime.tryParse(m['created_at'] as String? ?? '') ??
              DateTime.now()
          ..doneAt = m['done_at'] != null
              ? DateTime.tryParse(m['done_at'] as String)
              : null;
        final existing =
            await _isar.todoLocals.filter().remoteIdEqualTo(remoteId).findFirst();
        if (existing != null) t.id = existing.id;
        await _isar.todoLocals.put(t);
      }

      for (final row in (payload['focus_sessions'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final remoteId = m['id'] as String;
        final f = FocusSessionLocal()
          ..remoteId = remoteId
          ..userId = userId
          ..habitRemoteId = m['habit_remote_id'] as String
          ..targetMinutes = (m['target_minutes'] as num?)?.toInt() ?? 0
          ..seconds = (m['seconds'] as num?)?.toInt() ?? 0
          ..completed = m['completed'] as bool? ?? false
          ..startedAt = DateTime.parse(m['started_at'] as String);
        final existing = await _isar.focusSessionLocals
            .filter()
            .remoteIdEqualTo(remoteId)
            .findFirst();
        if (existing != null) f.id = existing.id;
        await _isar.focusSessionLocals.put(f);
      }
    });
  }

  Future<List<WalletLocal>> _walletsForUser(String userId, Id legacyIsarId) async {
    final all = await _isar.walletLocals.where().findAll();
    return all.where((w) => _ownsUserId(w.userId, userId, legacyIsarId)).toList();
  }

  Future<List<CategoryLocal>> _categoriesForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.categoryLocals.where().findAll();
    return all.where((c) => _ownsUserId(c.userId, userId, legacyIsarId)).toList();
  }

  Future<List<BudgetPeriodLocal>> _budgetPeriodsForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.budgetPeriodLocals.where().findAll();
    return all.where((p) => _ownsUserId(p.userId, userId, legacyIsarId)).toList();
  }

  Future<StandingSalaryLocal?> _standingSalaryForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.standingSalaryLocals.where().findAll();
    for (final s in all) {
      if (_ownsUserId(s.userId, userId, legacyIsarId)) return s;
    }
    return null;
  }

  Future<List<HabitLogLocal>> _habitLogsForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.habitLogLocals.where().findAll();
    return all.where((h) => _ownsUserId(h.userId, userId, legacyIsarId)).toList();
  }

  Future<List<MovieCategoryLocal>> _movieCategoriesForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.movieCategoryLocals.where().findAll();
    return all.where((c) => _ownsUserId(c.userId, userId, legacyIsarId)).toList();
  }

  Future<List<TodoLocal>> _todosForUser(String userId, Id legacyIsarId) async {
    final all = await _isar.todoLocals.where().findAll();
    return all.where((t) => _ownsUserId(t.userId, userId, legacyIsarId)).toList();
  }

  Future<List<FocusSessionLocal>> _focusSessionsForUser(
    String userId,
    Id legacyIsarId,
  ) async {
    final all = await _isar.focusSessionLocals.where().findAll();
    return all.where((f) => _ownsUserId(f.userId, userId, legacyIsarId)).toList();
  }

  Map<String, dynamic> _walletJson(WalletLocal w) => {
        'id': w.remoteId,
        'name': w.name,
        'currency': w.currency,
        'color_value': w.colorValue,
        'sort_order': w.sortOrder,
        'opening_balance': w.openingBalance,
      };

  Map<String, dynamic> _categoryJson(CategoryLocal c) => {
        'id': c.remoteId,
        'name': c.name,
        'is_income': c.isIncome,
        'color_value': c.colorValue,
        'sort_order': c.sortOrder,
        'icon_key': c.iconKey,
        'emoji': c.emoji,
        'is_custom': c.isCustom,
        'is_archived': c.isArchived,
      };

  Map<String, dynamic> _budgetPeriodJson(BudgetPeriodLocal p) => {
        'id': p.remoteId,
        'name': p.name,
        'limit_amount': p.limitAmount,
        'period': p.period,
        'starts_at': p.startsAt.toUtc().toIso8601String(),
        'color_value': p.colorValue,
        'archived': p.archived,
      };

  Map<String, dynamic> _standingSalaryJson(StandingSalaryLocal s) => {
        'amount': s.amount,
        'effective_from_month_key': s.effectiveFromMonthKey,
      };

  Map<String, dynamic> _habitLogJson(HabitLogLocal h) => {
        'id': h.remoteId,
        'habit_remote_id': h.habitRemoteId,
        'date_key': h.dateKey,
        'status': h.status.name,
        'current_value': h.currentValue,
      };

  Map<String, dynamic> _dailyPrayerJson(DailyPrayerLogLocal d) => {
        'id': d.remoteId,
        'date_key': d.dateKey,
        'is_excused_day': d.isExcusedDay,
        'fajr': d.fajr.name,
        'dhuhr': d.dhuhr.name,
        'asr': d.asr.name,
        'maghrib': d.maghrib.name,
        'isha': d.isha.name,
      };

  Map<String, dynamic> _movieCategoryJson(MovieCategoryLocal c) => {
        'id': c.remoteId,
        'name': c.name,
        'color_value': c.colorValue,
        'emoji': c.emoji,
        'is_custom': c.isCustom,
        'is_archived': c.isArchived,
        'sort_order': c.sortOrder,
      };

  Map<String, dynamic> _todoJson(TodoLocal t) => {
        'id': t.remoteId,
        'text': t.text,
        'done': t.done,
        'date_key': t.dateKey,
        'minutes_of_day': t.minutesOfDay,
        'priority': t.priority.name,
        'created_at': t.createdAt.toUtc().toIso8601String(),
        'done_at': t.doneAt?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _focusSessionJson(FocusSessionLocal f) => {
        'id': f.remoteId,
        'habit_remote_id': f.habitRemoteId,
        'target_minutes': f.targetMinutes,
        'seconds': f.seconds,
        'completed': f.completed,
        'started_at': f.startedAt.toUtc().toIso8601String(),
      };
}

/// Shared with [RuhhBackupCodec] for format version checks.
class RuhhBackupFormat {
  static const version = 1;
}
