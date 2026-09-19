import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/focus/focus_repository.dart';
import 'package:ruhh/features/focus/focus_timer_controller.dart';
import 'package:ruhh/features/habit/habit_repository.dart';

class FocusPage extends ConsumerWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(focusTimerProvider);
    final habitRepo = ref.watch(habitRepositoryProvider);
    final focusRepo = ref.watch(focusRepositoryProvider);

    return habitRepo.when(
      data: (repo) => FutureBuilder(
        future: repo.activeHabits(),
        builder: (context, habitSnap) {
          final habits = habitSnap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              NBCard(
                color: NBColors.habit.withValues(alpha: 0.25),
                child: Column(
                  children: [
                    Text(
                      formatFocusDuration(timer.elapsedSeconds),
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Text('Target ${timer.targetMinutes} min'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!timer.running)
                          NBButton(
                            expand: false,
                            label: 'Start',
                            color: NBColors.habit,
                            onPressed: habits.isEmpty
                                ? null
                                : () => ref
                                    .read(focusTimerProvider.notifier)
                                    .start(habitId: habits.first.remoteId),
                          )
                        else ...[
                          NBButton(
                            expand: false,
                            label: timer.paused ? 'Resume' : 'Pause',
                            onPressed: () {
                              final n = ref.read(focusTimerProvider.notifier);
                              timer.paused ? n.resume() : n.pause();
                            },
                          ),
                          const SizedBox(width: 8),
                          NBButton(
                            expand: false,
                            label: 'Stop',
                            color: Colors.grey.shade400,
                            onPressed: () =>
                                ref.read(focusTimerProvider.notifier).stop(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Pick habit', style: Theme.of(context).textTheme.titleMedium),
              ...habits.map(
                (h) => ListTile(
                  title: Text(h.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => ref.read(focusTimerProvider.notifier).start(
                          habitId: h.remoteId,
                          minutes: 25,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              focusRepo.when(
                data: (r) => FutureBuilder(
                  future: r.totalMinutes(
                    since: DateTime.now().subtract(const Duration(days: 7)),
                  ),
                  builder: (context, snap) => Text(
                    'Focus this week: ${snap.data ?? 0} min',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
