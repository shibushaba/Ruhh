import 'dart:async';

import 'package:ruhh/core/services/agent_inbox.dart';
import 'package:ruhh/core/session/secure_session_store.dart';

/// Transport-agnostic RPC call (Supabase PostgREST in the app, a fake in tests).
typedef RpcCall =
    Future<dynamic> Function(String function, Map<String, dynamic> params);

/// Error raised by [RpcCall] implementations (mapped from PostgrestException).
class CloudRpcException implements Exception {
  const CloudRpcException(this.code, this.message);

  final String? code;
  final String message;

  /// PostgREST "function not found" — server has not received migration S1 yet.
  bool get isFunctionMissing =>
      code == 'PGRST202' ||
      message.contains('Could not find the function') ||
      code == '404';

  bool get isSessionInvalid =>
      code == '28000' || message.contains('session_invalid');

  bool get isPermissionDenied =>
      code == '42501' || message.contains('permission denied');

  @override
  String toString() => 'CloudRpcException($code)';
}

enum CloudAuthError {
  invalidCredentials,
  lockedOut,
  updateRequired,
  usernameTaken,
  usernameTooShort,
  invalidPin,
  serverOutdated,

  /// The cloud account returned is not the account this device holds locally.
  accountMismatch,
  network,
  notConfigured,
  unknown,
}

class CloudLoginResult {
  const CloudLoginResult._({
    this.token,
    this.userId,
    this.username,
    this.pinSalt,
    this.expiresAt,
    this.minSupportedVersion,
    this.error,
  });

  const CloudLoginResult.failure(
    CloudAuthError error, {
    String? minSupportedVersion,
  }) : this._(error: error, minSupportedVersion: minSupportedVersion);

  factory CloudLoginResult.fromJson(Map<String, dynamic> json) {
    if (json['ok'] != true) {
      return CloudLoginResult.failure(
        _errorFromCode(json['error'] as String?),
        minSupportedVersion: json['min_supported_version'] as String?,
      );
    }
    return CloudLoginResult._(
      token: json['token'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      pinSalt: json['pin_salt'] as String,
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      minSupportedVersion: json['min_supported_version'] as String?,
    );
  }

  final String? token;
  final String? userId;
  final String? username;
  final String? pinSalt;
  final DateTime? expiresAt;
  final String? minSupportedVersion;
  final CloudAuthError? error;

  bool get ok => error == null && token != null;

  static CloudAuthError _errorFromCode(String? code) => switch (code) {
    'invalid_credentials' => CloudAuthError.invalidCredentials,
    'locked_out' => CloudAuthError.lockedOut,
    'update_required' => CloudAuthError.updateRequired,
    'username_taken' => CloudAuthError.usernameTaken,
    'username_too_short' => CloudAuthError.usernameTooShort,
    'invalid_pin' => CloudAuthError.invalidPin,
    _ => CloudAuthError.unknown,
  };
}

/// Thrown by [CloudAuthClient.pull]/[CloudAuthClient.push] with a user-facing message.
class CloudSyncAuthException implements Exception {
  const CloudSyncAuthException(this.message, {this.reauthRequired = false});

  final String message;
  final bool reauthRequired;

  @override
  String toString() => message;
}

/// Server-side session handling (R1). Never sends a PIN hash when a session exists.
///
/// Credential routing for sync:
///  * session token stored for the user -> `ruhh_pull_v2` / `ruhh_push_v2`;
///    if the server has no v2 functions yet (pre-S1) -> legacy v1 fallback.
///  * no token (user logged in on an older build, or session expired/revoked) ->
///    legacy v1 while the server still allows it (pre-S2). After S2 the server
///    rejects v1 and the user is asked to sign in again (offline use continues).
class CloudAuthClient implements InboxTransport {
  CloudAuthClient({
    required this.rpc,
    required this.store,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  RpcCall? rpc;
  final SessionStore store;
  final DateTime Function() _now;

  /// Last observed server capability (null = unknown).
  bool? serverSupportsV2;

  final _reauth = StreamController<String>.broadcast();

  /// Emits a user id whenever its cloud session is no longer usable.
  Stream<String> get reauthRequired => _reauth.stream;

  static String tokenKey(String userId) => 'ruhh_session_token:$userId';
  static String expiryKey(String userId) => 'ruhh_session_expires:$userId';

  static const sessionExpiredMessage =
      'Cloud session expired — log out and sign in again with your PIN to resume backup.';
  static const legacyRetiredMessage =
      'Cloud backup needs a fresh sign-in — log out and sign in again with your PIN.';

  /// [expectedUserId]: the local account's cloud id (existing-device login).
  /// A session for any other account is discarded, never stored.
  Future<CloudLoginResult> login({
    required String username,
    required String pin,
    required String clientVersion,
    String? expectedUserId,
  }) => _authCall(
    'ruhh_login',
    {'p_username': username, 'p_pin': pin, 'p_client_version': clientVersion},
    expectedUserId: expectedUserId,
    expectedUsername: username,
  );

  Future<CloudLoginResult> register({
    required String id,
    required String username,
    required String pin,
    required String clientVersion,
  }) => _authCall(
    'ruhh_register_user_v2',
    {
      'p_id': id,
      'p_username': username,
      'p_pin': pin,
      'p_client_version': clientVersion,
    },
    expectedUserId: id,
    expectedUsername: username,
  );

  Future<CloudLoginResult> _authCall(
    String fn,
    Map<String, dynamic> params, {
    String? expectedUserId,
    String? expectedUsername,
  }) async {
    final call = rpc;
    if (call == null) {
      return const CloudLoginResult.failure(CloudAuthError.notConfigured);
    }
    try {
      final raw = await call(fn, params);
      if (raw is! Map) {
        return const CloudLoginResult.failure(CloudAuthError.unknown);
      }
      serverSupportsV2 = true;
      final result = CloudLoginResult.fromJson(Map<String, dynamic>.from(raw));
      if (!result.ok) return result;
      final idMismatch =
          expectedUserId != null && result.userId != expectedUserId;
      final nameMismatch =
          expectedUsername != null &&
          result.username?.toLowerCase() !=
              expectedUsername.trim().toLowerCase();
      if (idMismatch || nameMismatch) {
        // Never store a session for another account; best-effort revoke it.
        try {
          await call('ruhh_logout', {'p_token': result.token});
        } catch (_) {}
        return const CloudLoginResult.failure(CloudAuthError.accountMismatch);
      }
      await saveSession(result);
      return result;
    } on CloudRpcException catch (e) {
      if (e.isFunctionMissing) {
        serverSupportsV2 = false;
        return const CloudLoginResult.failure(CloudAuthError.serverOutdated);
      }
      return const CloudLoginResult.failure(CloudAuthError.unknown);
    } catch (_) {
      return const CloudLoginResult.failure(CloudAuthError.network);
    }
  }

  /// Reads a secure value; an unreadable value (decrypt failure after a backup
  /// restore, broken keystore) clears the session and asks for a PIN sign-in.
  Future<String?> _read(String userId, String key) async {
    try {
      return await store.read(key);
    } catch (_) {
      await clearSession(userId);
      _reauth.add(userId);
      return null;
    }
  }

  /// Returns false when secure storage is unusable (the session is then not
  /// kept; cloud sync asks for a fresh sign-in later, local use continues).
  Future<bool> saveSession(CloudLoginResult result) async {
    try {
      await store.write(tokenKey(result.userId!), result.token!);
      if (result.expiresAt != null) {
        await store.write(
          expiryKey(result.userId!),
          result.expiresAt!.toUtc().toIso8601String(),
        );
      }
      return true;
    } catch (_) {
      await clearSession(result.userId!);
      return false;
    }
  }

  /// Returns a usable token or null; expired tokens are removed locally.
  Future<String?> tokenFor(String userId) async {
    final token = await _read(userId, tokenKey(userId));
    if (token == null || token.isEmpty) return null;
    final exp = DateTime.tryParse(await _read(userId, expiryKey(userId)) ?? '');
    if (exp != null && !exp.isAfter(_now())) {
      await clearSession(userId);
      _reauth.add(userId);
      return null;
    }
    return token;
  }

  /// Never throws: a storage failure must not block logout or re-login.
  Future<void> clearSession(String userId) async {
    for (final k in [tokenKey(userId), expiryKey(userId)]) {
      try {
        await store.delete(k);
      } catch (_) {}
    }
  }

  /// Revokes the server session (best effort) and always clears the local token.
  /// Never throws.
  Future<void> logout(String userId) async {
    String? token;
    try {
      token = await store.read(tokenKey(userId));
    } catch (_) {
      token =
          null; // unreadable: nothing to revoke from here; expires server-side
    }
    await clearSession(userId);
    final call = rpc;
    if (token == null || call == null) return;
    try {
      await call('ruhh_logout', {'p_token': token});
    } catch (_) {
      // offline logout: token is gone locally and expires server-side.
    }
  }

  Future<Map<String, dynamic>?> pull({
    required String userId,
    required String legacyPinHash,
  }) async {
    final raw = await _syncCall(
      userId: userId,
      v2: (token) => ('ruhh_pull_v2', {'p_token': token}),
      v1: () =>
          ('ruhh_pull', {'p_user_id': userId, 'p_pin_hash': legacyPinHash}),
    );
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> push({
    required String userId,
    required String legacyPinHash,
    required Map<String, dynamic> payload,
  }) async {
    await _syncCall(
      userId: userId,
      v2: (token) => ('ruhh_push_v2', {'p_token': token, 'p_payload': payload}),
      v1: () => (
        'ruhh_push',
        {
          'p_user_id': userId,
          'p_pin_hash': legacyPinHash,
          'p_payload': payload,
        },
      ),
    );
  }

  Future<dynamic> _syncCall({
    required String userId,
    required (String, Map<String, dynamic>) Function(String token) v2,
    required (String, Map<String, dynamic>) Function() v1,
  }) async {
    final call = rpc;
    if (call == null) {
      throw const CloudSyncAuthException(
        'Cloud backup is not configured in this build.',
      );
    }
    final token = await tokenFor(userId);
    if (token != null && serverSupportsV2 != false) {
      final (fn, params) = v2(token);
      try {
        final r = await call(fn, params);
        serverSupportsV2 = true;
        return r;
      } on CloudRpcException catch (e) {
        if (e.isSessionInvalid) {
          await clearSession(userId);
          _reauth.add(userId);
          throw const CloudSyncAuthException(
            sessionExpiredMessage,
            reauthRequired: true,
          );
        }
        if (!e.isFunctionMissing) rethrow;
        serverSupportsV2 =
            false; // documented fallback: server not migrated yet
      }
    }
    final (fn, params) = v1();
    try {
      return await call(fn, params);
    } on CloudRpcException catch (e) {
      if (e.isPermissionDenied || e.isFunctionMissing) {
        _reauth.add(userId);
        throw const CloudSyncAuthException(
          legacyRetiredMessage,
          reauthRequired: true,
        );
      }
      rethrow;
    }
  }

  /// Pending agent actions; null when unavailable (no session / pre-inbox server).
  @override
  Future<List<dynamic>?> fetchInbox(String userId) async {
    final call = rpc;
    final token = await tokenFor(userId);
    if (call == null || token == null) return null;
    try {
      final raw = await call('ruhh_inbox_fetch_v2', {'p_token': token});
      return raw is List ? raw : null;
    } on CloudRpcException catch (e) {
      if (e.isSessionInvalid) {
        await clearSession(userId);
        _reauth.add(userId);
      }
      return null;
    }
  }

  @override
  Future<void> ackInbox(
    String userId,
    List<Map<String, dynamic>> results,
  ) async {
    final call = rpc;
    final token = await tokenFor(userId);
    if (call == null || token == null) {
      throw const CloudSyncAuthException(sessionExpiredMessage);
    }
    await call('ruhh_inbox_ack_v2', {'p_token': token, 'p_results': results});
  }

  /// Pending proposals for the user's own session (approval is user-only:
  /// the agent API has no approve operation).
  Future<List<AgentProposal>> listProposals(String userId) async {
    final call = rpc;
    final token = await tokenFor(userId);
    if (call == null || token == null) {
      throw const CloudSyncAuthException(
        sessionExpiredMessage,
        reauthRequired: true,
      );
    }
    try {
      final raw = await call('ruhh_proposals_list_v2', {'p_token': token});
      if (raw is! List) return const [];
      return raw
          .map(AgentProposal.tryParse)
          .whereType<AgentProposal>()
          .toList();
    } on CloudRpcException catch (e) {
      if (e.isSessionInvalid) {
        await clearSession(userId);
        _reauth.add(userId);
        throw const CloudSyncAuthException(
          sessionExpiredMessage,
          reauthRequired: true,
        );
      }
      rethrow;
    }
  }

  Future<ProposalDecisionResult> decideProposal(
    String userId,
    AgentProposal proposal, {
    required bool approve,
  }) async {
    final call = rpc;
    final token = await tokenFor(userId);
    if (call == null || token == null) {
      return ProposalDecisionResult.sessionRequired;
    }
    try {
      final raw = await call('ruhh_proposal_decide_v2', {
        'p_token': token,
        'p_proposal_id': proposal.id,
        'p_params_hash': proposal.paramsHash,
        'p_decision': approve ? 'approve' : 'reject',
      });
      final status = raw is Map ? raw['status'] : null;
      if (status == 'executed') return ProposalDecisionResult.executed;
      if (status == 'rejected') return ProposalDecisionResult.rejected;
      return ProposalDecisionResult.failed;
    } on CloudRpcException catch (e) {
      if (e.isSessionInvalid) {
        await clearSession(userId);
        _reauth.add(userId);
        return ProposalDecisionResult.sessionRequired;
      }
      final m = e.message;
      if (m.contains('proposal_expired')) return ProposalDecisionResult.expired;
      if (m.contains('proposal_already_decided')) {
        return ProposalDecisionResult.alreadyDecided;
      }
      if (m.contains('proposal_hash_mismatch')) {
        return ProposalDecisionResult.changed;
      }
      if (m.contains('proposal_conflict')) {
        return ProposalDecisionResult.conflict;
      }
      if (m.contains('target_not_found')) {
        return ProposalDecisionResult.targetMissing;
      }
      if (m.contains('proposal_not_found')) {
        return ProposalDecisionResult.notFound;
      }
      return ProposalDecisionResult.failed;
    } catch (_) {
      return ProposalDecisionResult.failed;
    }
  }
}

/// A pending agent proposal as shown on the in-app approval screen.
class AgentProposal {
  const AgentProposal({
    required this.id,
    required this.action,
    required this.summary,
    required this.paramsHash,
    required this.params,
    required this.target,
    required this.expiresAt,
  });

  final String id;
  final String action;
  final String summary;
  final String paramsHash;
  final Map<String, dynamic> params;

  /// Server's description of the current target (null if it no longer exists).
  final Map<String, dynamic>? target;
  final DateTime? expiresAt;

  static AgentProposal? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'], action = raw['action'], hash = raw['params_hash'];
    if (id is! String || action is! String || hash is! String) return null;
    return AgentProposal(
      id: id,
      action: action,
      summary: raw['summary'] is String ? raw['summary'] as String : action,
      paramsHash: hash,
      params: raw['params'] is Map
          ? Map<String, dynamic>.from(raw['params'] as Map)
          : const {},
      target: raw['target'] is Map
          ? Map<String, dynamic>.from(raw['target'] as Map)
          : null,
      expiresAt: DateTime.tryParse(raw['expires_at'] as String? ?? ''),
    );
  }
}

enum ProposalDecisionResult {
  executed,
  rejected,
  expired,
  alreadyDecided,
  changed,
  targetMissing,
  conflict,
  notFound,
  sessionRequired,
  failed,
}

/// Compares dotted versions ("1.0.31", "1.0.31+32"). Unparseable => treated as 0.
bool isVersionLower(String a, String b) {
  List<int> parse(String v) {
    final core = v.split('+').first.split('.');
    return List<int>.generate(
      3,
      (i) => i < core.length ? int.tryParse(core[i]) ?? 0 : 0,
    );
  }

  final pa = parse(a), pb = parse(b);
  for (var i = 0; i < 3; i++) {
    if (pa[i] != pb[i]) return pa[i] < pb[i];
  }
  return false;
}
