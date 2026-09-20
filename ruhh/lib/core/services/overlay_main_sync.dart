import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';

/// Overlay isolate → main app: local data changed (separate Isar instance).
const kOverlayDataChanged = 'ruhh_overlay_data_changed';

Future<void> notifyMainAppDataChanged() async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await FlutterOverlayWindow.shareData(kOverlayDataChanged);
  } catch (e) {
    if (kDebugMode) debugPrint('notifyMainAppDataChanged: $e');
  }
}

void refreshMainAppAfterOverlayWrite(
  T Function<T>(ProviderListenable<T> provider) read,
) {
  read(habitRefreshProvider.notifier).state++;
  read(budgetRefreshProvider.notifier).state++;
  read(prayerRefreshProvider.notifier).state++;
  read(movieRefreshProvider.notifier).state++;
  scheduleCloudSync(read, delay: const Duration(milliseconds: 500));
}

StreamSubscription<dynamic>? listenForOverlayDataChanges(void Function() onChanged) {
  if (kIsWeb || !Platform.isAndroid) return null;
  return FlutterOverlayWindow.overlayListener.listen((event) {
    if (event == kOverlayDataChanged) onChanged();
  });
}
