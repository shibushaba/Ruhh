import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_dialog.dart';
import 'package:ruhh/core/widgets/nb_form_fields.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/budget/widgets/category_display.dart';
import 'package:ruhh/features/budget/widgets/category_color_picker.dart';
import 'package:ruhh/features/budget/widgets/category_emoji_picker.dart';

/// Categories, category budgets, and standing salary (Sections 7.4, 7.5, 5).
class BudgetManagePage extends ConsumerWidget {
  const BudgetManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: Future.wait([
          repo.activeCategories(),
          repo.allCategoryBudgets(),
          repo.standingSalary(),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cats = snap.data![0] as List<CategoryLocal>;
          final budgets = snap.data![1] as List<CategoryBudgetLimitLocal>;
          final salary = snap.data![2] as StandingSalaryLocal?;
          return NBPageBody(
            child: ListView(
              children: [
                NBSection(
                  title: 'Monthly salary',
                  subtitle:
                      'Auto-credited on the 1st each month (Section 5).',
                  child: _SalaryBlock(
                    amount: salary?.amount ?? 0,
                    onSave: (v) async {
                      await repo.setStandingSalary(v);
                      bumpBudgetRefresh(ref);
                    },
                  ),
                ),
                NBSection(
                  title: 'Categories',
                  subtitle: 'Custom expense & income tags',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...cats.where((c) => !c.isIncome).map(
                            (c) => _CategoryTile(
                              cat: c,
                              onTap: () => _editCategory(context, ref, repo, c),
                              onArchive: () async {
                                await repo.archiveCategory(c);
                                bumpBudgetRefresh(ref);
                              },
                            ),
                          ),
                      const Divider(height: 24),
                      ...cats.where((c) => c.isIncome).map(
                            (c) => _CategoryTile(
                              cat: c,
                              onTap: () => _editCategory(context, ref, repo, c),
                              onArchive: () async {
                                await repo.archiveCategory(c);
                                bumpBudgetRefresh(ref);
                              },
                            ),
                          ),
                      NBButton(
                        label: 'Add category',
                        color: NBColors.budget,
                        onPressed: () => _addCategory(context, ref, repo),
                      ),
                    ],
                  ),
                ),
                NBSection(
                  title: 'Budgets',
                  subtitle: 'Per expense category limits',
                  child: Column(
                    children: [
                      ...budgets.map((b) {
                        CategoryLocal? cat;
                        for (final c in cats) {
                          if (c.remoteId == b.categoryRemoteId ||
                              c.name == b.categoryName) {
                            cat = c;
                            break;
                          }
                        }
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: cat != null
                                ? categoryLeadingAvatar(context, cat, radius: 16)
                                : null,
                            title: Text(
                              cat != null
                                  ? categoryChipLabel(cat)
                                  : b.categoryName,
                            ),
                            subtitle: Text(
                              '${BudgetInr.format(b.limitAmount)} · ${b.monthKey}${b.rolloverEnabled ? ' · rollover' : ''}',
                            ),
                            trailing: IconButton(
                              icon: Icon(AppIcons.trash()),
                              onPressed: () async {
                                await repo.deleteCategoryBudget(b.id);
                                bumpBudgetRefresh(ref);
                              },
                            ),
                          ),
                        );
                      }),
                      NBButton(
                        label: 'Add budget',
                        color: NBColors.budget,
                        onPressed: () => _addBudget(context, ref, repo, cats),
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

  Future<void> _addCategory(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
  ) async {
    await _showCategoryForm(
      context: context,
      ref: ref,
      repo: repo,
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    CategoryLocal existing,
  ) async {
    await _showCategoryForm(
      context: context,
      ref: ref,
      repo: repo,
      existing: existing,
    );
  }

  Future<void> _showCategoryForm({
    required BuildContext context,
    required WidgetRef ref,
    required BudgetRepository repo,
    CategoryLocal? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    var income = existing?.isIncome ?? false;
    var emoji = existing?.emoji.trim().isNotEmpty == true
        ? existing!.emoji.trim()
        : kCategoryEmojiChoices.first;
    var colorValue = existing?.colorValue ??
        defaultNewCategoryColorValue(isIncome: income);
    await showNBStatefulFormDialog(
      context: context,
      title: existing == null ? 'New category' : 'Edit category',
      scrollable: true,
      content: (_, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NBTextField(controller: name, label: 'Name'),
          const SizedBox(height: 12),
          Text(
            'Emoji',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          CategoryEmojiPicker(
            selected: emoji,
            onSelected: (e) => setLocal(() => emoji = e),
          ),
          const SizedBox(height: 12),
          Text(
            'Color',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          CategoryColorPicker(
            selected: colorValue,
            onSelected: (v) => setLocal(() => colorValue = v),
          ),
          NBSwitchRow(
            label: 'Income category',
            value: income,
            onChanged: (v) => setLocal(() => income = v),
          ),
        ],
      ),
      actions: (_, __) => [
        NBDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
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
              emoji: emoji,
              colorValue: colorValue,
            );
            bumpBudgetRefresh(ref);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Future<void> _addBudget(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    List<CategoryLocal> cats,
  ) async {
    final expense = cats.where((c) => !c.isIncome).toList();
    if (expense.isEmpty) return;
    var cat = expense.first;
    final limit = TextEditingController(text: '5000');
    var rollover = false;
    await showNBStatefulFormDialog(
      context: context,
      title: 'Category budget',
      content: (_, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NBDropdownField<CategoryLocal>(
            label: 'Category',
            value: cat,
            items: expense
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      categoryChipLabel(c),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setLocal(() => cat = v ?? cat),
          ),
          const SizedBox(height: 12),
          NBTextField(
            controller: limit,
            label: 'Monthly limit (₹)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          NBSwitchRow(
            label: 'Rollover unused',
            value: rollover,
            onChanged: (v) => setLocal(() => rollover = v),
          ),
        ],
      ),
      actions: (_, __) => [
        NBDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        NBDialogAction(
          label: 'Save',
          primary: true,
          onPressed: () async {
            final lim = BudgetInr.parse(limit.text) ?? 0;
            if (lim <= 0) return;
            await repo.upsertCategoryBudget(
              categoryRemoteId: cat.remoteId,
              categoryName: cat.name,
              limitAmount: lim,
              rolloverEnabled: rollover,
            );
            bumpBudgetRefresh(ref);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _SalaryBlock extends StatefulWidget {
  const _SalaryBlock({required this.amount, required this.onSave});

  final double amount;
  final Future<void> Function(double) onSave;

  @override
  State<_SalaryBlock> createState() => _SalaryBlockState();
}

class _SalaryBlockState extends State<_SalaryBlock> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.amount > 0 ? widget.amount.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NBTextField(
          controller: _ctrl,
          label: 'Amount (₹)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        NBButton(
          label: 'Save salary',
          color: NBMetrics.incomeGreen,
          onPressed: () async {
            final v = BudgetInr.parse(_ctrl.text) ?? 0;
            if (v <= 0) return;
            await widget.onSave(v);
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.cat,
    required this.onTap,
    required this.onArchive,
  });

  final CategoryLocal cat;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: categoryLeadingAvatar(context, cat),
        title: Text(categoryChipLabel(cat)),
        subtitle: Text(cat.isIncome ? 'Income' : 'Expense'),
        trailing: IconButton(
          icon: const Icon(Icons.archive_outlined),
          onPressed: onArchive,
        ),
      ),
    );
  }
}
