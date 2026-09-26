import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ruhh/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionStatus {
  const NotificationPermissionStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
    required this.batteryUnrestricted,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsAllowed;
  final bool batteryUnrestricted;

  bool get allHealthy =>
      notificationsEnabled && exactAlarmsAllowed && batteryUnrestricted;
}

class NotificationPermissions {
  NotificationPermissions(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _askedKey = 'notif_permission_asked_v1';
  static const _bannerDismissedKey = 'notif_banner_dismissed_v1';

  Future<bool> wasPermissionFlowShown() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_askedKey) ?? false;
  }

  Future<void> markPermissionFlowShown() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_askedKey, true);
  }

  Future<bool> isHomeBannerDismissed() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_bannerDismissedKey) ?? false;
  }

  Future<void> dismissHomeBanner() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_bannerDismissedKey, true);
  }

  Future<NotificationPermissionStatus> readStatus() async {
    if (kIsWeb) {
      return const NotificationPermissionStatus(
        notificationsEnabled: false,
        exactAlarmsAllowed: false,
        batteryUnrestricted: false,
      );
    }
    if (Platform.isIOS || Platform.isAndroid) {
      final notif = await Permission.notification.status;
      final notificationsEnabled = notif.isGranted;
      if (Platform.isIOS) {
        return NotificationPermissionStatus(
          notificationsEnabled: notificationsEnabled,
          exactAlarmsAllowed: true,
          batteryUnrestricted: true,
        );
      }
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exactAlarmsAllowed =
          await android?.canScheduleExactNotifications() ?? false;
      final battery = await Permission.ignoreBatteryOptimizations.status;
      return NotificationPermissionStatus(
        notificationsEnabled: notificationsEnabled,
        exactAlarmsAllowed: exactAlarmsAllowed,
        batteryUnrestricted: battery.isGranted,
      );
    }
    return const NotificationPermissionStatus(
      notificationsEnabled: false,
      exactAlarmsAllowed: false,
      batteryUnrestricted: false,
    );
  }

  Future<bool> requestNotifications() async {
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final r = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      await markPermissionFlowShown();
      return r ?? (await Permission.notification.status).isGranted;
    }
    if (Platform.isAndroid) {
      final r = await Permission.notification.request();
      await markPermissionFlowShown();
      return r.isGranted;
    }
    return false;
  }

  Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }

  Future<void> requestBatteryExemption() async {
    if (!Platform.isAndroid) return;
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<void> openAppNotificationSettings() => openAppSettings();
}

final notificationPermissionsProvider =
    FutureProvider<NotificationPermissions>((ref) async {
  final n = await ref.watch(notificationServiceProvider.future);
  return NotificationPermissions(n.plugin);
});
