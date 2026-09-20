import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Live Supabase RPC smoke (skipped unless SUPABASE_URL + SUPABASE_ANON_KEY in env).
void main() {
  test('ruhh push empty payload does not require delete (RPC smoke)', () async {
    final url = Platform.environment['SUPABASE_URL'];
    final anon = Platform.environment['SUPABASE_ANON_KEY'];
    if (url == null ||
        anon == null ||
        url.isEmpty ||
        anon.isEmpty ||
        url.contains('example')) {
      return;
    }

    final base = url.replaceAll(RegExp(r'/+$'), '');
    final headers = {
      'apikey': anon,
      'Authorization': 'Bearer $anon',
      'Content-Type': 'application/json',
    };

    final username =
        'sync_test_${DateTime.now().millisecondsSinceEpoch % 100000000}';
    final salt = 'testsalt';
    final pin = '123456';
    final hash = sha256.convert(utf8.encode('$salt:$pin')).toString();
    final userId = _uuidV4();

    Future<Map<String, dynamic>> rpc(String fn, Map<String, dynamic> body) async {
      final res = await http.post(
        Uri.parse('$base/rest/v1/rpc/$fn'),
        headers: headers,
        body: jsonEncode(body),
      );
      expect(res.statusCode, lessThan(300), reason: '$fn: ${res.body}');
      if (res.body.isEmpty) return {};
      final decoded = jsonDecode(res.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'result': decoded};
    }

    await rpc('ruhh_register_user', {
      'p_id': userId,
      'p_username': username,
      'p_pin_hash': hash,
      'p_pin_salt': salt,
    });

    final habitId = _uuidV4();
    await rpc('ruhh_push', {
      'p_user_id': userId,
      'p_pin_hash': hash,
      'p_payload': {
        'habits': [
          {
            'id': habitId,
            'name': 'Smoke habit',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
      },
    });

    final afterSeed = await rpc('ruhh_pull', {
      'p_user_id': userId,
      'p_pin_hash': hash,
    });
    expect((afterSeed['habits'] as List?)?.length, 1);

    // Empty push must not wipe (server migration + client guard).
    await rpc('ruhh_push', {
      'p_user_id': userId,
      'p_pin_hash': hash,
      'p_payload': {'preferences': {'onboarding_complete': true}},
    });

    final afterEmpty = await rpc('ruhh_pull', {
      'p_user_id': userId,
      'p_pin_hash': hash,
    });
    expect((afterEmpty['habits'] as List?)?.length, 1);
  }, skip: !_hasSupabaseEnv());
}

bool _hasSupabaseEnv() {
  final url = Platform.environment['SUPABASE_URL'];
  final anon = Platform.environment['SUPABASE_ANON_KEY'];
  return url != null &&
      anon != null &&
      url.isNotEmpty &&
      anon.isNotEmpty &&
      !url.contains('example');
}

String _uuidV4() {
  final r = List<int>.generate(16, (i) => (i * 17 + 31) % 256);
  r[6] = (r[6] & 0x0f) | 0x40;
  r[8] = (r[8] & 0x3f) | 0x80;
  String b(int i) => r[i].toRadixString(16).padLeft(2, '0');
  return '${b(0)}${b(1)}${b(2)}${b(3)}-${b(4)}${b(5)}-${b(6)}${b(7)}-'
      '${b(8)}${b(9)}-${b(10)}${b(11)}${b(12)}${b(13)}${b(14)}${b(15)}';
}
