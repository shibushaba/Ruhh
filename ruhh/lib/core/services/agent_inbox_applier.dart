import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/services/agent_inbox.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/habit/habit_logic.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/tmdb_service.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';

/// Applies inbox actions through the existing repositories (same code paths as
/// the UI), keyed by the inbox action id so re-application is a no-op.
class RepositoryInboxApplier implements InboxApplier {
  RepositoryInboxApplier(this._isar, this._userId);

  final Isar _isar;
  final String _userId;

  static final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static DateTime? _parseDay(Object? v) =>
      v is String && _day.hasMatch(v) ? DateTime.tryParse(v) : null;

  static String? _str(Object? v, int max) =>
      v is String && v.length <= max ? v : null;

  @override
  Future<InboxOutcome> apply(InboxAction a) async {
    final p = a.payload;
    switch ((a.entity, a.op)) {
      case ('transaction', 'create'):
        final existing = await _tx(a.id);
        if (existing != null) return const InboxOutcome.applied();
        final amount = p['amount'];
        final when = DateTime.tryParse(p['occurred_at'] as String? ?? '');
        final category = _str(p['category'], 64);
        if (amount is! num || amount <= 0 || when == null || category == null) {
          return const InboxOutcome.rejected('invalid_payload');
        }
        await BudgetRepository(_isar, _userId).add(
          remoteId: a.id,
          amount: amount.toDouble(),
          isIncome: p['is_income'] == true,
          category: category,
          account: _str(p['account'], 64) ?? 'Cash',
          title: _str(p['title'], 120) ?? '',
          note: _str(p['note'], 500) ?? '',
          occurredAt: when.toLocal(),
        );
        return const InboxOutcome.applied();

      case ('transaction', 'update'):
        final tx = await _tx(p['id']);
        if (tx == null) return const InboxOutcome.rejected('target_not_found');
        final expected = p['expected'];
        if (expected != null &&
            (expected is! Map || !expectedMatches(tx, expected))) {
          // Edited on the phone after the proposal: never overwrite the user's edit.
          return const InboxOutcome.rejected('conflict');
        }
        final amount = p['amount'];
        if (amount != null) {
          if (amount is! num || amount <= 0) {
            return const InboxOutcome.rejected('invalid_payload');
          }
          tx.amount = amount.toDouble();
        }
        final category = _str(p['category'], 64);
        if (category != null) tx.category = category;
        final title = _str(p['title'], 120);
        if (title != null) tx.title = title;
        final note = _str(p['note'], 500);
        if (note != null) tx.note = note;
        await BudgetRepository(_isar, _userId).updateTransaction(tx);
        return const InboxOutcome.applied();

      case ('transaction', 'delete'):
        final tx = await _tx(p['id']);
        if (tx == null) return const InboxOutcome.applied(); // already gone
        await BudgetRepository(_isar, _userId).delete(tx.id);
        return const InboxOutcome.applied();

      case ('habit_completion', 'create'):
        final habitId = p['habit_id'];
        final day = _parseDay(p['day']);
        if (!InboxAction.isUuid(habitId) || day == null) {
          return const InboxOutcome.rejected('invalid_payload');
        }
        final repo = HabitRepository(_isar, _userId);
        final habit = await repo.byRemoteId(habitId as String);
        if (habit == null) {
          return const InboxOutcome.rejected('habit_not_found');
        }
        if (day.isAfter(HabitLogic.dayOnly(DateTime.now()))) {
          return const InboxOutcome.rejected('future_day');
        }
        final v = await repo.valueOn(habit, day);
        if (!HabitLogic.isCompletedOn(habit, day, v, now: DateTime.now())) {
          await repo.markDone(habit, day: day); // toggle only when not done
        }
        return const InboxOutcome.applied();

      case ('prayer_log', 'upsert'):
        final day = _parseDay(p['day']);
        final prayer = PrayerName.values.asNameMap()[p['prayer']];
        final status = PrayerStatus.values.asNameMap()[p['status']];
        if (day == null || prayer == null || status == null) {
          return const InboxOutcome.rejected('invalid_payload');
        }
        await PrayerRepository(
          _isar,
          _userId,
        ).setStatus(prayer, status, day: day);
        return const InboxOutcome.applied();

      case ('movie', 'create'):
        final repo = MovieRepository(_isar, _userId, TmdbService());
        if (await repo.movieByRemoteId(a.id) != null) {
          return const InboxOutcome.applied();
        }
        final title = _str(p['title'], 200);
        final media = p['media_type'] == 'tv' ? 'tv' : 'movie';
        if (title == null || title.trim().isEmpty) {
          return const InboxOutcome.rejected('invalid_payload');
        }
        await repo.addManual(
          remoteId: a.id,
          title: title.trim(),
          status: WatchStatus.wantToWatch,
          mediaType: media,
        );
        return const InboxOutcome.applied();

      case ('movie', 'delete'):
        final repo = MovieRepository(_isar, _userId, TmdbService());
        final id = p['id'];
        if (!InboxAction.isUuid(id)) {
          return const InboxOutcome.rejected('invalid_payload');
        }
        final m = await repo.movieByRemoteId(id as String);
        if (m != null) await repo.remove(m);
        return const InboxOutcome.applied();
    }
    return const InboxOutcome.rejected('unsupported_op');
  }

  /// Precondition for agent edits: the local transaction must still have the
  /// values the proposal was created against (compared the way they are
  /// exported to the cloud: an empty title is exported as the category).
  static bool expectedMatches(TransactionLocal tx, Map<dynamic, dynamic> e) {
    final amount = e['amount'];
    if (amount is! num || (tx.amount - amount.toDouble()).abs() > 1e-9) {
      return false;
    }
    final exportedTitle = tx.title.isNotEmpty ? tx.title : tx.category;
    return tx.category == (e['category'] ?? '') &&
        exportedTitle == (e['title'] ?? '') &&
        tx.note == (e['note'] ?? '');
  }

  Future<TransactionLocal?> _tx(Object? remoteId) async {
    if (remoteId is! String) return null;
    return _isar.transactionLocals
        .filter()
        .remoteIdEqualTo(remoteId)
        .userIdEqualTo(_userId)
        .findFirst();
  }
}
