import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/core/services/overlay_runtime.dart';
import 'package:ruhh/core/services/supabase_service.dart';
import 'package:ruhh/core/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/auth/username_availability.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class AuthState {
  const AuthState({this.username, this.loading = false});

  final String? username;
  final bool loading;

  bool get isLoggedIn => username != null;

  AuthState copyWith({String? username, bool? loading}) {
    return AuthState(
      username: username ?? this.username,
      loading: loading ?? this.loading,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  static const pinLength = 6;

  @override
  AuthState build() {
    _loadSession();
    return const AuthState(loading: true);
  }

  /// Restores session from disk — no timeout; user stays logged in until [logout].
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(ruhhSessionUsernameKey);
    if (username != null && username.isNotEmpty) {
      final isar = await ref.read(isarProvider.future);
      final user = await isar.userLocals
          .filter()
          .usernameEqualTo(username)
          .findFirst();
      if (user == null) {
        await prefs.remove(ruhhSessionUsernameKey);
        state = const AuthState(loading: false);
        return;
      }
    }
    state = AuthState(username: username, loading: false);
    if (username != null && !ruhhOverlayIsolate) {
      scheduleFullCloudSync(ref.read, delay: Duration.zero);
    }
  }

  Future<UsernameAvailability> checkUsernameAvailability(String username) async {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.length < 3) {
      return UsernameAvailability.tooShort;
    }

    final isar = await ref.read(isarProvider.future);
    final localTaken = await isar.userLocals
        .filter()
        .usernameEqualTo(trimmed)
        .findFirst();
    if (localTaken != null) return UsernameAvailability.taken;

    return SupabaseService.checkUsernameAvailability(trimmed);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final result = await checkUsernameAvailability(username);
    return result == UsernameAvailability.available ||
        result == UsernameAvailability.offlineAvailable;
  }

  Future<String?> signUp(String username, String pin) async {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.length < 3) return 'Username too short';
    if (pin.length != pinLength) return 'PIN must be $pinLength digits';

    final available = await isUsernameAvailable(trimmed);
    if (!available) return 'Username already taken';

    final salt = _randomSalt();
    final hash = _hashPin(pin, salt);
    final remoteId = const Uuid().v4();

    final isar = await ref.read(isarProvider.future);
    final user = UserLocal()
      ..username = trimmed
      ..pinHash = hash
      ..pinSalt = salt
      ..supabaseId = remoteId
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.userLocals.put(user);
    });

    final registered = await SupabaseService.registerUser(
      id: remoteId,
      username: trimmed,
      pinHash: hash,
      pinSalt: salt,
    );
    if (SupabaseService.client != null && !registered) {
      await isar.writeTxn(() async {
        await isar.userLocals.delete(user.id);
      });
      return 'Could not save account to the cloud. Check your connection and try again.';
    }

    await _persistSession(trimmed);
    state = AuthState(username: trimmed);
    await _syncUserData(user, hash, expectCloudRestore: false);
    return null;
  }

  Future<String?> login(String username, String pin) async {
    final trimmed = username.trim().toLowerCase();
    final isar = await ref.read(isarProvider.future);
    var user = await isar.userLocals
        .filter()
        .usernameEqualTo(trimmed)
        .findFirst();

    if (user == null) {
      final remote = await SupabaseService.fetchAuthProfile(trimmed);
      if (remote == null) return 'User not found';
      final hash = _hashPin(pin, remote.pinSalt);
      if (hash != remote.pinHash) return 'Incorrect PIN';
      user = UserLocal()
        ..username = remote.username
        ..pinHash = remote.pinHash
        ..pinSalt = remote.pinSalt
        ..supabaseId = remote.id
        ..createdAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.userLocals.put(user!);
      });
      await _persistSession(trimmed);
      await _syncUserData(user, hash, expectCloudRestore: true);
      state = AuthState(username: trimmed);
      return null;
    }

    final hash = _hashPin(pin, user.pinSalt);
    if (hash != user.pinHash) return 'Incorrect PIN';

    await _persistSession(trimmed);
    state = AuthState(username: trimmed);
    await _syncUserData(user, hash, expectCloudRestore: false);
    return null;
  }

  Future<void> _syncUserData(
    UserLocal user,
    String pinHash, {
    required bool expectCloudRestore,
  }) async {
    ref.read(cloudRestoreNoticeProvider.notifier).state = null;
    try {
      final isar = await ref.read(isarProvider.future);
      final result = await performUserCloudSync(isar, user);
      if (expectCloudRestore &&
          result.startedWithEmptyLocal &&
          result.noCloudBackup) {
        ref.read(cloudRestoreNoticeProvider.notifier).state =
            'No cloud backup found for this account. If you reinstalled after an older app version, '
            'your backup may have been cleared. Data on another phone that is still logged in can be re-uploaded.';
      } else if (expectCloudRestore && result.restoredFromCloud) {
        ref.read(cloudRestoreNoticeProvider.notifier).state =
            'Restored your data from the cloud.';
      }
      markCloudSyncSuccess(ref.read);
      await ref
          .read(settingsControllerProvider.notifier)
          .reloadForCurrentUser(force: true);
    } on CloudSyncPullFailedException catch (e) {
      ref.read(lastCloudSyncErrorProvider.notifier).state = e.message;
      scheduleCloudSync(ref.read, delay: const Duration(seconds: 15));
    } catch (_) {
      ref.read(lastCloudSyncErrorProvider.notifier).state =
          'Backup failed — will retry automatically.';
      scheduleCloudSync(ref.read, delay: const Duration(seconds: 15));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ruhhSessionUsernameKey);
    state = const AuthState(loading: false);
  }

  Future<void> _persistSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ruhhSessionUsernameKey, username);
  }

  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static String _randomSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
