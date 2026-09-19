import 'package:flutter/material.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';

class BudgetPeriodCard extends StatelessWidget {
  const BudgetPeriodCard({
    super.key,
    required this.budget,
    required this.spent,
    this.onTap,
  });

  final BudgetPeriodLocal budget;
  final double spent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final limit = budget.limitAmount;
    final remaining = limit - spent;
    final progress = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final color = Color(budget.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NBCard(
        color: color.withValues(alpha: 0.35),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(budget.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              remaining >= 0
                  ? '\$${remaining.toStringAsFixed(0)} left'
                  : '\$${(-remaining).toStringAsFixed(0)} over',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '\$${spent.toStringAsFixed(0)} of \$${limit.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white,
                color: remaining >= 0 ? NBColors.budget : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
