import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/ledger/budget_calculations.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/budget/tracker/budget_trends_insights.dart';
import 'package:ruhh/features/budget/widgets/category_display.dart';

/// Section 7.7 — 6-month trends with insights and top spend.
class BudgetTrendsPage extends ConsumerWidget {
  const BudgetTrendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;

    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: Future.wait([
          repo.ledgerRows(),
          repo.activeCategories(income: false),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data![0] as List<BudgetLedgerRow>;
          final expenseCats = snap.data![1] as List<CategoryLocal>;
          final snapshot = BudgetTrendsInsights.build(
            rows,
            expenseCategories: expenseCats,
          );

          CategoryLocal? catById(String id) {
            for (final c in expenseCats) {
              if (c.remoteId == id) return c;
            }
            return null;
          }

          final maxY = snapshot.monthlyTotals
              .map((m) => [m.totalIncome, m.totalExpense])
              .expand((e) => e)
              .fold<double>(0, (a, b) => a > b ? a : b);

          final insights = _buildInsightLines(context, snapshot, expenseCats);

          return NBPageBody(
            child: ListView(
              children: [
                NBSection(
                  title: 'Last 6 months',
                  subtitle: 'Income vs expense at a glance',
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _KpiTile(
                              label: 'Income',
                              value: BudgetInr.format(snapshot.totalIncome),
                              accent: NBMetrics.incomeGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KpiTile(
                              label: 'Spent',
                              value: BudgetInr.format(snapshot.totalExpense),
                              accent: NBMetrics.expenseRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _KpiTile(
                              label: 'Net saved',
                              value: BudgetInr.format(snapshot.netSaved),
                              accent: snapshot.netSaved >= 0
                                  ? t.textPrimary
                                  : NBMetrics.expenseRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KpiTile(
                              label: 'Savings rate',
                              value:
                                  '${(snapshot.savingsRate * 100).toStringAsFixed(0)}%',
                              accent: t.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NBSection(
                  title: 'Monthly chart',
                  subtitle: 'Green income · red expenses',
                  child: RuhhSoftCard(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _LegendDot(
                              label: 'Income',
                              fill: NBMetrics.incomeGreen,
                              outline: false,
                            ),
                            const SizedBox(width: 16),
                            _LegendDot(
                              label: 'Expense',
                              fill: NBMetrics.expenseRed,
                              outline: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              maxY: maxY <= 0 ? 1000 : maxY * 1.15,
                              minY: 0,
                              alignment: BarChartAlignment.spaceAround,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: maxY <= 0
                                    ? 250
                                    : (maxY * 1.15 / 4)
                                        .clamp(1, double.infinity),
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: t.divider,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border:
                                    Border.all(color: t.textPrimary, width: 1),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (v, meta) {
                                      final i = v.toInt();
                                      if (i < 0 ||
                                          i >= snapshot.monthKeys.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _monthLabel(snapshot.monthKeys[i]),
                                          style: t.micro(theme),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              barGroups: [
                                for (var i = 0;
                                    i < snapshot.monthKeys.length;
                                    i++)
                                  BarChartGroupData(
                                    x: i,
                                    barsSpace: 6,
                                    barRods: [
                                      BarChartRodData(
                                        toY: snapshot
                                            .monthlyTotals[i].totalIncome,
                                        color: NBMetrics.incomeGreen,
                                        width: 12,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(2),
                                        ),
                                      ),
                                      BarChartRodData(
                                        toY: snapshot
                                            .monthlyTotals[i].totalExpense,
                                        color: NBMetrics.expenseRed,
                                        width: 12,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                NBSection(
                  title: 'Insights',
                  subtitle: 'Patterns from your last six months',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final line in insights)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InsightCard(text: line),
                        ),
                      _InsightCard(
                        text:
                            'All-time balance: ${BudgetInr.format(snapshot.allTimeBalance)}',
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NBSection(
                  title: 'By category',
                  subtitle: 'All expense categories · last 6 months',
                  child: snapshot.topSpend.isEmpty
                      ? const NBEmptyState(
                          message: 'Add expense categories in Manage to see them here.',
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < snapshot.topSpend.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TopSpendRow(
                                  rank: i + 1,
                                  cat: catById(
                                    snapshot.topSpend[i].categoryId,
                                  ),
                                  categoryId:
                                      snapshot.topSpend[i].categoryId,
                                  amount: snapshot.topSpend[i].amount,
                                  share: snapshot.topSpend[i].shareOfExpense,
                                ),
                              ),
                          ],
                        ),
                ),
                const RuhhNavClearance(extra: 12),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  static String _monthLabel(String monthKey) {
    final parts = monthKey.split('-');
    return DateFormat.MMM().format(
      DateTime(int.parse(parts[0]), int.parse(parts[1])),
    );
  }

  static List<String> _buildInsightLines(
    BuildContext context,
    BudgetTrendsSnapshot snapshot,
    List<CategoryLocal> expenseCats,
  ) {
    final lines = <String>[];

    if (snapshot.highestExpenseMonthKey != null &&
        snapshot.highestExpenseAmount > 0) {
      lines.add(
        'Highest spend month: ${_monthLabel(snapshot.highestExpenseMonthKey!)} '
        '(${BudgetInr.format(snapshot.highestExpenseAmount)})',
      );
    }

    if (snapshot.topSpend.isNotEmpty) {
      final top = snapshot.topSpend.first;
      final cat = _categoryById(expenseCats, top.categoryId);
      final name = cat != null
          ? categoryChipLabel(cat)
          : BudgetTrendsInsights.categoryLabel(top.categoryId, expenseCats);
      final pct = (top.shareOfExpense * 100).toStringAsFixed(0);
      lines.add('Top category: $name · $pct% of spend');
    }

    if (snapshot.savingsRate > 0) {
      lines.add(
        'You kept ${(snapshot.savingsRate * 100).toStringAsFixed(0)}% of income '
        'after expenses (6-month average).',
      );
    }

    final expenseDelta = snapshot.expenseChangeVsPriorMonth;
    if (expenseDelta != 0) {
      final dir = expenseDelta > 0 ? 'up' : 'down';
      lines.add(
        'This month vs last: spending $dir ${BudgetInr.format(expenseDelta.abs())}.',
      );
    }

    final incomeDelta = snapshot.incomeChangeVsPriorMonth;
    if (incomeDelta != 0) {
      final dir = incomeDelta > 0 ? 'up' : 'down';
      lines.add(
        'Income $dir ${BudgetInr.format(incomeDelta.abs())} vs prior month.',
      );
    }

    if (lines.isEmpty) {
      lines.add('Add transactions to unlock trend insights.');
    }

    return lines;
  }

  static CategoryLocal? _categoryById(
    List<CategoryLocal> cats,
    String id,
  ) {
    for (final c in cats) {
      if (c.remoteId == id) return c;
    }
    return null;
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return RuhhSoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.caption(theme)),
            const SizedBox(height: 4),
            Text(
              value,
              style: t.cardTitle(theme).copyWith(color: accent),
            ),
          ],
        ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text, this.emphasized = false});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return RuhhSoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: emphasized ? t.cardTitle(theme) : theme.bodyMedium!.copyWith(
              color: t.textPrimary,
            ),
      ),
    );
  }
}

class _TopSpendRow extends StatelessWidget {
  const _TopSpendRow({
    required this.rank,
    required this.cat,
    required this.categoryId,
    required this.amount,
    required this.share,
  });

  final int rank;
  final CategoryLocal? cat;
  final String categoryId;
  final double amount;
  final double share;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final accent = categoryAccentColorOrFallback(cat, rank - 1);
    final label = cat != null
        ? categoryChipLabel(cat!)
        : categoryId;

    return RuhhSoftCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (cat != null)
                categoryLeadingAvatar(context, cat!, radius: 14)
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accent, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: t.micro(theme).copyWith(color: t.textPrimary),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.bodyMedium!.copyWith(
                    color: t.textPrimary,
                  ),
                ),
              ),
              Text(
                BudgetInr.format(amount),
                style: t.cardTitle(theme).copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: share.clamp(0, 1),
              minHeight: 6,
              backgroundColor: t.surfaceSecondary,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(share * 100).toStringAsFixed(0)}% of 6-month spend',
            style: t.micro(theme),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.fill,
    this.outline = false,
  });

  final String label;
  final Color fill;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: fill,
            border: outline ? Border.all(color: t.textPrimary, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: t.micro(Theme.of(context).textTheme)),
      ],
    );
  }
}
