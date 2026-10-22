import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/services/agent_inbox.dart';

const u = 'user-1';
String id(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

Map<String, dynamic> row(
  int n, {
  String entity = 'transaction',
  String op = 'create',
}) => {
  'id': id(n),
  'entity': entity,
  'op': op,
  'payload': {'amount': 10},
};

class FakeTransport implements InboxTransport {
  List<dynamic>? rows;
  final acks = <List<Map<String, dynamic>>>[];
  bool failAck = false;

  @override
  Future<List<dynamic>?> fetchInbox(String userId) async => rows;

  @override
  Future<void> ackInbox(
    String userId,
    List<Map<String, dynamic>> results,
  ) async {
    if (failAck) throw Exception('network');
    acks.add(results);
    // server marks acked rows as non-pending
    final ackedIds = results
        .where((r) => r['status'] != 'failed')
        .map((r) => r['id'])
        .toSet();
    rows = rows?.where((r) => !ackedIds.contains((r as Map)['id'])).toList();
  }
}

class FakeApplier implements InboxApplier {
  final applied = <String>[];
  InboxOutcome Function(InboxAction a)? decide;

  @override
  Future<InboxOutcome> apply(InboxAction a) async {
    final o = decide?.call(a) ?? const InboxOutcome.applied();
    if (o.kind == InboxOutcomeKind.applied) applied.add(a.id);
    return o;
  }
}

void main() {
  late FakeTransport t;
  late FakeApplier ap;
  late MemoryAppliedLedger ledger;
  late AgentInboxProcessor p;

  setUp(() {
    t = FakeTransport();
    ap = FakeApplier();
    ledger = MemoryAppliedLedger();
    p = AgentInboxProcessor(transport: t, applier: ap, ledger: ledger);
  });

  test('no session / server without inbox: no-op', () async {
    t.rows = null;
    final r = await p.process(u);
    expect(r.applied, 0);
    expect(t.acks, isEmpty);
  });

  test('applies pending actions and acks them', () async {
    t.rows = [row(1), row(2, entity: 'movie')];
    final r = await p.process(u);
    expect(ap.applied, [id(1), id(2)]);
    expect(r.acked, isTrue);
    expect(t.acks.single.map((e) => e['status']), ['applied', 'applied']);
  });

  test('duplicate rows in one batch are applied once', () async {
    t.rows = [row(1), row(1)];
    await p.process(u);
    expect(ap.applied, [id(1)]);
  });

  test(
    'crash/network loss before ack: next run re-acks without re-applying',
    () async {
      t.rows = [row(1)];
      t.failAck = true;
      final first = await p.process(u);
      expect(first.acked, isFalse);
      t.failAck = false;
      // simulated app restart: new processor, same persisted ledger
      final p2 = AgentInboxProcessor(transport: t, applier: ap, ledger: ledger);
      final second = await p2.process(u);
      expect(ap.applied, [id(1)], reason: 'applied exactly once');
      expect(second.acked, isTrue);
      expect(t.rows, isEmpty);
    },
  );

  test(
    'conflict / missing target is rejected permanently, not retried',
    () async {
      t.rows = [row(1, entity: 'habit_completion')];
      ap.decide = (_) => const InboxOutcome.rejected('habit_not_found');
      await p.process(u);
      expect(t.acks.single.single, {
        'id': id(1),
        'status': 'rejected',
        'error': 'habit_not_found',
      });
    },
  );

  test(
    'transient failure is reported as failed and retried next run',
    () async {
      t.rows = [row(1)];
      var calls = 0;
      ap.decide = (_) => ++calls == 1
          ? const InboxOutcome.failed('io')
          : const InboxOutcome.applied();
      await p.process(u);
      expect(t.acks.last.single['status'], 'failed');
      await p.process(u);
      expect(t.acks.last.single['status'], 'applied');
      expect(ap.applied, [id(1)]);
    },
  );

  test(
    'applier exception becomes failed with a generic code (no user data)',
    () async {
      t.rows = [row(1)];
      ap.decide = (_) => throw StateError('secret note text');
      await p.process(u);
      expect(t.acks.single.single, {
        'id': id(1),
        'status': 'failed',
        'error': 'apply_error',
      });
    },
  );

  test('local-only entity is rejected without calling the applier', () async {
    t.rows = [row(1, entity: 'wallet')];
    await p.process(u);
    expect(ap.applied, isEmpty);
    expect(t.acks.single.single['error'], 'entity_not_syncable');
  });

  test(
    'malformed rows with a valid id are rejected; garbage ignored',
    () async {
      t.rows = [
        {'id': id(1), 'entity': 'transaction', 'op': 'create', 'payload': 'x'},
        'garbage',
        {'id': 'not-a-uuid'},
      ];
      await p.process(u);
      expect(t.acks.single.single, {
        'id': id(1),
        'status': 'rejected',
        'error': 'malformed',
      });
    },
  );

  test('ledger is per user', () async {
    await ledger.add('a', id(1));
    expect(await ledger.load('b'), isEmpty);
  });
}
