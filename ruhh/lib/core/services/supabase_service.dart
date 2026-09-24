import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ruhh/features/auth/username_availability.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthProfile {
  const SupabaseAuthProfile({
    required this.id,
    required this.username,
    required this.pinHash,
    required this.pinSalt,
  });

  final String id;
  final String username;
  final String pinHash;
  final String pinSalt;

  factory SupabaseAuthProfile.fromJson(Map<String, dynamic> json) {
    return SupabaseAuthProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      pinHash: json['pin_hash'] as String,
      pinSalt: json['pin_salt'] as String,
    );
  }
}

class SupabasePushResult {
  const SupabasePushResult({required this.ok, this.errorMessage});

  final bool ok;
  final String? errorMessage;
}

class SupabaseService {
  static bool _initialized = false;

  static bool _hasValidConfig(String? url, String? key) {
    if (url == null || key == null || url.isEmpty || key.isEmpty) {
      return false;
    }
    if (!url.startsWith('https://') || !url.contains('supabase')) {
      return false;
    }
    if (key.contains('your_') || key.length < 40) {
      return false;
    }
    return true;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (!_hasValidConfig(url, key)) {
      return;
    }
    await Supabase.initialize(url: url!, anonKey: key!);
    _initialized = true;
  }

  static SupabaseClient? get client =>
      _initialized ? Supabase.instance.client : null;

  static Future<bool> isUsernameAvailable(String username) async {
    final result = await checkUsernameAvailability(username);
    return result == UsernameAvailability.available ||
        result == UsernameAvailability.offlineAvailable;
  }

  /// Live signup check: local Isar + Supabase RPC.
  static Future<UsernameAvailability> checkUsernameAvailability(
    String username,
  ) async {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.length < 3) {
      return UsernameAvailability.tooShort;
    }
    final c = client;
    if (c == null) {
      return UsernameAvailability.offlineAvailable;
    }
    try {
      final available = await c.rpc<bool>(
        'ruhh_is_username_available',
        params: {'p_username': trimmed},
      );
      if (available == true) return UsernameAvailability.available;
      return UsernameAvailability.taken;
    } catch (_) {
      // Network or misconfigured cloud — still allow local signup if not taken on device.
      return UsernameAvailability.offlineAvailable;
    }
  }

  /// Returns true when user row exists on Supabase (or offline skip).
  static Future<bool> registerUser({
    required String id,
    required String username,
    required String pinHash,
    required String pinSalt,
  }) async {
    final c = client;
    if (c == null) return true;
    try {
      await c.rpc(
        'ruhh_register_user',
        params: {
          'p_id': id,
          'p_username': username,
          'p_pin_hash': pinHash,
          'p_pin_salt': pinSalt,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<SupabaseAuthProfile?> fetchAuthProfile(String username) async {
    final c = client;
    if (c == null) return null;
    try {
      final raw = await c.rpc(
        'ruhh_fetch_auth_profile',
        params: {'p_username': username},
      );
      if (raw == null) return null;
      if (raw is! Map) return null;
      final map = Map<String, dynamic>.from(raw);
      if (map['id'] == null) return null;
      return SupabaseAuthProfile.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> pull({
    required String userId,
    required String pinHash,
  }) async {
    final c = client;
    if (c == null) return null;
    try {
      final raw = await c.rpc(
        'ruhh_pull',
        params: {'p_user_id': userId, 'p_pin_hash': pinHash},
      );
      if (raw == null) return null;
      return Map<String, dynamic>.from(raw as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<SupabasePushResult> push({
    required String userId,
    required String pinHash,
    required Map<String, dynamic> payload,
  }) async {
    final c = client;
    if (c == null) {
      return const SupabasePushResult(
        ok: false,
        errorMessage: 'Cloud backup is not configured in this build.',
      );
    }
    try {
      await c.rpc(
        'ruhh_push',
        params: {
          'p_user_id': userId,
          'p_pin_hash': pinHash,
          'p_payload': payload,
        },
      );
      return const SupabasePushResult(ok: true);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('ruhh_push failed: ${e.message} (${e.code})');
      }
      final msg = e.message.toLowerCase();
      if (msg.contains('unauthorized')) {
        return const SupabasePushResult(
          ok: false,
          errorMessage:
              'Account verification failed — log out and sign in again with your PIN.',
        );
      }
      if (msg.contains('invalid input syntax for type uuid')) {
        return const SupabasePushResult(
          ok: false,
          errorMessage:
              'Backup data format error — update the app and sync again.',
        );
      }
      return SupabasePushResult(
        ok: false,
        errorMessage: e.message.isNotEmpty
            ? e.message
            : 'Could not upload to cloud backup.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('ruhh_push failed: $e');
      return const SupabasePushResult(
        ok: false,
        errorMessage: 'Could not upload to cloud backup.',
      );
    }
  }
}
