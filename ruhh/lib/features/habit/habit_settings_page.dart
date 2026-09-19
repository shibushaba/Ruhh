import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/habit/habit_repository.dart';

class HabitSettingsPage extends ConsumerWidget {
  const HabitSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(habitRefreshProvider);
    final repoAsync = ref.watch(habitRepositoryProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ruhhAppBar(context, title: 'Habit settings'),
      body: NBPageBody(
        child: repoAsync.when(
      data: (repo) => FutureBuilder(
        future: repo.archivedHabits(),
        builder: (context, snap) {
          final archived = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 4),
              const NBCard(
                child: Text(
                  'Home screen widget: after you add habits, RUHH syncs today\'s '
                  'progress to the Android widget (add “RUHH Today” from your '
                  'launcher widgets). Reminders use each habit\'s reminder list.',
                ),
              ),
              const SizedBox(height: 12),
              const NBCard(
                child: Text(
                  'Archived habits stay in your data but disappear from Today. '
                  'Restore them anytime.',
                ),
              ),
              const SizedBox(height: 16),
              Text('Archived',
                  style: Theme.of(context).textTheme.titleMedium),
              if (archived.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No archived habits.'),
                )
              else
                ...archived.map(
                  (h) => NBCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(h.name)),
                        NBButton(
                          expand: false,
                          label: 'Restore',
                          onPressed: () async {
                            await repo.restoreHabit(h);
                            bumpHabitRefresh(ref);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }
}
