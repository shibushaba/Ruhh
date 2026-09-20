import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/local_data_sync.dart';
import 'package:ruhh/core/services/supabase_service.dart';
import 'package:ruhh/core/services/supabase_sync_service.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

Timer? _cloudSyncDebounce;
Timer? _cloudSyncPeriodic;
Timer? _cloudSyncRetry;
var _cloudSyncInFlight = false;
var _periodicCloudSyncActive = false;
var _pendingCloudSync = false;
var _pendingFullPull = false;
Future<void>? _userSyncChain;

/// Serializes all cloud sync calls (login + background).
Future<T> withCloudUserSyncLock<T>(Future<T> Function() action) async {
  final previous = _userSyncChain ?? Future.value();
  final gate = Completer<void>();
  _userSyncChain = gate.future;
  await previous;
  try {
    return await action();
  } finally {
    gate.complete();
  }
}

Future<SyncUserResult> performUserCloudSync(Isar isar, UserLocal user) {
  return withCloudUserSyncLock(
    () => SupabaseSyncService(isar).syncUser(user, user.pinHash),
  );
}

Future<void> performUserCloudPush(Isar isar, UserLocal user) {
  return withCloudUserSyncLock(
    () => SupabaseSyncService(isar).pushUserChanges(user, user.pinHash),
  );
}

/// Full pull+push safety net while logged in.
const cloudSyncInterval = Duration(seconds: 45);

/// Coalesce rapid edits; upload runs soon after you stop tapping.
const cloudSyncDebounceDelay = Duration(milliseconds: 400);

typedef _RiverpodRead = T Function<T>(ProviderListenable<T> provider);

final cloudSyncGenerationProvider = StateProvider<int>((ref) => 0);

final lastCloudSyncAtProvider = StateProvider<DateTime?>((ref) => null);

final lastCloudSyncErrorProvider = StateProvider<String?>((ref) => null);

final cloudSyncBusyProvider = StateProvider<bool>((ref) => false);

final cloudRestoreNoticeProvider = StateProvider<String?>((ref) => null);

void markCloudSyncSuccess(_RiverpodRead read) {
  read(cloudSyncGenerationProvider.notifier).state++;
  read(lastCloudSyncAtProvider.notifier).state = DateTime.now();
  read(lastCloudSyncErrorProvider.notifier).state = null;
}

void clearCloudSyncStatus(_RiverpodRead read) {
  read(lastCloudSyncAtProvider.notifier).state = null;
  read(lastCloudSyncErrorProvider.notifier).state = null;
  read(cloudSyncBusyProvider.notifier).state = false;
  read(cloudRestoreNoticeProvider.notifier).state = null;
}

/// Queue upload to Supabase ([pullRemote] true = also download after push).
void scheduleCloudSync(
  _RiverpodRead read, {
  Duration delay = cloudSyncDebounceDelay,
  bool pullRemote = false,
}) {
  if (SupabaseService.client == null) return;
  _pendingCloudSync = true;
  if (pullRemote) _pendingFullPull = true;
  _cloudSyncDebounce?.cancel();
  _cloudSyncDebounce = Timer(delay, () {
    if (!_pendingCloudSync) return;
    _pendingCloudSync = false;
    final full = _pendingFullPull;
    _pendingFullPull = false;
    unawaited(runCloudSync(read, pullRemote: full));
  });
}

void scheduleFullCloudSync(_RiverpodRead read, {Duration delay = Duration.zero}) {
  scheduleCloudSync(read, delay: delay, pullRemote: true);
}

void startPeriodicCloudSync(_RiverpodRead read) {
  if (SupabaseService.client == null) return;
  if (!_periodicCloudSyncActive) {
    _periodicCloudSyncActive = true;
    _cloudSyncPeriodic?.cancel();
    _cloudSyncPeriodic = Timer.periodic(cloudSyncInterval, (_) {
      scheduleFullCloudSync(read, delay: Duration.zero);
    });
  }
  scheduleFullCloudSync(read, delay: Duration.zero);
}

void stopPeriodicCloudSync() {
  _periodicCloudSyncActive = false;
  _cloudSyncPeriodic?.cancel();
  _cloudSyncPeriodic = null;
  _cloudSyncRetry?.cancel();
  _cloudSyncRetry = null;
  _pendingCloudSync = false;
  _pendingFullPull = false;
}

Future<bool> runCloudSync(
  _RiverpodRead read, {
  bool pullRemote = false,
}) async {
  if (SupabaseService.client == null) return false;
  if (_cloudSyncInFlight) {
    _pendingCloudSync = true;
    if (pullRemote) _pendingFullPull = true;
    scheduleCloudSync(read, delay: cloudSyncDebounceDelay, pullRemote: pullRemote);
    return false;
  }
  final username = read(authControllerProvider).username;
  if (username == null) return false;

  _cloudSyncInFlight = true;
  read(cloudSyncBusyProvider.notifier).state = true;
  try {
    final isar = await read(isarProvider.future);
    final user = await isar.userLocals
        .filter()
        .usernameEqualTo(username)
        .findFirst();
    if (user == null || user.supabaseId == null || user.supabaseId!.isEmpty) {
      read(lastCloudSyncErrorProvider.notifier).state =
          'Sign in again to back up this account.';
      return false;
    }
    if (pullRemote) {
      await performUserCloudSync(isar, user);
    } else {
      await performUserCloudPush(isar, user);
    }
    markCloudSyncSuccess(read);
    read(budgetRefreshProvider.notifier).state++;
    await read(settingsControllerProvider.notifier)
        .reloadForCurrentUser(force: true);
    _cloudSyncRetry?.cancel();
    _cloudSyncRetry = null;
    return true;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Cloud sync failed: $e\n$st');
    }
    final message = e is CloudSyncPullFailedException
        ? e.message
        : 'Backup failed — will retry automatically.';
    read(lastCloudSyncErrorProvider.notifier).state = message;
    _cloudSyncRetry?.cancel();
    _cloudSyncRetry = Timer(const Duration(seconds: 12), () {
      unawaited(runCloudSync(read, pullRemote: pullRemote));
    });
    return false;
  } finally {
    _cloudSyncInFlight = false;
    read(cloudSyncBusyProvider.notifier).state = false;
    if (_pendingCloudSync) {
      scheduleCloudSync(
        read,
        delay: cloudSyncDebounceDelay,
        pullRemote: _pendingFullPull,
      );
    }
  }
}

final cloudSyncLifecycleProvider = Provider<void>((ref) {
  registerLocalDataChangedHook(
    () => scheduleCloudSync(ref.read, pullRemote: false),
  );

  void onAuth(AuthState auth) {
    if (auth.loading) return;
    if (auth.isLoggedIn) {
      startPeriodicCloudSync(ref.read);
    } else {
      stopPeriodicCloudSync();
      clearCloudSyncStatus(ref.read);
    }
  }

  ref.listen(authControllerProvider, (_, next) => onAuth(next));
  onAuth(ref.read(authControllerProvider));
  ref.onDispose(stopPeriodicCloudSync);
});

void scheduleCloudSyncFromWidget(WidgetRef ref) =>
    scheduleCloudSync(ref.read, pullRemote: false);

Future<bool> runCloudSyncFromWidget(WidgetRef ref) =>
    runCloudSync(ref.read, pullRemote: true);

void scheduleCloudSyncFromNotifier(Ref ref) =>
    scheduleCloudSync(ref.read, pullRemote: false);

void flushCloudSyncToServer(_RiverpodRead read) {
  scheduleFullCloudSync(read, delay: Duration.zero);
}
