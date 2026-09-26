import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/services/notification_channels.dart';
import 'package:ruhh/core/services/notification_permissions.dart';
import 'package:ruhh/core/services/notification_prefs.dart';
import 'package:ruhh/core/services/notification_service.dart';
import 'package:ruhh/core/services/reschedule_all_notifications.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final t = context.ruhh;
    final permsAsync = ref.watch(notificationPermissionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ruhhAppBar(context, title: 'Notifications'),
      body: NBPageBody(
        child: ListView(
          children: [
            permsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (perms) => FutureBuilder<NotificationPermissionStatus>(
                future: perms.readStatus(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final s = snap.data!;
                  return _Section(
                    title: 'Device permissions',
                    child: NBCard(
                      child: Column(
                      children: [
                        _StatusRow(
                          label: 'Notifications',
                          value: s.notificationsEnabled ? 'Enabled' : 'Disabled',
                          onFix: perms.openAppNotificationSettings,
                        ),
                        _StatusRow(
                          label: 'Exact alarms',
                          value:
                              s.exactAlarmsAllowed ? 'Allowed' : 'Restricted',
                          onFix: perms.openExactAlarmSettings,
                        ),
                        _StatusRow(
                          label: 'Battery',
                          value: s.batteryUnrestricted
                              ? 'Unrestricted'
                              : 'Optimized',
                          onFix: perms.requestBatteryExemption,
                        ),
                      ],
                    ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: t.spaceStackGap),
            _Section(
              title: 'Channels',
              child: NBCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Prayer reminders'),
                      subtitle: const Text('At each salāh time'),
                      value: settings.notifyPrayer,
                      onChanged: (v) => _toggle(ref, prayer: v),
                    ),
                    SwitchListTile(
                      title: const Text('Habit reminders'),
                      value: settings.notifyHabit,
                      onChanged: (v) => _toggle(ref, habit: v),
                    ),
                    SwitchListTile(
                      title: const Text('Streak protection'),
                      subtitle: const Text('Evening nudge when today is open'),
                      value: settings.notifyStreakProtection,
                      onChanged: (v) => _toggle(ref, streakProtection: v),
                    ),
                    SwitchListTile(
                      title: const Text('Budget alerts'),
                      value: settings.notifyBudget,
                      onChanged: (v) => _toggle(ref, budget: v),
                    ),
                    SwitchListTile(
                      title: const Text('Recommendations'),
                      subtitle: const Text('Weekly digest'),
                      value: settings.notifyRecommendations,
                      onChanged: (v) => _toggle(ref, recommendations: v),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: t.spaceStackGap),
            _Section(
              title: 'Streak nudge time',
              child: NBCard(
                child: ListTile(
                title: const Text('Evening reminder'),
                subtitle: FutureBuilder<int>(
                  future: NotificationPrefs.streakMinuteOfDay(),
                  builder: (context, snap) {
                    final m = snap.data ?? NotificationPrefs.defaultStreakMinute;
                    final h = m ~/ 60;
                    final min = m % 60;
                    return Text(
                      '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}',
                    );
                  },
                ),
                onTap: () => _pickStreakTime(context, ref),
                ),
              ),
            ),
            SizedBox(height: t.spaceStackGap),
            NBButton(
              label: 'Send test notification',
              primary: false,
              onPressed: () => _testNotification(ref),
            ),
            const RuhhNavClearance(),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(
    WidgetRef ref, {
    bool? prayer,
    bool? habit,
    bool? budget,
    bool? streakProtection,
    bool? recommendations,
  }) async {
    await ref.read(settingsControllerProvider.notifier).setNotification(
          prayer: prayer,
          habit: habit,
          budget: budget,
          streakProtection: streakProtection,
          recommendations: recommendations,
        );
    await rescheduleAllNotifications(ref);
  }

  Future<void> _testNotification(WidgetRef ref) async {
    final n = await ref.read(notificationServiceProvider.future);
    await n.showInstant(
      id: 9999,
      title: 'RUHH test',
      body: 'If you see this, notifications are working.',
      payload: '/home',
      channelId: RuhhNotificationChannels.system,
    );
  }

  Future<void> _pickStreakTime(BuildContext context, WidgetRef ref) async {
    final current = await NotificationPrefs.streakMinuteOfDay();
    final initial = TimeOfDay(hour: current ~/ 60, minute: current % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await NotificationPrefs.setStreakMinuteOfDay(
      picked.hour * 60 + picked.minute,
    );
    await refreshStreakProtectionAlarm(ref);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.onFix,
  });

  final String label;
  final String value;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text('$label: $value')),
          TextButton(onPressed: onFix, child: const Text('Fix')),
        ],
      ),
    );
  }
}
