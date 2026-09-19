import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/budget_schedule.dart';
import 'package:ruhh/features/budget/widgets/budget_amount_keypad.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({
    super.key,
    this.transactionId,
    this.objectiveRemoteId,
  });

  final int? transactionId;
  final String? objectiveRemoteId;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  double? _amount;
  String? _category;
  String? _wallet;
  bool _income = false;
  DateTime _date = DateTime.now();
  TransactionLocal? _existing;
  BudgetScheduleType _scheduleType = BudgetScheduleType.normal;
  String _recurrence = 'monthly';
  int _periodLength = 1;
  String? _objectiveRemoteId;
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _periodCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _objectiveRemoteId = widget.objectiveRemoteId;
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.transactionId == null) return;
    final repo = await ref.read(budgetRepositoryProvider.future);
    final tx = await repo.getTransaction(widget.transactionId!);
    if (tx == null || !mounted) return;
    setState(() {
      _existing = tx;
      _amount = tx.amount;
      _category = tx.category;
      _wallet = tx.account;
      _income = tx.isIncome;
      _date = tx.occurredAt;
      _scheduleType = tx.scheduleType;
      _recurrence = tx.recurrence == 'none' ? 'monthly' : tx.recurrence;
      _periodLength = tx.periodLength;
      _periodCtrl.text = tx.periodLength.toString();
      _objectiveRemoteId = tx.objectiveRemoteId;
      _titleCtrl.text = tx.title;
      _noteCtrl.text = tx.note;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BudgetRepository repo) async {
    final amount = _amount;
    final category = _category;
    final wallet = _wallet;
    if (amount == null || amount <= 0 || category == null || wallet == null) {
      return;
    }
    if (_existing != null) {
      _existing!
        ..amount = amount
        ..title = _titleCtrl.text.trim()
        ..note = _noteCtrl.text.trim()
        ..category = category
        ..account = wallet
        ..isIncome = _income
        ..occurredAt = _date
        ..scheduleType = _scheduleType
        ..recurrence =
            _scheduleType == BudgetScheduleType.normal ? 'none' : _recurrence
        ..periodLength = _periodLength
        ..objectiveRemoteId = _objectiveRemoteId;
      if (_scheduleType == BudgetScheduleType.normal) {
        _existing!.paid = true;
      }
      await repo.updateTransaction(_existing!);
    } else {
      await repo.add(
        amount: amount,
        isIncome: _income,
        category: category,
        account: wallet,
        title: _titleCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        occurredAt: _date,
        scheduleType: _scheduleType,
        recurrence:
            _scheduleType == BudgetScheduleType.normal ? 'none' : _recurrence,
        periodLength: _periodLength,
        objectiveRemoteId: _objectiveRemoteId,
      );
    }
    bumpBudgetRefresh(ref);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: Future.wait([
          repo.categories(income: _income),
          repo.wallets(),
          repo.objectives(),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const NBModuleScaffold(
              title: 'Transaction',
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final cats = snap.data![0] as List<CategoryLocal>;
          final wallets = snap.data![1] as List<WalletLocal>;
          final objectives = snap.data![2] as List<ObjectiveLocal>;
          _category ??= cats.isNotEmpty ? cats.first.name : null;
          _wallet ??= wallets.isNotEmpty ? wallets.first.name : null;

          return NBModuleScaffold(
            title: _existing == null ? 'Add transaction' : 'Edit transaction',
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    NBChip(
                      label: 'Expense',
                      selected: !_income,
                      onTap: () => setState(() {
                        _income = false;
                        _category = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    NBChip(
                      label: 'Income',
                      selected: _income,
                      color: NBColors.budget,
                      onTap: () => setState(() {
                        _income = true;
                        _category = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Schedule type',
                    style: Theme.of(context).textTheme.titleMedium),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: BudgetScheduleType.values
                      .map(
                        (type) => NBChip(
                          label: scheduleTypeLabel(type),
                          selected: _scheduleType == type,
                          color: NBColors.budget,
                          onTap: () => setState(() => _scheduleType = type),
                        ),
                      )
                      .toList(),
                ),
                if (_scheduleType != BudgetScheduleType.normal) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _recurrence,
                    decoration: const InputDecoration(labelText: 'Repeats'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(
                          value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    ],
                    onChanged: (v) =>
                        setState(() => _recurrence = v ?? _recurrence),
                  ),
                  Row(
                    children: [
                      const Text('Every '),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: _periodCtrl,
                          onChanged: (v) => setState(() {
                            _periodLength =
                                int.tryParse(v)?.clamp(1, 365) ?? 1;
                          }),
                        ),
                      ),
                      Text(' ${_recurrence == 'daily' ? 'day(s)' : _recurrence == 'weekly' ? 'week(s)' : _recurrence == 'yearly' ? 'year(s)' : 'month(s)'}'),
                    ],
                  ),
                ],
                if (objectives.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _objectiveRemoteId,
                    decoration: const InputDecoration(labelText: 'Link to goal (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...objectives.map(
                        (o) => DropdownMenuItem(
                          value: o.remoteId,
                          child: Text(o.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _objectiveRemoteId = v),
                  ),
                ],
                const SizedBox(height: 12),
                if (_amount != null)
                  NBCard(
                    child: Text(
                      'Amount: \$${_amount!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                BudgetAmountKeypad(
                  onAmount: (v) => setState(() => _amount = v),
                ),
                const SizedBox(height: 16),
                NBTextField(controller: _titleCtrl, label: 'Title'),
                NBTextField(controller: _noteCtrl, label: 'Notes'),
                Text('Category', style: Theme.of(context).textTheme.titleMedium),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cats
                      .map(
                        (c) => NBChip(
                          label: c.name,
                          selected: _category == c.name,
                          color: Color(c.colorValue),
                          onTap: () => setState(() => _category = c.name),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text('Wallet', style: Theme.of(context).textTheme.titleMedium),
                Wrap(
                  spacing: 6,
                  children: wallets
                      .map(
                        (w) => NBChip(
                          label: w.name,
                          selected: _wallet == w.name,
                          onTap: () => setState(() => _wallet = w.name),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: 16),
                NBButton(
                  label: 'Save',
                  color: NBColors.budget,
                  onPressed: () => _save(repo),
                ),
                if (_existing != null) ...[
                  const SizedBox(height: 8),
                  NBButton(
                    label: 'Delete',
                    color: Colors.red,
                    onPressed: () async {
                      await repo.delete(_existing!.id);
                      bumpBudgetRefresh(ref);
                      if (context.mounted) context.pop();
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
      loading: () => const NBModuleScaffold(
        title: 'Transaction',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => NBModuleScaffold(title: 'Transaction', body: Text('$e')),
    );
  }
}
