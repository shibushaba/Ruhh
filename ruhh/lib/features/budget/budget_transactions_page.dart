import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/widgets/budget_transaction_list.dart';

class BudgetTransactionsPage extends ConsumerStatefulWidget {
  const BudgetTransactionsPage({super.key});

  @override
  ConsumerState<BudgetTransactionsPage> createState() =>
      _BudgetTransactionsPageState();
}

class _BudgetTransactionsPageState extends ConsumerState<BudgetTransactionsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _search = TextEditingController();
  String _filter = 'all'; // all | expense | income

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NBTextField(
              controller: _search,
              label: 'Search',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 8),
                _filterChip('Expense', 'expense'),
                const SizedBox(width: 8),
                _filterChip('Income', 'income'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _load(repo),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var txs = snap.data!;
                if (_filter == 'expense') {
                  txs = txs.where((t) => !t.isIncome).toList();
                } else if (_filter == 'income') {
                  txs = txs.where((t) => t.isIncome).toList();
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    BudgetTransactionList(
                      transactions: txs,
                      onTap: (t) => context.push('/budget/edit/${t.id}'),
                      onDelete: (t) async {
                        await repo.delete(t.id);
                        bumpBudgetRefresh(ref);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _filterChip(String label, String id) {
    return FilterChip(
      label: Text(label),
      selected: _filter == id,
      onSelected: (_) => setState(() => _filter = id),
      selectedColor: NBColors.budget.withValues(alpha: 0.4),
    );
  }

  Future<List<TransactionLocal>> _load(BudgetRepository repo) async {
    final q = _search.text.trim();
    if (q.isNotEmpty) {
      final all = await repo.search(q);
      final range = monthRange(_month);
      return all
          .where((t) =>
              !t.occurredAt.isBefore(range.start) &&
              t.occurredAt.isBefore(range.end))
          .toList();
    }
    return repo.forMonth(_month);
  }
}
