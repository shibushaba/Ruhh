import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/core/services/supabase_service.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final t = context.ruhh;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ruhhAppBar(context, title: 'Settings'),
      body: NBPageBody(
        extraBottomPadding: false,
        child: ListView(
          children: [
            NBSection(
              title: 'Modules',
              subtitle: 'Turn trackers on or off for this account.',
              child: NBCard(
                child: _SettingsSwitch(
                  title: 'Budget tracker',
                  subtitle: 'Expenses, goals, and accounts',
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
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsSwitch(
                      title: 'Budget',
                      value: settings.notifyBudget,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(budget: v),
                    ),
                    Divider(height: 1, color: t.divider),
                    _SettingsSwitch(
                      title: 'Habit',
                      value: settings.notifyHabit,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(habit: v),
                    ),
                    Divider(height: 1, color: t.divider),
                    _SettingsSwitch(
                      title: 'Prayer',
                      value: settings.notifyPrayer,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(prayer: v),
                    ),
                    Divider(height: 1, color: t.divider),
                    _SettingsSwitch(
                      title: 'Movie',
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
                child: _SettingsSwitch(
                  title: 'Dark mode',
                  value: settings.darkMode,
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setDarkMode(v),
                ),
              ),
            ),
            const SizedBox(height: NBLayout.sectionGap),
            NBSection(
              title: 'Cloud backup',
              subtitle: SupabaseService.client == null
                  ? 'Add SUPABASE_URL and SUPABASE_ANON_KEY in .env to enable sync.'
                  : 'Your data syncs after login and when you change habits, budget, prayer, or movies.',
              child: NBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Supabase'),
                      subtitle: Text(
                        SupabaseService.client == null
                            ? 'Offline only'
                            : 'Connected',
                      ),
                      trailing: Icon(
                        SupabaseService.client == null
                            ? Icons.cloud_off_outlined
                            : Icons.cloud_done_outlined,
                      ),
                    ),
                    if (SupabaseService.client != null) ...[
                      const SizedBox(height: 8),
                      NBButton(
                        label: 'Sync now',
                        primary: false,
                        onPressed: () async {
                          await runCloudSyncFromWidget(ref);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sync finished'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ],
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
              color: t.textPrimary,
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/auth/welcome');
              },
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: theme.titleMedium?.copyWith(color: t.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: t.caption(theme))
          : null,
      value: value,
      activeThumbColor: t.canvas,
      activeTrackColor: t.textPrimary,
      inactiveThumbColor: t.textSecondary,
      inactiveTrackColor: t.divider,
      onChanged: onChanged,
    );
  }
}
