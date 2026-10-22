import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/services/cloud_auth_client.dart';
import 'package:ruhh/core/session/secure_session_store.dart';
import 'package:ruhh/features/settings/agent_approvals_page.dart';

const userId = '00000000-0000-4000-8000-00000000000a';
const token =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const hash = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

Map<String, dynamic> row() => {
  'id': '00000000-0000-4000-8000-000000000001',
  'action': 'tx.delete',
  'summary': 'Delete one transaction',
  'params': <String, dynamic>{},
  'params_hash': hash,
  'target': {
    'kind': 'transaction',
    'amount': 10,
    'is_income': false,
    'category': 'Food',
    'title': '',
    'occurred_at': '2026-10-22T06:00:00Z',
  },
  'expires_at': '2026-10-22T06:15:00Z',
};

void main() {
  late List<(String, Map<String, dynamic>)> calls;
  late Map<String, dynamic Function(Map<String, dynamic>)> handlers;
  late MemorySessionStore store;
  late CloudAuthClient client;

  setUp(() async {
    calls = [];
    handlers = {};
    store = MemorySessionStore();
    client = CloudAuthClient(
      rpc: (fn, p) async {
        calls.add((fn, p));
        final h = handlers[fn];
        if (h == null) throw const CloudRpcException('PGRST202', 'missing');
        return h(p);
      },
      store: store,
      now: () => DateTime.utc(2026, 10, 22),
    );
    await store.write(CloudAuthClient.tokenKey(userId), token);
  });

  test('list uses the user session token, parses proposals', () async {
    handlers['ruhh_proposals_list_v2'] = (_) => [row(), 'garbage'];
    final l = await client.listProposals(userId);
    expect(l, hasLength(1));
    expect(l.single.paramsHash, hash);
    expect(calls.single.$2, {'p_token': token});
  });

  test(
    'approve sends the exact id + params_hash with the session token',
    () async {
      handlers['ruhh_proposal_decide_v2'] = (_) => {'status': 'executed'};
      final p = AgentProposal.tryParse(row())!;
      final r = await client.decideProposal(userId, p, approve: true);
      expect(r, ProposalDecisionResult.executed);
      expect(calls.single.$1, 'ruhh_proposal_decide_v2');
      expect(calls.single.$2, {
        'p_token': token,
        'p_proposal_id': p.id,
        'p_params_hash': hash,
        'p_decision': 'approve',
      });
    },
  );

  test('stale edit comes back as a committed conflict rejection', () async {
    handlers['ruhh_proposal_decide_v2'] = (_) => {
      'status': 'rejected',
      'reason': 'conflict',
    };
    final p = AgentProposal.tryParse(row())!;
    expect(
      await client.decideProposal(userId, p, approve: true),
      ProposalDecisionResult.conflict,
    );
  });

  test('server rejections map to safe results', () async {
    final p = AgentProposal.tryParse(row())!;
    for (final (msg, want) in [
      ('proposal_expired', ProposalDecisionResult.expired),
      ('proposal_already_decided', ProposalDecisionResult.alreadyDecided),
      ('proposal_hash_mismatch', ProposalDecisionResult.changed),
      ('proposal_conflict', ProposalDecisionResult.conflict),
      ('target_not_found', ProposalDecisionResult.targetMissing),
      ('proposal_not_found', ProposalDecisionResult.notFound),
    ]) {
      handlers['ruhh_proposal_decide_v2'] = (_) =>
          throw CloudRpcException('P0001', msg);
      expect(
        await client.decideProposal(userId, p, approve: true),
        want,
        reason: msg,
      );
    }
  });

  test('without a session nothing is sent and re-login is required', () async {
    await client.clearSession(userId);
    final p = AgentProposal.tryParse(row())!;
    expect(
      await client.decideProposal(userId, p, approve: true),
      ProposalDecisionResult.sessionRequired,
    );
    expect(calls, isEmpty);
    expect(
      () => client.listProposals(userId),
      throwsA(isA<CloudSyncAuthException>()),
    );
  });

  test('invalid session clears the token', () async {
    handlers['ruhh_proposal_decide_v2'] = (_) =>
        throw const CloudRpcException('28000', 'session_invalid');
    final p = AgentProposal.tryParse(row())!;
    expect(
      await client.decideProposal(userId, p, approve: false),
      ProposalDecisionResult.sessionRequired,
    );
    expect(store.values, isEmpty);
  });

  test('describeTarget is readable and handles a missing target', () {
    final p = AgentProposal.tryParse(row())!;
    expect(describeTarget(p), contains('Food'));
    expect(describeTarget(p), contains('-10'));
    final gone = AgentProposal.tryParse({...row(), 'target': null})!;
    expect(describeTarget(gone), contains('no longer exists'));
  });
}
