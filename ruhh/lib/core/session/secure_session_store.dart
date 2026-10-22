import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key/value contract so session handling can be unit-tested with fakes.
abstract class SessionStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Raised by [SessionStore.read] when a stored value exists but cannot be read;
/// the entry has already been removed.
class SessionStoreReadException implements Exception {
  const SessionStoreReadException();
}

/// Platform-secure storage (Android Keystore-backed EncryptedSharedPreferences,
/// iOS/macOS Keychain, Windows Credential Manager / DPAPI).
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  /// A value that cannot be decrypted (e.g. restored from a backup without its
  /// Keystore key, or a corrupted keystore) is deleted and reported as absent,
  /// which makes the app ask for a fresh PIN sign-in instead of crashing.
  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      await _deleteQuietly(key);
      throw const SessionStoreReadException();
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Unusable keystore: drop the entry; the app falls back to sign-in.
      await _deleteQuietly(key);
      rethrow;
    }
  }

  @override
  Future<void> delete(String key) => _deleteQuietly(key);

  Future<void> _deleteQuietly(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }
}

/// In-memory store for tests and for builds without secure storage.
class MemorySessionStore implements SessionStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
