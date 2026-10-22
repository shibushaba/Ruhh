import 'package:shared_preferences/shared_preferences.dart';

/// Entities the cloud can carry. Local-only modules (wallets, categories, budget
/// periods, movie categories, todos, focus) are deliberately absent.
const inboxEntities = {
  'transaction',
  'habit_completion',
  'prayer_log',
  'movie',
};

class InboxAction {
  const InboxAction({
    required this.id,
    required this.entity,
    required this.op,
    required this.payload,
  });

  final String id;
  final String entity;
  final String op;
  final Map<String, dynamic> payload;

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isUuid(Object? v) => v is String && _uuid.hasMatch(v);

  /// Returns null when the row is malformed (it is then rejected, not retried).
  static InboxAction? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final entity = raw['entity'];
    final op = raw['op'];
    final payload = raw['payload'];
    if (!isUuid(id) || entity is! String || op is! String || payload is! Map) {
      return null;
    }
    return InboxAction(
      id: id as String,
      entity: entity,
      op: op,
      payload: Map<String, dynamic>.from(payload),
    );
  }
}

enum InboxOutcomeKind { applied, rejected, failed }

class InboxOutcome {
  const InboxOutcome.applied() : kind = InboxOutcomeKind.applied, code = null;
  const InboxOutcome.rejected(this.code) : kind = InboxOutcomeKind.rejected;
  const InboxOutcome.failed(this.code) : kind = InboxOutcomeKind.failed;

  final InboxOutcomeKind kind;

  /// Short machine code only (never user data) — it is stored server-side.
  final String? code;
}

/// Applies one action into local storage through the app's repositories.
/// Implementations MUST be idempotent per [InboxAction.id].
abstract class InboxApplier {
  Future<InboxOutcome> apply(InboxAction action);
}

/// Remembers which action ids were applied locally, so a crash between local
/// apply and server ack never applies an action twice.
abstract class AppliedLedger {
  Future<Set<String>> load(String userId);
  Future<void> add(String userId, String actionId);
}

class PrefsAppliedLedger implements AppliedLedger {
  static const maxEntries = 1000;
  static String key(String userId) => 'ruhh_inbox_applied:$userId';

  @override
  Future<Set<String>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key(userId)) ?? const []).toSet();
  }

  @override
  Future<void> add(String userId, String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key(userId)) ?? <String>[];
    if (list.contains(actionId)) return;
    list.add(actionId);
    if (list.length > maxEntries) list.removeRange(0, list.length - maxEntries);
    await prefs.setStringList(key(userId), list);
  }
}

class MemoryAppliedLedger implements AppliedLedger {
  final Map<String, Set<String>> ids = {};

  @override
  Future<Set<String>> load(String userId) async => {...?ids[userId]};

  @override
  Future<void> add(String userId, String actionId) async =>
      (ids[userId] ??= {}).add(actionId);
}

/// Server side of the inbox (implemented by CloudAuthClient).
abstract class InboxTransport {
  /// null = unavailable (no session, server without inbox, offline).
  Future<List<dynamic>?> fetchInbox(String userId);
  Future<void> ackInbox(String userId, List<Map<String, dynamic>> results);
}

class InboxRunResult {
  const InboxRunResult(this.applied, this.rejected, this.failed, this.acked);
  final int applied;
  final int rejected;
  final int failed;
  final bool acked;
}

/// Outcome of applying one fetched batch locally; acknowledged only after the
/// snapshot containing the applied records has been pushed successfully.
class InboxBatch {
  const InboxBatch(this.results, this.applied, this.rejected, this.failed);
  static const empty = InboxBatch([], 0, 0, 0);

  final List<Map<String, dynamic>> results;
  final int applied;
  final int rejected;
  final int failed;
  bool get isEmpty => results.isEmpty;
}

/// Order per sync: [applyPending] (Isar) -> export + push snapshot ->
/// [acknowledge]. If the push fails nothing is acked: the rows stay pending on
/// the server and the next run re-acks them from the ledger without
/// re-applying (creates are also keyed by remoteId = action id).
class AgentInboxProcessor {
  AgentInboxProcessor({
    required this.transport,
    required this.applier,
    required this.ledger,
  });

  final InboxTransport transport;
  final InboxApplier applier;
  final AppliedLedger ledger;

  Future<InboxBatch> applyPending(String userId) async {
    final rows = await transport.fetchInbox(userId);
    if (rows == null || rows.isEmpty) return InboxBatch.empty;
    final done = await ledger.load(userId);
    final results = <Map<String, dynamic>>[];
    final seen = <String>{};
    var applied = 0, rejected = 0, failed = 0;

    for (final raw in rows) {
      final action = InboxAction.tryParse(raw);
      if (action == null) {
        final id = raw is Map ? raw['id'] : null;
        if (InboxAction.isUuid(id) && seen.add(id as String)) {
          results.add({'id': id, 'status': 'rejected', 'error': 'malformed'});
          rejected++;
        }
        continue;
      }
      if (!seen.add(action.id)) continue; // duplicate within a batch
      if (done.contains(action.id)) {
        results.add({'id': action.id, 'status': 'applied'}); // re-ack only
        applied++;
        continue;
      }
      if (!inboxEntities.contains(action.entity)) {
        await ledger.add(userId, action.id);
        results.add({
          'id': action.id,
          'status': 'rejected',
          'error': 'entity_not_syncable',
        });
        rejected++;
        continue;
      }
      InboxOutcome outcome;
      try {
        outcome = await applier.apply(action);
      } catch (_) {
        outcome = const InboxOutcome.failed('apply_error');
      }
      switch (outcome.kind) {
        case InboxOutcomeKind.applied:
          await ledger.add(userId, action.id);
          results.add({'id': action.id, 'status': 'applied'});
          applied++;
        case InboxOutcomeKind.rejected:
          await ledger.add(userId, action.id); // permanent: never retry locally
          results.add({
            'id': action.id,
            'status': 'rejected',
            'error': outcome.code,
          });
          rejected++;
        case InboxOutcomeKind.failed:
          results.add({
            'id': action.id,
            'status': 'failed',
            'error': outcome.code,
          });
          failed++;
      }
    }
    return InboxBatch(results, applied, rejected, failed);
  }

  /// Call only after a successful snapshot push. Never throws; false = retry
  /// next run (the ledger prevents re-application).
  Future<bool> acknowledge(String userId, InboxBatch batch) async {
    if (batch.isEmpty) return false;
    try {
      await transport.ackInbox(userId, batch.results);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// apply -> [pushSnapshot] -> ack. A failing push propagates and nothing is acked.
  Future<InboxRunResult> process(
    String userId, {
    required Future<void> Function() pushSnapshot,
  }) async {
    final batch = await applyPending(userId);
    await pushSnapshot();
    final acked = await acknowledge(userId, batch);
    return InboxRunResult(batch.applied, batch.rejected, batch.failed, acked);
  }
}
