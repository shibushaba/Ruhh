import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/budget_schedule.dart';

class BudgetUpcomingPage extends ConsumerWidget {
  const BudgetUpcomingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: Future.wait([repo.scheduledUnpaid(), repo.overdueScheduled()]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final upcoming = snap.data![0] as List<TransactionLocal>;
          final overdue = snap.data![1] as List<TransactionLocal>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Upcoming & recurring',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Mark paid when it posts, or skip to move the next due date.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (overdue.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Overdue',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.red.shade800)),
                ...overdue.map((t) => _ScheduledTile(
                      tx: t,
                      repo: repo,
                      ref: ref,
                      overdue: true,
                    )),
              ],
              const SizedBox(height: 16),
              Text('Scheduled', style: Theme.of(context).textTheme.titleLarge),
              if (upcoming.where((t) => !isTransactionOverdue(t)).isEmpty)
                const NBCard(child: Text('Nothing scheduled — add a repeating or upcoming transaction.')),
              ...upcoming
                  .where((t) => !isTransactionOverdue(t))
                  .map((t) => _ScheduledTile(
                        tx: t,
                        repo: repo,
                        ref: ref,
                        overdue: false,
                      )),
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

class _ScheduledTile extends StatelessWidget {
  const _ScheduledTile({
    required this.tx,
    required this.repo,
    required this.ref,
    required this.overdue,
  });

  final TransactionLocal tx;
  final BudgetRepository repo;
  final WidgetRef ref;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final due = DateFormat.yMMMd().format(tx.occurredAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NBCard(
        color: overdue
            ? Colors.red.withValues(alpha: 0.15)
            : NBColors.budget.withValues(alpha: 0.12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tx.title.isNotEmpty ? tx.title : tx.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${tx.isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '${scheduleTypeLabel(tx.scheduleType)} · Due $due · ${tx.account}',
            ),
            if (tx.recurrence != 'none')
              Text('Every ${tx.periodLength} ${tx.recurrence}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: NBButton(
                    label: 'Mark paid',
                    color: NBColors.budget,
                    onPressed: () async {
                      await repo.markScheduledPaid(tx.id);
                      bumpBudgetRefresh(ref);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                NBButton(
                  label: 'Skip',
                  expand: false,
                  color: NBColors.offWhite,
                  onPressed: () async {
                    await repo.skipScheduled(tx.id);
                    bumpBudgetRefresh(ref);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/budget/edit/${tx.id}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
