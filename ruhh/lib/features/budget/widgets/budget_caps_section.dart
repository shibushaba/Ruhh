import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/motion/animated_progress_bar.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/budget/budget_page.dart';
import 'package:ruhh/features/budget/ledger/budget_calculations.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/budget/widgets/category_display.dart';

/// Home tab — category caps + unbudgeted spend (vector B&W).
class BudgetCapsSection extends ConsumerWidget {
  const BudgetCapsSection({
    super.key,
    required this.expenseCats,
    required this.budgetedIds,
    required this.rules,
    required this.rows,
    required this.byCat,
    required this.monthKey,
  });

  final List<CategoryLocal> expenseCats;
  final Set<String> budgetedIds;
  final List<BudgetRuleRow> rules;
  final List<BudgetLedgerRow> rows;
  final Map<String, double> byCat;
  final String monthKey;

  BudgetRuleRow? _ruleFor(String categoryId) {
    for (final r in rules) {
      if (r.categoryId != categoryId) continue;
      if (r.monthKey == monthKey || r.monthKey == 'recurring') return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final capped = expenseCats.where((c) => budgetedIds.contains(c.remoteId)).toList();
    final unbudgeted = expenseCats
        .where((c) =>
            !budgetedIds.contains(c.remoteId) && (byCat[c.remoteId] ?? 0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budgets', style: t.cardTitle(theme)),
                  const SizedBox(height: 4),
                  Text(
                    'Per-category caps for this month',
                    style: t.caption(theme),
                  ),
                ],
              ),
            ),
            _CountBadge(count: capped.length, label: 'caps'),
          ],
        ),
        const SizedBox(height: 12),
        if (capped.isEmpty)
          _EmptyCapsCard(
            onManage: () {
              ref.read(budgetTabIndexProvider.notifier).state = 4;
              context.go('/budget?tab=4');
            },
          )
        else
          ...capped.map((cat) {
            final spend = BudgetCalculations.categorySpend(
              rows,
              monthKey,
              cat.remoteId,
            );
            final ratio = BudgetCalculations.budgetUsageRatio(
                  rows,
                  rules,
                  monthKey,
                  cat.remoteId,
                ) ??
                0;
            final rule = _ruleFor(cat.remoteId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CapCard(
                cat: cat,
                spend: spend,
                limit: rule?.limitAmount,
                ratio: ratio.clamp(0, 1.2),
                rollover: rule?.rolloverEnabled ?? false,
              ),
            );
          }),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text('Spend without budget', style: t.cardTitle(theme)),
            ),
            if (unbudgeted.isNotEmpty)
              _CountBadge(count: unbudgeted.length, label: 'open'),
          ],
        ),
        const SizedBox(height: 10),
        if (unbudgeted.isEmpty)
          RuhhSoftCard(
            padding: EdgeInsets.all(t.spaceCardPaddingCompact),
            child: Row(
              children: [
                Icon(AppIcons.check(), size: 22, color: t.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All spending this month is under a cap.',
                    style: t.caption(theme),
                  ),
                ),
              ],
            ),
          )
        else
          ...unbudgeted.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UnbudgetedRow(
                cat: cat,
                amount: byCat[cat.remoteId]!,
              ),
            ),
          ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: t.textPrimary, width: 1),
        borderRadius: BorderRadius.circular(t.radiusChip),
      ),
      child: Text(
        '$count $label',
        style: t.micro(Theme.of(context).textTheme),
      ),
    );
  }
}

class _EmptyCapsCard extends StatelessWidget {
  const _EmptyCapsCard({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return RuhhSoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VectorStackIcon(accent: t.textPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No caps yet', style: t.statMedium(theme)),
                    const SizedBox(height: 6),
                    Text(
                      'Give each category a monthly limit so you can see usage at a glance.',
                      style: t.caption(theme),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RuhhSecondaryButton(
            label: 'Add caps in Manage',
            onPressed: onManage,
          ),
        ],
      ),
    );
  }
}

class _VectorStackIcon extends StatelessWidget {
  const _VectorStackIcon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 8,
            child: _box(32, accent.withValues(alpha: 0.25)),
          ),
          Positioned(
            left: 8,
            top: 4,
            child: _box(32, accent.withValues(alpha: 0.45)),
          ),
          Positioned(
            left: 16,
            top: 0,
            child: _box(32, accent),
          ),
        ],
      ),
    );
  }

  Widget _box(double size, Color border) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 1.5),
        color: Colors.transparent,
      ),
      child: Center(
        child: Icon(AppIcons.wallet(), size: 16, color: border),
      ),
    );
  }
}

class _CapCard extends StatelessWidget {
  const _CapCard({
    required this.cat,
    required this.spend,
    required this.limit,
    required this.ratio,
    required this.rollover,
  });

  final CategoryLocal cat;
  final double spend;
  final double? limit;
  final double ratio;
  final bool rollover;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final pct = (ratio * 100).clamp(0, 999).round();
    final over = ratio > 1;
    final barColor = over ? t.textPrimary : t.textSecondary;

    return RuhhSoftCard(
      padding: EdgeInsets.all(t.spaceCardPaddingCompact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              categoryLeadingAvatar(context, cat, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: theme.titleMedium?.copyWith(color: t.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      limit != null
                          ? 'Limit ${BudgetInr.format(limit!)}${rollover ? ' · rollover' : ''}'
                          : 'No limit set',
                      style: t.micro(theme),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    over ? 'OVER' : '$pct%',
                    style: t.micro(theme).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: over ? 1.2 : 0,
                        ),
                  ),
                  Text(
                    BudgetInr.format(spend),
                    style: theme.titleSmall?.copyWith(color: t.textPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedProgressBar(
            progress: ratio.clamp(0, 1),
            color: barColor,
            height: 8,
          ),
          if (limit != null && limit! > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${BudgetInr.format((limit! - spend).clamp(0, limit!))} left',
              style: t.micro(theme),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnbudgetedRow extends StatelessWidget {
  const _UnbudgetedRow({required this.cat, required this.amount});

  final CategoryLocal cat;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return RuhhSoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          categoryLeadingAvatar(context, cat, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: theme.titleSmall),
                Text('Uncapped', style: t.micro(theme)),
              ],
            ),
          ),
          Text(
            BudgetInr.format(amount),
            style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
