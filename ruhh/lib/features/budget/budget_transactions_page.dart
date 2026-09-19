import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/widgets/nb_dialog.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/budget/widgets/ledger_list_row.dart';

/// Section 7.3 — filter by month and type.
class BudgetTransactionsPage extends ConsumerStatefulWidget {
  const BudgetTransactionsPage({super.key});

  @override
  ConsumerState<BudgetTransactionsPage> createState() =>
      _BudgetTransactionsPageState();
}

class _BudgetTransactionsPageState extends ConsumerState<BudgetTransactionsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _filter = 'all';

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _editTransaction(TransactionLocal tx) async {
    await context.push('/budget/edit/${tx.id}');
    if (mounted) setState(() {});
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    BudgetRepository repo,
    TransactionLocal tx,
  ) async {
    final ok = await showNBConfirmDialog(
      context: context,
      title: 'Delete transaction?',
      message:
          'Remove ${ledgerRowTitle(tx)} (${BudgetInr.format(tx.amount)})? This syncs to your account.',
      confirmLabel: 'Delete',
    );
    if (ok != true || !context.mounted) return;
    await repo.deleteLedgerTransaction(tx.id);
    bumpBudgetRefresh(ref);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => NBPageBody(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _shiftMonth(-1),
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
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                _chip('All', 'all'),
                _chip('Expense', 'expense'),
                _chip('Credit', 'credit'),
                _chip('Salary', 'salary'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder(
                future: repo.ledgerTransactionsForMonth(_month),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var txs = snap.data!;
                  if (_filter == 'expense') {
                    txs = txs
                        .where((t) => t.ledgerType == BudgetLedgerType.expense)
                        .toList();
                  } else if (_filter == 'credit') {
                    txs = txs
                        .where((t) => t.ledgerType == BudgetLedgerType.credit)
                        .toList();
                  } else if (_filter == 'salary') {
                    txs = txs
                        .where((t) => t.ledgerType == BudgetLedgerType.salary)
                        .toList();
                  }
                  if (txs.isEmpty) {
                    return const Center(
                      child: NBEmptyState(
                        message: 'No transactions this month.',
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: txs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final tx = txs[i];
                      return LedgerListRow(
                        tx: tx,
                        onTap: () => _editTransaction(tx),
                        onEdit: () => _editTransaction(tx),
                        onDelete: () => _deleteTransaction(context, repo, tx),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _chip(String label, String id) {
    final selected = _filter == id;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = id),
    );
  }
}
