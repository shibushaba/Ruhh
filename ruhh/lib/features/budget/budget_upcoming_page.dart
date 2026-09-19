import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/features/budget/budget_format.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/budget_schedule.dart';
import 'package:ruhh/features/budget/widgets/budget_ui.dart';

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
          return NBPageBody(
            child: ListView(
              children: [
                NBSection(
                  title: 'Upcoming & recurring',
                  subtitle:
                      'Mark paid when it posts, or skip to move the next due date.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (overdue.isNotEmpty) ...[
                        Text('Overdue',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.red.shade800)),
                        const SizedBox(height: 8),
                        ...overdue.map((t) => _ScheduledTile(
                              tx: t,
                              repo: repo,
                              ref: ref,
                              overdue: true,
                            )),
                        const SizedBox(height: 16),
                      ],
                      Text('Scheduled',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (upcoming
                          .where((t) => !isTransactionOverdue(t))
                          .isEmpty)
                        const BudgetEmptyCard(
                          message:
                              'Nothing scheduled — add a repeating or upcoming transaction.',
                        ),
                      ...upcoming
                          .where((t) => !isTransactionOverdue(t))
                          .map((t) => _ScheduledTile(
                                tx: t,
                                repo: repo,
                                ref: ref,
                                overdue: false,
                              )),
                    ],
                  ),
                ),
                const SizedBox(height: 72),
              ],
            ),
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
    final signed = tx.isIncome ? tx.amount : -tx.amount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NBGlassSurface(
        accent: overdue ? Colors.red.shade700 : NBColors.budget,
        padding: const EdgeInsets.all(14),
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
                  BudgetFormat.money(signed, showSign: true),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '${scheduleTypeLabel(tx.scheduleType)} · Due $due · ${tx.account}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (tx.recurrence != 'none')
              Text(
                'Every ${tx.periodLength} ${tx.recurrence}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 10),
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
                  icon: const Icon(Icons.edit_outlined),
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
