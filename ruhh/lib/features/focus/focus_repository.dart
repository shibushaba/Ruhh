import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/focus_session_local.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:uuid/uuid.dart';

class FocusRepository {
  FocusRepository(this._isar, this._userId);

  final Isar _isar;
  final String _userId;

  Future<List<FocusSessionLocal>> allSessions() => _isar.focusSessionLocals
      .filter()
      .userIdEqualTo(_userId)
      .sortByStartedAtDesc()
      .findAll();

  Future<int> totalMinutes({DateTime? since}) async {
    final rows = since == null
        ? await allSessions()
        : await _isar.focusSessionLocals
            .filter()
            .userIdEqualTo(_userId)
            .startedAtGreaterThan(since)
            .findAll();
    return rows.fold<int>(0, (a, s) => a + s.seconds ~/ 60);
  }

  Future<void> saveSession({
    required String habitRemoteId,
    required int targetMinutes,
    required int seconds,
    required bool completed,
  }) async {
    if (seconds < 30) return;
    await _isar.writeTxn(() => _isar.focusSessionLocals.put(
          FocusSessionLocal()
            ..remoteId = const Uuid().v4()
            ..userId = _userId
            ..habitRemoteId = habitRemoteId
            ..targetMinutes = targetMinutes
            ..seconds = seconds
            ..completed = completed
            ..startedAt = DateTime.now().subtract(Duration(seconds: seconds)),
        ));
  }
}

final focusRepositoryProvider = FutureProvider<FocusRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  return FocusRepository(isar, user.supabaseId ?? user.id.toString());
});
