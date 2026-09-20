import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ruhh/core/data/isar_service.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/core/services/local_data_sync.dart';
import 'package:ruhh/core/services/overlay_main_sync.dart';
import 'package:ruhh/core/services/ruhh_backup_codec.dart';
import 'package:ruhh/core/services/supabase_sync_service.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/settings/settings_controller.dart';
import 'package:share_plus/share_plus.dart';

class RuhhFileBackupResult {
  const RuhhFileBackupResult({
    required this.entityCount,
    this.sourceUsername,
  });

  final int entityCount;
  final String? sourceUsername;
}

class RuhhFileBackupService {
  RuhhFileBackupService(this._isar);

  final Isar _isar;

  Future<File> exportBackupCsv({
    required UserLocal user,
    required ModuleSettings deviceSettings,
  }) async {
    final sync = SupabaseSyncService(_isar);
    final payload = await sync.exportFileBackupPayload(
      user,
      deviceSettings: {
        'dark_mode': deviceSettings.darkMode,
        'notify_budget': deviceSettings.notifyBudget,
        'notify_habit': deviceSettings.notifyHabit,
        'notify_prayer': deviceSettings.notifyPrayer,
        'notify_movie': deviceSettings.notifyMovie,
      },
    );
    final csv = RuhhBackupCodec.encode(payload);
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now());
    final safeUser = user.username.replaceAll(RegExp(r'[^\w.-]+'), '_');
    final file = File('${dir.path}/ruhh-backup-$safeUser-$stamp.csv');
    await file.writeAsString(csv, flush: true);
    return file;
  }

  Future<void> shareBackupFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv', name: file.uri.pathSegments.last)],
      subject: 'RUHH backup',
      text: 'Full RUHH backup — restore from Settings on a fresh install.',
    );
  }

  Future<RuhhFileBackupResult> importBackupCsv({
    required UserLocal user,
    required String csvContents,
    required SettingsController settingsController,
  }) async {
    final payload = RuhhBackupCodec.decode(csvContents);
    final sync = SupabaseSyncService(_isar);
    final count = await sync.importFileBackupPayload(user, payload);

    final device = payload['device_settings'];
    if (device is Map) {
      await settingsController.setDarkMode(device['dark_mode'] as bool? ?? true);
      await settingsController.setNotification(
        budget: device['notify_budget'] as bool?,
        habit: device['notify_habit'] as bool?,
        prayer: device['notify_prayer'] as bool?,
        movie: device['notify_movie'] as bool?,
      );
    }
    await settingsController.reloadForCurrentUser(force: true);

    notifyLocalDataChanged();
    return RuhhFileBackupResult(
      entityCount: count,
      sourceUsername: payload['source_username'] as String?,
    );
  }
}

Future<void> refreshAppAfterFileBackupImport(WidgetRef ref) async {
  await IsarService.close();
  ref.invalidate(isarProvider);
  ref.invalidate(currentUserProvider);
  ref.invalidate(habitRepositoryProvider);
  ref.invalidate(budgetRepositoryProvider);
  ref.invalidate(prayerRepositoryProvider);
  ref.invalidate(movieRepositoryProvider);
  refreshMainAppAfterOverlayWrite(ref.read);
  scheduleFullCloudSync(ref.read, delay: Duration.zero);
}

final ruhhFileBackupServiceProvider = FutureProvider<RuhhFileBackupService>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return RuhhFileBackupService(isar);
});

Future<UserLocal?> currentUserLocal(WidgetRef ref) async {
  final username = ref.read(authControllerProvider).username;
  if (username == null) return null;
  final isar = await ref.read(isarProvider.future);
  return isar.userLocals.filter().usernameEqualTo(username).findFirst();
}
