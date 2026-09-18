import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Manage trackers',
              style: Theme.of(context).textTheme.titleLarge),
          NBCard(
            child: SwitchListTile(
              title: const Text('Budget tracker'),
              value: settings.budgetEnabled,
              onChanged: (v) => ref
                  .read(settingsControllerProvider.notifier)
                  .setBudgetEnabled(v),
            ),
          ),
          const SizedBox(height: 16),
          Text('Notifications',
              style: Theme.of(context).textTheme.titleLarge),
          NBCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Budget reminders'),
                  value: settings.notifyBudget,
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setNotification(budget: v),
                ),
                SwitchListTile(
                  title: const Text('Habit reminders'),
                  value: settings.notifyHabit,
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setNotification(habit: v),
                ),
                SwitchListTile(
                  title: const Text('Prayer reminders'),
                  value: settings.notifyPrayer,
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setNotification(prayer: v),
                ),
                SwitchListTile(
                  title: const Text('Movie nudges'),
                  value: settings.notifyMovie,
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setNotification(movie: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NBCard(
            child: SwitchListTile(
              title: const Text('Dark mode'),
              value: settings.darkMode,
              onChanged: (v) =>
                  ref.read(settingsControllerProvider.notifier).setDarkMode(v),
            ),
          ),
          const SizedBox(height: 12),
          NBButton(
            label: 'Quick action / Back tap setup',
            color: NBColors.prayer,
            onPressed: () => context.push('/settings/overlay'),
          ),
          const SizedBox(height: 12),
          NBButton(
            label: 'Log out',
            color: NBColors.offWhite,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/auth/welcome');
            },
          ),
        ],
      ),
    );
  }
}
