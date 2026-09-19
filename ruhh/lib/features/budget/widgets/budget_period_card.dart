import 'package:flutter/material.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/budget/budget_format.dart';

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
    final limit = BudgetFormat.sanitize(budget.limitAmount);
    final spentSafe = BudgetFormat.sanitize(spent);
    final remaining = limit - spentSafe;
    final progress = limit <= 0 ? 0.0 : (spentSafe / limit).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NBMetrics.radius + 4),
          child: NBGlassSurface(
            accent: NBColors.budget,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(budget.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  remaining >= 0
                      ? '${BudgetFormat.money(remaining, decimals: 0)} left'
                      : '${BudgetFormat.money(-remaining, decimals: 0)} over',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${BudgetFormat.money(spentSafe, decimals: 0)} of ${BudgetFormat.money(limit, decimals: 0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                NBProgressBar(
                  progress: progress,
                  color: remaining >= 0 ? NBColors.budget : Colors.red.shade700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
