import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/budget/budget_repository.dart';

class BudgetAccountsPage extends ConsumerWidget {
  const BudgetAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
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
              Text('Accounts', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              ...wallets.map(
                (w) => NBCard(
                  child: ListTile(
                    title: Text(w.name),
                    subtitle: Text('${w.currency} · opening \$${w.openingBalance.toStringAsFixed(0)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editWallet(context, ref, repo, w),
                    ),
                  ),
                ),
              ),
              NBButton(
                label: 'Add wallet',
                color: NBColors.budget,
                onPressed: () => _editWallet(context, ref, repo, null),
              ),
              const SizedBox(height: 24),
              Text('Categories', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              ...cats.map(
                (c) => NBCard(
                  color: Color(c.colorValue).withValues(alpha: 0.25),
                  child: ListTile(
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.isIncome ? 'Income' : 'Expense'),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCategory(context, ref, repo, c),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              NBButton(
                label: 'Add category',
                color: NBColors.budget,
                onPressed: () => _editCategory(context, ref, repo, null),
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

  Future<void> _editWallet(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    WalletLocal? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final cur = TextEditingController(text: existing?.currency ?? 'USD');
    final open = TextEditingController(
      text: existing?.openingBalance.toStringAsFixed(0) ?? '0',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add wallet' : 'Edit wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: cur, decoration: const InputDecoration(labelText: 'Currency')),
            TextField(
              controller: open,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Opening balance'),
            ),
          ],
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await repo.deleteWallet(existing.id);
                bumpBudgetRefresh(ref);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await repo.upsertWallet(
                id: existing?.id,
                name: name.text.trim(),
                currency: cur.text.trim(),
                openingBalance: double.tryParse(open.text) ?? 0,
                colorValue: existing?.colorValue,
              );
              bumpBudgetRefresh(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    CategoryLocal? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    var income = existing?.isIncome ?? false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add category' : 'Edit category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              SwitchListTile(
                title: const Text('Income category'),
                value: income,
                onChanged: (v) => setLocal(() => income = v),
              ),
            ],
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  await repo.deleteCategory(existing.id);
                  bumpBudgetRefresh(ref);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await repo.upsertCategory(
                  id: existing?.id,
                  name: name.text.trim(),
                  isIncome: income,
                  colorValue: existing?.colorValue,
                );
                bumpBudgetRefresh(ref);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
