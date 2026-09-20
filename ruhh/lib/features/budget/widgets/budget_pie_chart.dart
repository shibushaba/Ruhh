import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';

class BudgetPieSlice {
  const BudgetPieSlice({
    required this.categoryId,
    required this.label,
    required this.amount,
    required this.color,
  });

  final String categoryId;
  final String label;
  final double amount;
  final Color color;
}

class BudgetPieChart extends StatefulWidget {
  const BudgetPieChart({
    super.key,
    required this.slices,
    this.selectedCategoryId,
    this.onSelectedCategoryIdChanged,
  });

  final List<BudgetPieSlice> slices;
  final String? selectedCategoryId;
  final ValueChanged<String?>? onSelectedCategoryIdChanged;

  @override
  State<BudgetPieChart> createState() => _BudgetPieChartState();
}

class _BudgetPieChartState extends State<BudgetPieChart> {
  int? _touchedIndex;

  List<BudgetPieSlice> get _sorted {
    final list = [...widget.slices]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  double get _total =>
      widget.slices.fold<double>(0, (sum, s) => sum + s.amount);

  void _select(String? categoryId) {
    widget.onSelectedCategoryIdChanged?.call(categoryId);
    setState(() {
      _touchedIndex = null;
    });
  }

  void _toggle(BudgetPieSlice slice) {
    final next =
        widget.selectedCategoryId == slice.categoryId ? null : slice.categoryId;
    _select(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final slices = _sorted;

    if (slices.isEmpty || _total <= 0) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No spending this period')),
      );
    }

    BudgetPieSlice? selected;
    for (final s in slices) {
      if (s.categoryId == widget.selectedCategoryId) {
        selected = s;
        break;
      }
    }

    final selectedShare =
        selected != null && _total > 0 ? selected.amount / _total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 56,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions) {
                          setState(() => _touchedIndex = null);
                          return;
                        }
                        final i = response?.touchedSection?.touchedSectionIndex;
                        if (i == null || i < 0 || i >= slices.length) return;
                        setState(() => _touchedIndex = i);
                        if (event is FlTapUpEvent) {
                          _toggle(slices[i]);
                        }
                      },
                    ),
                    sections: [
                      for (var i = 0; i < slices.length; i++)
                        PieChartSectionData(
                          value: slices[i].amount,
                          color: slices[i].color,
                          title: '',
                          showTitle: false,
                          radius: _sliceRadius(i, slices[i].categoryId),
                          borderSide: BorderSide(
                            color: t.textPrimary,
                            width: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      BudgetInr.format(_total),
                      style: t.cardTitle(theme),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Total spent',
                      style: t.micro(theme),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 12),
          RuhhSoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected.color,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: t.textPrimary, width: 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.label,
                        style: theme.titleMedium?.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${BudgetInr.format(selected.amount)} · '
                        '${(selectedShare * 100).toStringAsFixed(1)}% of expenses',
                        style: t.caption(theme),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _select(null),
                  icon: Icon(Icons.close, color: t.textSecondary, size: 20),
                  tooltip: 'Clear',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        ...[
          for (var i = 0; i < slices.length; i++)
            _LegendRow(
              slice: slices[i],
              share: slices[i].amount / _total,
              selected: widget.selectedCategoryId == slices[i].categoryId,
              highlighted: _touchedIndex == i,
              onTap: () => _toggle(slices[i]),
            ),
        ],
      ],
    );
  }

  double _sliceRadius(int index, String categoryId) {
    const base = 46.0;
    if (widget.selectedCategoryId == categoryId) return base + 6;
    if (_touchedIndex == index) return base + 4;
    return base;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.share,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  final BudgetPieSlice slice;
  final double share;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final bg = selected
        ? t.surfaceSecondary
        : highlighted
            ? t.surfaceSecondary.withValues(alpha: 0.6)
            : Colors.transparent;

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: slice.color,
                  border: Border.all(color: t.textPrimary, width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  slice.label,
                  style: theme.bodyMedium?.copyWith(
                    color: t.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                BudgetInr.format(slice.amount),
                style: theme.bodyMedium?.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                child: Text(
                  '${(share * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: t.caption(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
