import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (settings.budgetEnabled) _BudgetInsight(ref: ref),
          _HabitInsight(ref: ref),
          _PrayerInsight(ref: ref),
          _MovieInsight(ref: ref),
        ],
      ),
    );
  }
}

class _BudgetInsight extends StatelessWidget {
  const _BudgetInsight({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(budgetRepositoryProvider);
    return repo.when(
      data: (r) => FutureBuilder(
        future: Future.wait([r.spentThisMonth(), r.budgets()]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const SizedBox.shrink();
          }
          final spent = snap.data![0] as double;
          final budgets = snap.data![1] as List<BudgetPeriodLocal>;
          final limit =
              budgets.isEmpty ? 2000.0 : budgets.first.limitAmount;
          final progress =
              limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spent this month',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  NBProgressBar(progress: progress, color: NBColors.budget),
                  const SizedBox(height: 8),
                  Text('Tip: log expenses nightly to stay on track.'),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HabitInsight extends StatelessWidget {
  const _HabitInsight({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(habitRepositoryProvider);
    return repo.when(
      data: (r) => FutureBuilder(
        future: r.activeHabits(),
        builder: (context, snap) {
          final count = snap.data?.length ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NBCard(
              color: NBColors.habit.withValues(alpha: 0.35),
              child: Text('$count active habits — keep the streak alive.'),
            ),
          );
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PrayerInsight extends StatelessWidget {
  const _PrayerInsight({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(prayerRepositoryProvider);
    return repo.when(
      data: (r) => FutureBuilder(
        future: r.missedCount(),
        builder: (context, snap) {
          final missed = snap.data ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NBCard(
              color: NBColors.prayer.withValues(alpha: 0.35),
              child: Text(
                missed == 0
                    ? 'No missed prayers logged — keep it up.'
                    : '$missed missed prayers logged in your history.',
              ),
            ),
          );
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MovieInsight extends StatelessWidget {
  const _MovieInsight({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(movieRepositoryProvider);
    return repo.when(
      data: (r) => FutureBuilder(
        future: r.watchedThisMonth(),
        builder: (context, snap) {
          final n = snap.data ?? 0;
          return NBCard(
            color: NBColors.movie.withValues(alpha: 0.35),
            child: Text('Watched $n titles this month.'),
          );
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
