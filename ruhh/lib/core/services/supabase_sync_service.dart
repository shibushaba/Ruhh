import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/supabase_service.dart';

class SupabaseSyncService {
  SupabaseSyncService(this._isar);

  final Isar _isar;

  Future<void> syncUser(UserLocal user, String pinHash) async {
    final userId = user.supabaseId;
    if (userId == null || userId.isEmpty) return;

    final payload = await _exportPayload(userId);
    await SupabaseService.push(userId: userId, pinHash: pinHash, payload: payload);

    final remote = await SupabaseService.pull(userId: userId, pinHash: pinHash);
    if (remote != null) {
      await _importPayload(userId, remote);
    }
  }

  Future<Map<String, dynamic>> _exportPayload(String userId) async {
    final txs = await _isar.transactionLocals.filter().userIdEqualTo(userId).findAll();
    final habits = await _isar.habitLocals.filter().userIdEqualTo(userId).findAll();
    final completions =
        await _isar.habitCompletionLocals.filter().userIdEqualTo(userId).findAll();
    final prayers = await _isar.prayerLogLocals.filter().userIdEqualTo(userId).findAll();
    final movies = await _isar.movieLocals.filter().userIdEqualTo(userId).findAll();

    return {
      'transactions': txs.map(_transactionJson).toList(),
      'habits': habits.map(_habitJson).toList(),
      'habit_completions': completions.map(_completionJson).toList(),
      'prayer_logs': prayers.map(_prayerJson).toList(),
      'movies': movies.map(_movieJson).toList(),
    };
  }

  Future<void> _importPayload(String userId, Map<String, dynamic> remote) async {
    await _isar.writeTxn(() async {
      for (final row in (remote['transactions'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final tx = TransactionLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..amount = (m['amount'] as num).toDouble()
          ..isIncome = m['is_income'] as bool? ?? false
          ..category = m['category'] as String
          ..account = m['account'] as String? ?? 'Cash'
          ..note = m['note'] as String? ?? ''
          ..occurredAt = DateTime.parse(m['occurred_at'] as String);
        final existing = await _isar.transactionLocals
            .filter()
            .remoteIdEqualTo(tx.remoteId)
            .findFirst();
        if (existing != null) tx.id = existing.id;
        await _isar.transactionLocals.put(tx);
      }

      for (final row in (remote['habits'] as List? ?? [])) {
        final m = row as Map<String, dynamic>;
        final h = HabitLocal()
          ..remoteId = m['id'] as String
          ..userId = userId
          ..name = m['name'] as String
          ..colorValue = m['color_value'] as int
          ..frequency = m['frequency'] as String? ?? 'daily'
          ..targetPerDay = m['target_per_day'] as int? ?? 1
          ..reminderMinute = m['reminder_minute'] as int?
          ..archived = m['archived'] as bool? ?? false
          ..createdAt = DateTime.tryParse(m['updated_at'] as String? ?? '') ??
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
          ..mediaType = m['media_type'] as String? ?? 'movie'
          ..watchStatus = WatchStatus.values.byName(m['watch_status'] as String)
          ..overview = m['overview'] as String?
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
        'category': t.category,
        'account': t.account,
        'note': t.note,
        'occurred_at': t.occurredAt.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Map<String, dynamic> _habitJson(HabitLocal h) => {
        'id': h.remoteId,
        'name': h.name,
        'color_value': h.colorValue,
        'frequency': h.frequency,
        'target_per_day': h.targetPerDay,
        'reminder_minute': h.reminderMinute,
        'archived': h.archived,
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
        'media_type': m.mediaType,
        'watch_status': m.watchStatus.name,
        'overview': m.overview,
        'updated_at': m.addedAt.toUtc().toIso8601String(),
      };
}
