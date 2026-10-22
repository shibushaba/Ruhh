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
  void Function()? onAck;

  @override
  Future<List<dynamic>?> fetchInbox(String userId) async => rows;

  @override
  Future<void> ackInbox(
    String userId,
    List<Map<String, dynamic>> results,
  ) async {
    if (failAck) throw Exception('network');
    onAck?.call();
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
  late List<String> events;
  var failPush = false;

  Future<InboxRunResult> run(AgentInboxProcessor proc) => proc.process(
    u,
    pushSnapshot: () async {
      if (failPush) throw Exception('push failed');
      events.add('push');
    },
  );

  setUp(() {
    events = [];
    failPush = false;
    t = FakeTransport();
    ap = FakeApplier();
    ledger = MemoryAppliedLedger();
    p = AgentInboxProcessor(transport: t, applier: ap, ledger: ledger);
  });

  test('no session / server without inbox: no-op', () async {
    t.rows = null;
    final r = await run(p);
    expect(r.applied, 0);
    expect(t.acks, isEmpty);
  });

  test('applies pending actions and acks them', () async {
    t.rows = [row(1), row(2, entity: 'movie')];
    final r = await run(p);
    expect(ap.applied, [id(1), id(2)]);
    expect(r.acked, isTrue);
    expect(t.acks.single.map((e) => e['status']), ['applied', 'applied']);
  });

  test('duplicate rows in one batch are applied once', () async {
    t.rows = [row(1), row(1)];
    await run(p);
    expect(ap.applied, [id(1)]);
  });

  test(
    'crash/network loss before ack: next run re-acks without re-applying',
    () async {
      t.rows = [row(1)];
      t.failAck = true;
      final first = await run(p);
      expect(first.acked, isFalse);
      t.failAck = false;
      // simulated app restart: new processor, same persisted ledger
      final p2 = AgentInboxProcessor(transport: t, applier: ap, ledger: ledger);
      final second = await run(p2);
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
      await run(p);
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
      await run(p);
      expect(t.acks.last.single['status'], 'failed');
      await run(p);
      expect(t.acks.last.single['status'], 'applied');
      expect(ap.applied, [id(1)]);
    },
  );

  test(
    'applier exception becomes failed with a generic code (no user data)',
    () async {
      t.rows = [row(1)];
      ap.decide = (_) => throw StateError('secret note text');
      await run(p);
      expect(t.acks.single.single, {
        'id': id(1),
        'status': 'failed',
        'error': 'apply_error',
      });
    },
  );

  test('local-only entity is rejected without calling the applier', () async {
    t.rows = [row(1, entity: 'wallet')];
    await run(p);
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
      await run(p);
      expect(t.acks.single.single, {
        'id': id(1),
        'status': 'rejected',
        'error': 'malformed',
      });
    },
  );

  test('ack happens only after the snapshot push', () async {
    t.rows = [row(1)];
    t.onAck = () => events.add('ack');
    await run(p);
    expect(events, ['push', 'ack']);
  });

  test(
    'push failure: nothing acked, rows stay pending, retry applies once',
    () async {
      t.rows = [row(1), row(2)];
      failPush = true;
      await expectLater(run(p), throwsException);
      expect(
        t.acks,
        isEmpty,
        reason: 'never ack before the cloud has the data',
      );
      expect(t.rows, hasLength(2));
      failPush = false;
      final r = await run(p);
      expect(r.acked, isTrue);
      expect(ap.applied, [id(1), id(2)], reason: 'not re-applied on retry');
      expect(t.acks.single.map((e) => e['status']), ['applied', 'applied']);
      expect(t.rows, isEmpty);
    },
  );

  test(
    'crash between push and ack: restart re-acks without re-applying',
    () async {
      t.rows = [row(1)];
      final batch = await p.applyPending(u);
      events.add('push'); // push succeeded, then the app was killed (no ack)
      expect(batch.results, hasLength(1));
      expect(t.acks, isEmpty);
      final p2 = AgentInboxProcessor(transport: t, applier: ap, ledger: ledger);
      final r = await run(p2);
      expect(r.acked, isTrue);
      expect(ap.applied, [id(1)]);
    },
  );

  test(
    'duplicate fetch (row still pending on a second run) applies once',
    () async {
      t.rows = [row(1)];
      await p.applyPending(u); // fetched + applied, not acked
      await p.applyPending(u); // fetched again
      expect(ap.applied, [id(1)]);
    },
  );

  test('ack failure after a good push is retried next run', () async {
    t.rows = [row(1)];
    t.failAck = true;
    final r = await run(p);
    expect(r.acked, isFalse);
    t.failAck = false;
    expect((await run(p)).acked, isTrue);
    expect(ap.applied, [id(1)]);
  });

  test('ledger is per user', () async {
    await ledger.add('a', id(1));
    expect(await ledger.load('b'), isEmpty);
  });
}
