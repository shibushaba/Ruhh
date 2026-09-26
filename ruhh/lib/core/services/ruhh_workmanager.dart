import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ruhh/core/data/isar_service.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/habit_notification_scheduler.dart';
import 'package:ruhh/core/services/notification_service.dart';
import 'package:ruhh/core/services/reschedule_all_notifications.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const ruhhDailyNotificationTask = 'ruhhDailyNotificationTask';

Future<void> initRuhhWorkmanager() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    ruhhDailyNotificationTask,
    ruhhDailyNotificationTask,
    frequency: const Duration(hours: 24),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
    await NotificationService.configureTimeZones();
    final notifications = await NotificationService.create();
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(ruhhSessionUsernameKey);
    if (username == null || username.isEmpty) return true;

    final isar = await IsarService.open();
    final user =
        await isar.userLocals.filter().usernameEqualTo(username).findFirst();
    if (user == null) return true;

    final settings = ModuleSettings(
      budgetEnabled: user.budgetEnabled,
      onboardingComplete: user.onboardingComplete,
      loaded: true,
      darkMode: prefs.getBool('dark_mode') ?? true,
      notifyBudget: prefs.getBool('notify_budget') ?? true,
      notifyHabit: prefs.getBool('notify_habit') ?? true,
      notifyPrayer: prefs.getBool('notify_prayer') ?? true,
      notifyMovie: prefs.getBool('notify_movie') ?? true,
      notifyStreakProtection: prefs.getBool('notify_streak') ?? true,
      notifyRecommendations: prefs.getBool('notify_recommendations') ?? true,
    );

    final userId = user.supabaseId ?? user.id.toString();
    final habitRepo = HabitRepository(isar, userId);
    final prayerRepo = PrayerRepository(isar, userId);
    final habitSched = HabitNotificationScheduler(notifications, settings);
    final reschedule = RescheduleAllNotifications(
      notifications,
      settings,
      habitSched,
      habitRepo,
      prayerRepo,
    );
    await reschedule.run();
    await reschedule.maybeFireStreakProtectionNow();
    return true;
  });
}
