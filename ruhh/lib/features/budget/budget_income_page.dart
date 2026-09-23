import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/widgets/ledger_list_row.dart';

/// Section 7.6 — income sources only (never mixed into expense math).
class BudgetIncomePage extends ConsumerStatefulWidget {
  const BudgetIncomePage({super.key});

  @override
  ConsumerState<BudgetIncomePage> createState() => _BudgetIncomePageState();
}

class _BudgetIncomePageState extends ConsumerState<BudgetIncomePage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder<List<TransactionLocal>>(
        future: repo.ledgerTransactionsForMonth(_month),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final txs = snap.data!;
          final incomeTx = txs
              .where((t) =>
                  t.ledgerType == BudgetLedgerType.salary ||
                  t.ledgerType == BudgetLedgerType.credit)
              .toList();
          final total =
              incomeTx.fold<double>(0, (sum, t) => sum + t.amount);

          return NBPageBody(
            child: ListView(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month - 1);
                      }),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM().format(_month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month + 1);
                      }),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                NBSection(
                  title: 'Income this month',
                  subtitle: 'Salary + credits (Section 6)',
                  child: incomeTx.isEmpty
                      ? const NBEmptyState(
                          message: 'No income logged this month.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LedgerIncomeTotalCard(total: total),
                            const SizedBox(height: 12),
                            ...incomeTx.map(
                              (tx) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: LedgerListRow(
                                  tx: tx,
                                  showSign: true,
                                  onTap: () =>
                                      context.push('/budget/edit/${tx.id}'),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const RuhhNavClearance(extra: 12),
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
