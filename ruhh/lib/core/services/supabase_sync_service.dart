import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/services/supabase_service.dart';

class SupabaseSyncService {
  SupabaseSyncService(this._isar);

  final Isar _isar;

  Future<void> syncUser(UserLocal user, String pinHash) async {
    final userId = user.supabaseId;
    if (userId == null || userId.isEmpty) return;

    final payload = await _exportPayload(user, userId);
    await SupabaseService.push(userId: userId, pinHash: pinHash, payload: payload);

    final remote = await SupabaseService.pull(userId: userId, pinHash: pinHash);
    if (remote != null) {
      await _importPayload(userId, remote);
    }
  }

  Future<Map<String, dynamic>> _exportPayload(UserLocal user, String userId) async {
    final txs = await _isar.transactionLocals.filter().userIdEqualTo(userId).findAll();
    final habits = await _isar.habitLocals.filter().userIdEqualTo(userId).findAll();
    final completions =
        await _isar.habitCompletionLocals.filter().userIdEqualTo(userId).findAll();
    final prayers = await _isar.prayerLogLocals.filter().userIdEqualTo(userId).findAll();
    final movies = await _isar.movieLocals.filter().userIdEqualTo(userId).findAll();
    final objectives =
        await _isar.objectiveLocals.filter().userIdEqualTo(userId).findAll();
    final categoryLimits = await _isar.categoryBudgetLimitLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();

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

  Future<void> _importPayload(String userId, Map<String, dynamic> remote) async {
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
        final tx = TransactionLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..amount = (m['amount'] as num).toDouble()
          ..isIncome = m['is_income'] as bool? ?? false
          ..title = m['title'] as String? ?? ''
          ..category = m['category'] as String
          ..account = m['account'] as String? ?? 'Cash'
          ..note = m['note'] as String? ?? ''
          ..occurredAt = DateTime.parse(m['occurred_at'] as String)
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

      for (final row in (remote['objectives'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final o = ObjectiveLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..name = m['name'] as String
          ..targetAmount = (m['target_amount'] as num).toDouble()
          ..kind = m['kind'] as String? ?? 'savings'
          ..walletName = m['wallet_name'] as String? ?? 'Cash'
          ..colorValue = m['color_value'] as int? ?? 0
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

      for (final row in (remote['category_budget_limits'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final l = CategoryBudgetLimitLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..budgetRemoteId = m['budget_remote_id'] as String
          ..categoryName = m['category_name'] as String
          ..limitAmount = (m['limit_amount'] as num).toDouble();
        final existing = await _isar.categoryBudgetLimitLocals
            .filter()
            .remoteIdEqualTo(l.remoteId)
            .findFirst();
        if (existing != null) l.id = existing.id;
        await _isar.categoryBudgetLimitLocals.put(l);
      }

      for (final row in (remote['habits'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final h = HabitLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..name = m['name'] as String
          ..colorValue = (m['color_value'] as num?)?.toInt() ?? 0xFFF97316
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
          ..createdAt = DateTime.tryParse(m['created_at'] as String? ?? '') ??
              DateTime.tryParse(m['updated_at'] as String? ?? '') ??
              DateTime.now();
        final existing =
            await _isar.habitLocals.filter().remoteIdEqualTo(h.remoteId).findFirst();
        if (existing != null) h.id = existing.id;
        await _isar.habitLocals.put(h);
      }

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
          ..addedAt = DateTime.tryParse(m['updated_at'] as String? ?? '') ??
              DateTime.now();
        final existing =
            await _isar.movieLocals.filter().remoteIdEqualTo(mv.remoteId).findFirst();
        if (existing != null) mv.id = existing.id;
        await _isar.movieLocals.put(mv);
      }
    });
  }

  Map<String, dynamic> _transactionJson(TransactionLocal t) => {
        'id': t.remoteId,
        'amount': t.amount,
        'is_income': t.isIncome,
        'title': t.title,
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
        'color_value': o.colorValue,
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
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> _habitJson(HabitLocal h) => {
        'id': h.remoteId,
        'name': h.name,
        'color_value': h.colorValue,
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
        'id': p.remoteId,
        'day': p.day.toIso8601String().split('T').first,
        'prayer': p.prayer.name,
        'status': p.status.name,
      };

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
        'updated_at': m.addedAt.toUtc().toIso8601String(),
      };

  List<int> _intList(dynamic value) {
    if (value is List) {
      return value.map((e) => (e as num).toInt()).toList();
    }
    return [];
  }
}
