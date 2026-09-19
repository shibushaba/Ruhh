import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return Scaffold(
      backgroundColor: NBColors.canvas(Theme.of(context).brightness),
      appBar: AppBar(title: const Text('Settings')),
      body: NBPageBody(
        child: ListView(
          children: [
            NBSection(
              title: 'Modules',
              subtitle: 'Turn trackers on or off for this account.',
              child: NBCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Budget tracker'),
                  subtitle: const Text('Expenses, goals, and accounts'),
                  value: settings.budgetEnabled,
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setBudgetEnabled(v),
                ),
              ),
            ),
            const SizedBox(height: NBLayout.sectionGap),
            NBSection(
              title: 'Notifications',
              subtitle: 'Android reminders when enabled.',
              child: NBCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Budget'),
                      value: settings.notifyBudget,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(budget: v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Habit'),
                      value: settings.notifyHabit,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(habit: v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Prayer'),
                      value: settings.notifyPrayer,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(prayer: v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Movie'),
                      value: settings.notifyMovie,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(movie: v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: NBLayout.sectionGap),
            NBSection(
              title: 'Appearance',
              child: NBCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark mode'),
                  value: settings.darkMode,
                  onChanged: (v) =>
                      ref.read(settingsControllerProvider.notifier).setDarkMode(v),
                ),
              ),
            ),
            const SizedBox(height: NBLayout.sectionGap),
            NBButton(
              label: 'Quick action setup',
              onPressed: () => context.push('/settings/overlay'),
            ),
            const SizedBox(height: 12),
            NBButton(
              label: 'Log out',
              color: Theme.of(context).colorScheme.surface,
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/auth/welcome');
              },
            ),
          ],
        ),
      ),
    );
  }
}
