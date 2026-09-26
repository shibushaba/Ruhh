import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/services/notification_permissions.dart';
import 'package:ruhh/core/services/reschedule_all_notifications.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class NotificationOnboardingPage extends ConsumerWidget {
  const NotificationOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: ruhhAppBar(context, title: 'Reminders'),
      body: Padding(
        padding: EdgeInsets.all(t.spaceScreenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RuhhSoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay on track',
                    style: t.statMedium(theme),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RUHH needs notification permission to remind you about '
                    'prayers and habits at the right time.',
                    style: theme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'On Samsung devices, also set Battery to Unrestricted '
                    'so reminders survive overnight.',
                    style: t.caption(theme),
                  ),
                ],
              ),
            ),
            const Spacer(),
            NBButton(
              label: 'Allow notifications',
              onPressed: () => _continue(ref, context, request: true),
            ),
            const SizedBox(height: 12),
            NBButton(
              label: 'Not now',
              primary: false,
              onPressed: () => _continue(ref, context, request: false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue(
    WidgetRef ref,
    BuildContext context, {
    required bool request,
  }) async {
    if (request) {
      final perms = await ref.read(notificationPermissionsProvider.future);
      await perms.requestNotifications();
      final android = await perms.readStatus();
      if (!android.exactAlarmsAllowed) {
        await perms.openExactAlarmSettings();
      }
      if (!android.batteryUnrestricted) {
        await perms.requestBatteryExemption();
      }
    }
    await ref
        .read(settingsControllerProvider.notifier)
        .setOnboardingComplete(true);
    await rescheduleAllNotifications(ref);
    if (context.mounted) context.go('/home');
  }
}
