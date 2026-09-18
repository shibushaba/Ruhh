import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/budget/budget_repository.dart';

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = 'Food';
  String _wallet = 'Cash';
  bool _income = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(budgetRepositoryProvider);
    return repo.when(
      data: (r) => NBModuleScaffold(
        title: 'Budget',
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Budgets'),
            Tab(text: 'Wallets'),
            Tab(text: 'Add'),
          ],
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _TransactionsTab(repo: r, refresh: () => setState(() {})),
            _BudgetsTab(repo: r),
            _WalletsTab(repo: r),
            _AddTab(
              amount: _amount,
              note: _note,
              category: _category,
              wallet: _wallet,
              income: _income,
              repo: r,
              onCategory: (c) => setState(() => _category = c),
              onWallet: (w) => setState(() => _wallet = w),
              onIncome: (v) => setState(() => _income = v),
              onSaved: () {
                _amount.clear();
                _note.clear();
                setState(() {});
                _tabs.animateTo(0);
              },
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({required this.repo, required this.refresh});
  final BudgetRepository repo;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repo.getAll(),
      builder: (context, snap) {
        final txs = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (txs.isEmpty)
              const NBCard(child: Text('No transactions yet — use Add tab.')),
            ...txs.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NBCard(
                  child: ListTile(
                    title: Text(
                      '${t.isIncome ? '+' : '-'}${t.amount.toStringAsFixed(2)} · ${t.category}',
                    ),
                    subtitle: Text('${t.account} · ${t.note}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await repo.delete(t.id);
                        refresh();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetsTab extends StatelessWidget {
  const _BudgetsTab({required this.repo});
  final BudgetRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([repo.budgets(), repo.spentThisMonth(), repo.spendByCategoryThisMonth()]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final budgets = snap.data![0] as List<BudgetPeriodLocal>;
        final spent = snap.data![1] as double;
        final byCat = snap.data![2] as Map<String, double>;
        final limit =
            budgets.isEmpty ? 2000.0 : budgets.first.limitAmount;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly spend',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  NBProgressBar(
                    progress: limit == 0 ? 0 : spent / limit,
                    color: NBColors.budget,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('By category', style: Theme.of(context).textTheme.titleLarge),
            ...byCat.entries.map(
              (e) => ListTile(
                title: Text(e.key),
                trailing: Text('\$${e.value.toStringAsFixed(0)}'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WalletsTab extends StatelessWidget {
  const _WalletsTab({required this.repo});
  final BudgetRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([repo.wallets(), repo.categories()]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final wallets = snap.data![0] as List<WalletLocal>;
        final cats = snap.data![1] as List<CategoryLocal>;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Wallets', style: Theme.of(context).textTheme.titleLarge),
            ...wallets.map(
              (w) => NBCard(
                child: ListTile(
                  title: Text(w.name),
                  subtitle: Text(w.currency),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Categories', style: Theme.of(context).textTheme.titleLarge),
            ...cats.map(
              (c) => NBCard(
                color: NBColors.budget.withValues(alpha: 0.25),
                child: ListTile(
                  title: Text(c.name),
                  trailing: Text(c.isIncome ? 'Income' : 'Expense'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddTab extends StatelessWidget {
  const _AddTab({
    required this.amount,
    required this.note,
    required this.category,
    required this.wallet,
    required this.income,
    required this.repo,
    required this.onCategory,
    required this.onWallet,
    required this.onIncome,
    required this.onSaved,
  });

  final TextEditingController amount;
  final TextEditingController note;
  final String category;
  final String wallet;
  final bool income;
  final BudgetRepository repo;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onWallet;
  final ValueChanged<bool> onIncome;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NBTextField(
          controller: amount,
          label: 'Amount',
          keyboardType: TextInputType.number,
        ),
        NBTextField(controller: note, label: 'Note'),
        Wrap(
          spacing: 6,
          children: ['Food', 'Transport', 'Bills', 'Fun', 'Salary']
              .map(
                (c) => NBChip(
                  label: c,
                  selected: category == c,
                  color: NBColors.budget,
                  onTap: () => onCategory(c),
                ),
              )
              .toList(),
        ),
        Wrap(
          spacing: 6,
          children: ['Cash']
              .map(
                (w) => NBChip(
                  label: w,
                  selected: wallet == w,
                  onTap: () => onWallet(w),
                ),
              )
              .toList(),
        ),
        Row(
          children: [
            NBChip(
              label: 'Expense',
              selected: !income,
              onTap: () => onIncome(false),
            ),
            const SizedBox(width: 8),
            NBChip(
              label: 'Income',
              selected: income,
              onTap: () => onIncome(true),
              color: NBColors.budget,
            ),
          ],
        ),
        const SizedBox(height: 12),
        NBButton(
          label: 'Save transaction',
          color: NBColors.budget,
          onPressed: () async {
            final value = double.tryParse(amount.text) ?? 0;
            if (value <= 0) return;
            await repo.add(
              amount: value,
              isIncome: income,
              category: category,
              account: wallet,
              note: note.text,
            );
            onSaved();
          },
        ),
      ],
    );
  }
}
