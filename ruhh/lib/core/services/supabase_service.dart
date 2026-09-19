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

class SupabaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || key == null || url.isEmpty || key.isEmpty) {
      return;
    }
    await Supabase.initialize(url: url, anonKey: key);
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
      return UsernameAvailability.checkFailed;
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

  static Future<void> push({
    required String userId,
    required String pinHash,
    required Map<String, dynamic> payload,
  }) async {
    final c = client;
    if (c == null) return;
    try {
      await c.rpc(
        'ruhh_push',
        params: {
          'p_user_id': userId,
          'p_pin_hash': pinHash,
          'p_payload': payload,
        },
      );
    } catch (_) {
      // Sync retried on next login.
    }
  }
}
