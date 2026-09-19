import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/budget/budget_format.dart';
import 'package:ruhh/features/budget/budget_schedule.dart';
import 'package:ruhh/features/budget/widgets/budget_ui.dart';

class BudgetTransactionList extends StatelessWidget {
  const BudgetTransactionList({
    super.key,
    required this.transactions,
    this.onTap,
    this.onDelete,
    this.groupByDay = true,
  });

  final List<TransactionLocal> transactions;
  final void Function(TransactionLocal tx)? onTap;
  final void Function(TransactionLocal tx)? onDelete;
  final bool groupByDay;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const BudgetEmptyCard(
        message: 'No transactions in this period.',
      );
    }
    if (!groupByDay) {
      return Column(
        children: transactions.map((t) => _tile(context, t)).toList(),
      );
    }
    final grouped = <String, List<TransactionLocal>>{};
    for (final t in transactions) {
      final key = DateFormat.yMMMEd().format(t.occurredAt);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...entry.value.map((t) => _tile(context, t)),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, TransactionLocal t) {
    final label = t.title.isNotEmpty ? t.title : t.category;
    final amount = BudgetFormat.sanitize(t.amount);
    final signed = t.isIncome ? amount : -amount;
    return BudgetListRow(
      title: label,
      subtitle:
          '${t.account} · ${t.note}${t.scheduleType != BudgetScheduleType.normal ? ' · ${scheduleTypeLabel(t.scheduleType)}' : ''}',
      accent: t.isIncome ? const Color(0xFF2E7D32) : NBColors.budget,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            BudgetFormat.money(signed, showSign: true),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.isIncome ? const Color(0xFF2E7D32) : null,
                ),
          ),
          if (onDelete != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => onDelete!(t),
            ),
        ],
      ),
      onTap: onTap == null ? null : () => onTap!(t),
    );
  }
}
