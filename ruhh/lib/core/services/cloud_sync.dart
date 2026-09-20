import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/supabase_service.dart';
import 'package:ruhh/core/services/supabase_sync_service.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

Timer? _cloudSyncDebounce;
Timer? _cloudSyncPeriodic;
Timer? _cloudSyncRetry;
var _cloudSyncInFlight = false;
var _periodicCloudSyncActive = false;

/// Background sync while logged in (push local, then pull remote).
const cloudSyncInterval = Duration(minutes: 1);

/// Debounce after local edits before uploading.
const cloudSyncDebounceDelay = Duration(seconds: 1);

typedef _RiverpodRead = T Function<T>(ProviderListenable<T> provider);

/// Incremented after a successful cloud sync so lists reload remote data.
final cloudSyncGenerationProvider = StateProvider<int>((ref) => 0);

final lastCloudSyncAtProvider = StateProvider<DateTime?>((ref) => null);

final lastCloudSyncErrorProvider = StateProvider<String?>((ref) => null);

final cloudSyncBusyProvider = StateProvider<bool>((ref) => false);

void markCloudSyncSuccess(_RiverpodRead read) {
  read(cloudSyncGenerationProvider.notifier).state++;
  read(lastCloudSyncAtProvider.notifier).state = DateTime.now();
  read(lastCloudSyncErrorProvider.notifier).state = null;
}

void clearCloudSyncStatus(_RiverpodRead read) {
  read(lastCloudSyncAtProvider.notifier).state = null;
  read(lastCloudSyncErrorProvider.notifier).state = null;
  read(cloudSyncBusyProvider.notifier).state = false;
}

/// Push local changes to Supabase then pull remote (debounced).
void scheduleCloudSync(
  _RiverpodRead read, {
  Duration delay = cloudSyncDebounceDelay,
}) {
  if (SupabaseService.client == null) return;
  _cloudSyncDebounce?.cancel();
  _cloudSyncDebounce = Timer(delay, () {
    unawaited(runCloudSync(read));
  });
}

/// Starts periodic sync and runs one cycle immediately.
void startPeriodicCloudSync(_RiverpodRead read) {
  if (SupabaseService.client == null) return;
  if (!_periodicCloudSyncActive) {
    _periodicCloudSyncActive = true;
    _cloudSyncPeriodic?.cancel();
    _cloudSyncPeriodic = Timer.periodic(cloudSyncInterval, (_) {
      unawaited(runCloudSync(read));
    });
  }
  scheduleCloudSync(read, delay: Duration.zero);
}

void stopPeriodicCloudSync() {
  _periodicCloudSyncActive = false;
  _cloudSyncPeriodic?.cancel();
  _cloudSyncPeriodic = null;
  _cloudSyncRetry?.cancel();
  _cloudSyncRetry = null;
}

Future<bool> runCloudSync(_RiverpodRead read) async {
  if (SupabaseService.client == null) return false;
  if (_cloudSyncInFlight) {
    scheduleCloudSync(read, delay: cloudSyncDebounceDelay);
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
    await SupabaseSyncService(isar).syncUser(user, user.pinHash);
    markCloudSyncSuccess(read);
    await read(settingsControllerProvider.notifier)
        .reloadForCurrentUser(force: true);
    _cloudSyncRetry?.cancel();
    _cloudSyncRetry = null;
    return true;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Cloud sync failed: $e\n$st');
    }
    read(lastCloudSyncErrorProvider.notifier).state =
        'Backup failed — will retry automatically.';
    _cloudSyncRetry?.cancel();
    _cloudSyncRetry = Timer(const Duration(seconds: 30), () {
      unawaited(runCloudSync(read));
    });
    return false;
  } finally {
    _cloudSyncInFlight = false;
    read(cloudSyncBusyProvider.notifier).state = false;
  }
}

/// Wires auth + automatic background sync for the app lifetime.
final cloudSyncLifecycleProvider = Provider<void>((ref) {
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

void scheduleCloudSyncFromWidget(WidgetRef ref) => scheduleCloudSync(ref.read);

Future<bool> runCloudSyncFromWidget(WidgetRef ref) => runCloudSync(ref.read);

void scheduleCloudSyncFromNotifier(Ref ref) => scheduleCloudSync(ref.read);
