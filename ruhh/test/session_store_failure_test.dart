import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/services/cloud_auth_client.dart';
import 'package:ruhh/core/session/secure_session_store.dart';

/// Simulates Android EncryptedSharedPreferences after a backup restore without
/// its Keystore key: every read throws; optionally writes/deletes throw too.
class ThrowingStore implements SessionStore {
  ThrowingStore({this.failWrites = false, this.failDeletes = false});
  final bool failWrites;
  final bool failDeletes;
  final values = <String, String>{};
  int deletes = 0;

  @override
  Future<String?> read(String key) async =>
      throw Exception('javax.crypto.AEADBadTagException');

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw Exception('keystore unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deletes++;
    if (failDeletes) throw Exception('keystore unavailable');
    values.remove(key);
  }
}

const userId = '00000000-0000-4000-8000-00000000000a';

void main() {
  test('unreadable token -> null, entry deleted, re-login requested', () async {
    final store = ThrowingStore();
    final client = CloudAuthClient(rpc: (_, _) async => null, store: store);
    final reauth = <String>[];
    final sub = client.reauthRequired.listen(reauth.add);
    expect(await client.tokenFor(userId), isNull);
    await Future<void>.delayed(Duration.zero);
    expect(reauth, [userId]);
    expect(store.deletes, greaterThanOrEqualTo(2));
    await sub.cancel();
  });

  test(
    'sync falls back cleanly (no crash) when the token is unreadable',
    () async {
      final calls = <String>[];
      final client = CloudAuthClient(
        rpc: (fn, _) async {
          calls.add(fn);
          return {'transactions': []};
        },
        store: ThrowingStore(),
      );
      await client.pull(userId: userId, legacyPinHash: 'h');
      expect(calls, ['ruhh_pull']); // no token -> legacy path (pre-S2)
    },
  );

  test('logout never throws even if read and delete both fail', () async {
    final client = CloudAuthClient(
      rpc: (_, _) async => throw Exception('offline'),
      store: ThrowingStore(failDeletes: true),
    );
    await expectLater(client.logout(userId), completes);
    await expectLater(client.clearSession(userId), completes);
  });

  test('login succeeds even if the token cannot be stored', () async {
    final store = ThrowingStore(failWrites: true);
    final client = CloudAuthClient(
      rpc: (_, _) async => {
        'ok': true,
        'token': 'a' * 64,
        'expires_at': '2099-01-01T00:00:00Z',
        'user_id': userId,
        'username': 'alice',
        'pin_salt': 's',
      },
      store: store,
    );
    final r = await client.login(
      username: 'alice',
      pin: '123456',
      clientVersion: '1.0.31',
    );
    expect(r.ok, isTrue);
    expect(store.values, isEmpty);
  });

  test(
    'SecureSessionStore: decrypt failure deletes the entry and throws a typed error',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const ch = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      final methods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, (call) async {
            methods.add(call.method);
            if (call.method == 'read') {
              throw PlatformException(
                code: 'Exception',
                message: 'AEADBadTagException',
              );
            }
            return null;
          });
      final store = SecureSessionStore();
      await expectLater(
        store.read('k'),
        throwsA(isA<SessionStoreReadException>()),
      );
      expect(methods, ['read', 'delete']);
      await expectLater(store.delete('k'), completes);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, null);
    },
  );
}
