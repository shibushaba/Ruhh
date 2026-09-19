import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_dialog.dart';
import 'package:ruhh/core/widgets/nb_form_fields.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/budget/budget_format.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/widgets/budget_ui.dart';

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
          return NBPageBody(
            child: ListView(
              children: [
                NBSection(
                  title: 'Wallets',
                  subtitle: 'Cash and accounts that hold your balance.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wallets.isEmpty)
                        const BudgetEmptyCard(
                          message: 'No wallets yet — add one to start tracking.',
                        ),
                      ...wallets.map(
                        (w) => BudgetListRow(
                          title: w.name,
                          subtitle:
                              '${w.currency} · opening ${BudgetFormat.money(BudgetFormat.sanitize(w.openingBalance), decimals: 0)}',
                          accent: NBColors.budget,
                          onEdit: () => _editWallet(context, ref, repo, w),
                        ),
                      ),
                      const SizedBox(height: 12),
                      NBButton(
                        label: 'Add wallet',
                        color: NBColors.budget,
                        onPressed: () => _editWallet(context, ref, repo, null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NBLayout.sectionGap),
                NBSection(
                  title: 'Categories',
                  subtitle: 'Tag expenses and income consistently.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (cats.isEmpty)
                        const BudgetEmptyCard(
                          message: 'No categories — add expense and income tags.',
                        ),
                      ...cats.map(
                        (c) => BudgetListRow(
                          title: c.name,
                          subtitle: c.isIncome ? 'Income' : 'Expense',
                          accent: Color(c.colorValue),
                          trailing: NBStatusChip(
                            label: c.isIncome ? 'Income' : 'Expense',
                          ),
                          onEdit: () => _editCategory(context, ref, repo, c),
                        ),
                      ),
                      const SizedBox(height: 12),
                      NBButton(
                        label: 'Add category',
                        color: NBColors.budget,
                        onPressed: () => _editCategory(context, ref, repo, null),
                      ),
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

  Future<void> _editWallet(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    WalletLocal? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final cur = TextEditingController(text: existing?.currency ?? 'USD');
    final open = TextEditingController(
      text: existing != null
          ? BudgetFormat.sanitize(existing.openingBalance).toStringAsFixed(0)
          : '0',
    );
    await showNBFormDialog(
      context: context,
      title: existing == null ? 'Add wallet' : 'Edit wallet',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NBTextField(controller: name, label: 'Name'),
          const SizedBox(height: 12),
          NBTextField(controller: cur, label: 'Currency'),
          const SizedBox(height: 12),
          NBTextField(
            controller: open,
            label: 'Opening balance',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: (dialogCtx) => [
        if (existing != null)
          NBDialogAction(
            label: 'Delete',
            destructive: true,
            onPressed: () async {
              await repo.deleteWallet(existing.id);
              bumpBudgetRefresh(ref);
              if (dialogCtx.mounted) popNBDialog(dialogCtx);
            },
          ),
        NBDialogAction(
          label: 'Cancel',
          onPressed: () => popNBDialog(dialogCtx),
        ),
        NBDialogAction(
          label: 'Save',
          primary: true,
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
            if (dialogCtx.mounted) popNBDialog(dialogCtx);
          },
        ),
      ],
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
    await showNBStatefulFormDialog(
      context: context,
      title: existing == null ? 'Add category' : 'Edit category',
      content: (_, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NBTextField(controller: name, label: 'Name'),
          NBSwitchRow(
            label: 'Income category',
            value: income,
            onChanged: (v) => setLocal(() => income = v),
          ),
        ],
      ),
      actions: (dialogCtx, setLocal) => [
        if (existing != null)
          NBDialogAction(
            label: 'Delete',
            destructive: true,
            onPressed: () async {
              await repo.deleteCategory(existing.id);
              bumpBudgetRefresh(ref);
              if (dialogCtx.mounted) popNBDialog(dialogCtx);
            },
          ),
        NBDialogAction(
          label: 'Cancel',
          onPressed: () => popNBDialog(dialogCtx),
        ),
        NBDialogAction(
          label: 'Save',
          primary: true,
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            await repo.upsertCategory(
              id: existing?.id,
              name: name.text.trim(),
              isIncome: income,
              colorValue: existing?.colorValue,
            );
            bumpBudgetRefresh(ref);
            if (dialogCtx.mounted) popNBDialog(dialogCtx);
          },
        ),
      ],
    );
  }
}
