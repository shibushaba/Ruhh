import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/budget/budget_schedule.dart';
import 'package:ruhh/core/widgets/nb_card.dart';

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
      return const NBCard(child: Text('No transactions in this period.'));
    }
    if (!groupByDay) {
      return Column(
        children: transactions
            .map((t) => _tile(context, t))
            .toList(),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NBCard(
        child: ListTile(
          onTap: onTap == null ? null : () => onTap!(t),
          title: Text(label),
          subtitle: Text(
            '${t.account} · ${t.note}${t.scheduleType != BudgetScheduleType.normal ? ' · ${scheduleTypeLabel(t.scheduleType)}' : ''}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${t.isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: t.isIncome ? Colors.green.shade800 : NBColors.budget,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete!(t),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
