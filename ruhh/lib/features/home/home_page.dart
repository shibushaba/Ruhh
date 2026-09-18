import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_tile.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final habitRepo = ref.watch(habitRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RUHH'),
        actions: [
          habitRepo.when(
            data: (repo) => FutureBuilder<int>(
              future: _bestStreak(repo),
              builder: (context, snap) {
                final value = snap.data ?? 0;
                return TextButton(
                  onPressed: () => context.push('/analytics'),
                  child: Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          children: [
            if (settings.budgetEnabled)
              NBTile(
                title: 'Budget',
                subtitle: 'Log expenses',
                color: NBColors.budget,
                icon: Icons.account_balance_wallet,
                onTap: () => context.push('/budget'),
              )
            else
              NBTile(
                title: 'Budget',
                subtitle: 'Tap to enable',
                color: Colors.grey.shade400,
                icon: Icons.account_balance_wallet,
                disabled: true,
                onTap: () => context.push('/settings'),
              ),
            NBTile(
              title: 'Habit',
              subtitle: 'Daily streaks',
              color: NBColors.habit,
              icon: Icons.bolt,
              onTap: () => context.push('/habit'),
            ),
            NBTile(
              title: 'Prayer',
              subtitle: 'Salah tracker',
              color: NBColors.prayer,
              icon: Icons.mosque,
              onTap: () => context.push('/prayer'),
            ),
            NBTile(
              title: 'Movie',
              subtitle: 'Watchlists',
              color: NBColors.movie,
              icon: Icons.movie,
              onTap: () => context.push('/movie'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok =
              await ref.read(overlayServiceProvider).showQuickAction();
          if (!context.mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Allow “Display over other apps” for RUHH in system settings.',
                ),
              ),
            );
          }
        },
        label: const Text('Quick'),
        icon: const Icon(Icons.bolt),
      ),
    );
  }

  Future<int> _bestStreak(HabitRepository repo) async {
    final habits = await repo.activeHabits();
    var best = 0;
    for (final h in habits) {
      final s = await repo.streakFor(h);
      if (s > best) best = s;
    }
    return best;
  }
}
