import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/core/services/supabase_sync_service.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: ruhhAppBar(context, title: 'Welcome'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick your trackers',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Habit, Prayer, and Movie are always on. Budget is optional.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _lockedTile(context, 'Habit', NBColors.habit),
            const SizedBox(height: 12),
            _lockedTile(context, 'Prayer', NBColors.prayer),
            const SizedBox(height: 12),
            _lockedTile(context, 'Movie', NBColors.movie),
            const SizedBox(height: 12),
            NBCard(
              color: NBColors.budget,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Budget',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Text('Track spending & budgets'),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.budgetEnabled,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .setBudgetEnabled(v),
                  ),
                ],
              ),
            ),
            const Spacer(),
            NBButton(
              label: 'Continue',
              onPressed: () async {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .setOnboardingComplete(true);
                final username = ref.read(authControllerProvider).username;
                if (username != null) {
                  final isar = await ref.read(isarProvider.future);
                  final user = await isar.userLocals
                      .filter()
                      .usernameEqualTo(username)
                      .findFirst();
                  if (user != null) {
                    await SupabaseSyncService(isar)
                        .syncUser(user, user.pinHash);
                  }
                }
                if (context.mounted) context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockedTile(BuildContext context, String title, Color color) {
    return NBCard(
      color: color,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const Icon(Icons.lock),
        ],
      ),
    );
  }
}
