import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/supabase_service.dart';
import 'package:ruhh/core/services/supabase_sync_service.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/auth/auth_controller.dart';

Timer? _cloudSyncDebounce;
Timer? _cloudSyncPeriodic;

/// Background sync interval (push local changes, then pull remote).
const cloudSyncInterval = Duration(minutes: 2);

typedef _RiverpodRead = T Function<T>(ProviderListenable<T> provider);

/// Push local changes to Supabase then pull remote (debounced).
void scheduleCloudSync(
  _RiverpodRead read, {
  Duration delay = const Duration(seconds: 2),
}) {
  if (SupabaseService.client == null) return;
  _cloudSyncDebounce?.cancel();
  _cloudSyncDebounce = Timer(delay, () {
    unawaited(runCloudSync(read));
  });
}

/// Runs every [cloudSyncInterval] while the app is logged in.
void startPeriodicCloudSync(_RiverpodRead read) {
  if (SupabaseService.client == null) return;
  _cloudSyncPeriodic?.cancel();
  _cloudSyncPeriodic = Timer.periodic(cloudSyncInterval, (_) {
    unawaited(runCloudSync(read));
  });
}

void stopPeriodicCloudSync() {
  _cloudSyncPeriodic?.cancel();
  _cloudSyncPeriodic = null;
}

Future<void> runCloudSync(_RiverpodRead read) async {
  if (SupabaseService.client == null) return;
  final username = read(authControllerProvider).username;
  if (username == null) return;

  try {
    final isar = await read(isarProvider.future);
    final user = await isar.userLocals
        .filter()
        .usernameEqualTo(username)
        .findFirst();
    if (user == null || user.supabaseId == null || user.supabaseId!.isEmpty) {
      return;
    }
    await SupabaseSyncService(isar).syncUser(user, user.pinHash);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Cloud sync failed: $e\n$st');
    }
  }
}

void scheduleCloudSyncFromWidget(WidgetRef ref) => scheduleCloudSync(ref.read);

Future<void> runCloudSyncFromWidget(WidgetRef ref) => runCloudSync(ref.read);

void scheduleCloudSyncFromNotifier(Ref ref) => scheduleCloudSync(ref.read);
