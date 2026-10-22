import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/services/cloud_auth_client.dart';
import 'package:ruhh/core/session/secure_session_store.dart';

class FakeRpc {
  final calls = <(String, Map<String, dynamic>)>[];
  final handlers = <String, dynamic Function(Map<String, dynamic>)>{};

  Future<dynamic> call(String fn, Map<String, dynamic> params) async {
    calls.add((fn, params));
    final h = handlers[fn];
    if (h == null) {
      throw const CloudRpcException('PGRST202', 'Could not find the function');
    }
    return h(params);
  }
}

const userId = '00000000-0000-4000-8000-00000000000a';
const token =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Map<String, dynamic> okLogin({String exp = '2099-01-01T00:00:00Z'}) => {
  'ok': true,
  'token': token,
  'expires_at': exp,
  'user_id': userId,
  'username': 'alice',
  'pin_salt': 'salt',
  'min_supported_version': '0.0.0',
};

void main() {
  late FakeRpc rpc;
  late MemorySessionStore store;
  late CloudAuthClient client;
  var now = DateTime.utc(2026, 10, 22);

  setUp(() {
    rpc = FakeRpc();
    store = MemorySessionStore();
    now = DateTime.utc(2026, 10, 22);
    client = CloudAuthClient(rpc: rpc.call, store: store, now: () => now);
  });

  group('account binding', () {
    test(
      'session for a different cloud account is discarded and revoked',
      () async {
        rpc.handlers['ruhh_login'] = (_) => okLogin();
        rpc.handlers['ruhh_logout'] = (_) => true;
        final r = await client.login(
          username: 'alice',
          pin: '123456',
          clientVersion: '1.0.31',
          expectedUserId: '00000000-0000-4000-8000-0000000000ff',
        );
        expect(r.ok, isFalse);
        expect(r.error, CloudAuthError.accountMismatch);
        expect(store.values, isEmpty);
        expect(rpc.calls.last.$1, 'ruhh_logout');
        expect(rpc.calls.last.$2, {'p_token': token});
      },
    );

    test('username mismatch in the response is rejected', () async {
      rpc.handlers['ruhh_login'] = (_) => okLogin();
      rpc.handlers['ruhh_logout'] = (_) => true;
      final r = await client.login(
        username: 'bob',
        pin: '123456',
        clientVersion: '1.0.31',
      );
      expect(r.error, CloudAuthError.accountMismatch);
      expect(store.values, isEmpty);
    });

    test('matching local id stores the session', () async {
      rpc.handlers['ruhh_login'] = (_) => okLogin();
      final r = await client.login(
        username: ' Alice ',
        pin: '123456',
        clientVersion: '1.0.31',
        expectedUserId: userId,
      );
      expect(r.ok, isTrue);
      expect(store.values[CloudAuthClient.tokenKey(userId)], token);
    });

    test('register returning another id is rejected', () async {
      rpc.handlers['ruhh_register_user_v2'] = (_) => okLogin();
      rpc.handlers['ruhh_logout'] = (_) => true;
      final r = await client.register(
        id: '00000000-0000-4000-8000-0000000000ff',
        username: 'alice',
        pin: '123456',
        clientVersion: '1.0.31',
      );
      expect(r.error, CloudAuthError.accountMismatch);
      expect(store.values, isEmpty);
    });
  });

  group('login', () {
    test('success stores token in session store, not the PIN', () async {
      rpc.handlers['ruhh_login'] = (_) => okLogin();
      final r = await client.login(
        username: 'alice',
        pin: '123456',
        clientVersion: '1.0.31',
      );
      expect(r.ok, isTrue);
      expect(store.values[CloudAuthClient.tokenKey(userId)], token);
      expect(store.values.values.any((v) => v.contains('123456')), isFalse);
    });

    test(
      'wrong PIN / unknown user map to invalidCredentials, nothing stored',
      () async {
        rpc.handlers['ruhh_login'] = (_) => {
          'ok': false,
          'error': 'invalid_credentials',
        };
        final r = await client.login(
          username: 'x',
          pin: '000000',
          clientVersion: '1.0.31',
        );
        expect(r.error, CloudAuthError.invalidCredentials);
        expect(store.values, isEmpty);
      },
    );

    test('lockout and update_required are surfaced', () async {
      rpc.handlers['ruhh_login'] = (_) => {'ok': false, 'error': 'locked_out'};
      expect(
        (await client.login(username: 'a', pin: '1', clientVersion: '1')).error,
        CloudAuthError.lockedOut,
      );
      rpc.handlers['ruhh_login'] = (_) => {
        'ok': false,
        'error': 'update_required',
        'min_supported_version': '1.0.31',
      };
      final r = await client.login(
        username: 'a',
        pin: '1',
        clientVersion: '1.0.0',
      );
      expect(r.error, CloudAuthError.updateRequired);
      expect(r.minSupportedVersion, '1.0.31');
    });

    test(
      'server without v2 -> serverOutdated (documented legacy fallback)',
      () async {
        final r = await client.login(
          username: 'a',
          pin: '123456',
          clientVersion: '1.0.31',
        );
        expect(r.error, CloudAuthError.serverOutdated);
        expect(client.serverSupportsV2, isFalse);
      },
    );

    test('network error -> network', () async {
      rpc.handlers['ruhh_login'] = (_) => throw Exception('socket');
      expect(
        (await client.login(username: 'a', pin: '1', clientVersion: '1')).error,
        CloudAuthError.network,
      );
    });

    test('not configured -> notConfigured', () async {
      client.rpc = null;
      expect(
        (await client.login(username: 'a', pin: '1', clientVersion: '1')).error,
        CloudAuthError.notConfigured,
      );
    });
  });

  group('sync credential routing', () {
    test('with token: uses pull_v2 and never sends the PIN hash', () async {
      await store.write(CloudAuthClient.tokenKey(userId), token);
      rpc.handlers['ruhh_pull_v2'] = (_) => {'transactions': []};
      await client.pull(userId: userId, legacyPinHash: 'LEGACYHASH');
      expect(rpc.calls.single.$1, 'ruhh_pull_v2');
      expect(rpc.calls.single.$2.toString().contains('LEGACYHASH'), isFalse);
    });

    test('with token: push_v2 sends payload with token only', () async {
      await store.write(CloudAuthClient.tokenKey(userId), token);
      rpc.handlers['ruhh_push_v2'] = (_) => null;
      await client.push(
        userId: userId,
        legacyPinHash: 'LEGACYHASH',
        payload: {'movies': []},
      );
      expect(rpc.calls.single.$1, 'ruhh_push_v2');
      expect(rpc.calls.single.$2.keys, containsAll(['p_token', 'p_payload']));
      expect(rpc.calls.single.$2.toString().contains('LEGACYHASH'), isFalse);
    });

    test('no token: legacy v1 (old sessions keep syncing until S2)', () async {
      rpc.handlers['ruhh_pull'] = (_) => {'transactions': []};
      await client.pull(userId: userId, legacyPinHash: 'h');
      expect(rpc.calls.single.$1, 'ruhh_pull');
    });

    test(
      'token but server lacks v2: falls back to v1 once, then remembers',
      () async {
        await store.write(CloudAuthClient.tokenKey(userId), token);
        rpc.handlers['ruhh_pull'] = (_) => {'transactions': []};
        await client.pull(userId: userId, legacyPinHash: 'h');
        await client.pull(userId: userId, legacyPinHash: 'h');
        expect(rpc.calls.map((c) => c.$1), [
          'ruhh_pull_v2',
          'ruhh_pull',
          'ruhh_pull',
        ]);
      },
    );

    test(
      'revoked/expired server session: token cleared, reauth signalled, no v1 retry',
      () async {
        await store.write(CloudAuthClient.tokenKey(userId), token);
        rpc.handlers['ruhh_pull_v2'] = (_) =>
            throw const CloudRpcException('28000', 'session_invalid');
        rpc.handlers['ruhh_pull'] = (_) => {'transactions': []};
        final events = <String>[];
        final sub = client.reauthRequired.listen(events.add);
        await expectLater(
          client.pull(userId: userId, legacyPinHash: 'h'),
          throwsA(
            isA<CloudSyncAuthException>().having(
              (e) => e.reauthRequired,
              'reauth',
              true,
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(events, [userId]);
        expect(store.values, isEmpty);
        expect(rpc.calls.map((c) => c.$1), ['ruhh_pull_v2']);
        await sub.cancel();
      },
    );

    test('locally expired token is discarded before use', () async {
      rpc.handlers['ruhh_login'] = (_) => okLogin(exp: '2026-10-21T00:00:00Z');
      await client.login(
        username: 'alice',
        pin: '123456',
        clientVersion: '1.0.31',
      );
      expect(await client.tokenFor(userId), isNull);
      expect(store.values, isEmpty);
    });

    test('after S2 (v1 revoked): asks user to sign in again', () async {
      rpc.handlers['ruhh_push'] = (_) => throw const CloudRpcException(
        '42501',
        'permission denied for function ruhh_push',
      );
      await expectLater(
        client.push(userId: userId, legacyPinHash: 'h', payload: {}),
        throwsA(isA<CloudSyncAuthException>()),
      );
    });

    test('other server errors propagate unchanged', () async {
      await store.write(CloudAuthClient.tokenKey(userId), token);
      rpc.handlers['ruhh_push_v2'] = (_) => throw const CloudRpcException(
        '22P02',
        'invalid input syntax for type uuid',
      );
      await expectLater(
        client.push(userId: userId, legacyPinHash: 'h', payload: {}),
        throwsA(isA<CloudRpcException>()),
      );
    });
  });

  group('logout', () {
    test('revokes on server and clears local token', () async {
      rpc.handlers['ruhh_login'] = (_) => okLogin();
      rpc.handlers['ruhh_logout'] = (_) => true;
      await client.login(
        username: 'alice',
        pin: '123456',
        clientVersion: '1.0.31',
      );
      await client.logout(userId);
      expect(rpc.calls.last.$1, 'ruhh_logout');
      expect(rpc.calls.last.$2['p_token'], token);
      expect(store.values, isEmpty);
    });

    test('offline logout still clears local token', () async {
      await store.write(CloudAuthClient.tokenKey(userId), token);
      rpc.handlers['ruhh_logout'] = (_) => throw Exception('offline');
      await client.logout(userId);
      expect(store.values, isEmpty);
    });
  });

  test('isVersionLower', () {
    expect(isVersionLower('1.0.30+31', '1.0.31'), isTrue);
    expect(isVersionLower('1.0.31', '1.0.31'), isFalse);
    expect(isVersionLower('1.1.0', '1.0.99'), isFalse);
    expect(isVersionLower('garbage', '0.0.1'), isTrue);
  });
}
