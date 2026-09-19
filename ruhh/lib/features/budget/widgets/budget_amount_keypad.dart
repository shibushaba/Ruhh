import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';

class BudgetAmountKeypad extends StatefulWidget {
  const BudgetAmountKeypad({
    super.key,
    required this.onAmount,
    this.initial = '',
  });

  final ValueChanged<double> onAmount;
  final String initial;

  @override
  State<BudgetAmountKeypad> createState() => _BudgetAmountKeypadState();
}

class _BudgetAmountKeypadState extends State<BudgetAmountKeypad> {
  late String _expr;

  @override
  void initState() {
    super.initState();
    _expr = widget.initial;
  }

  void _tap(String key) {
    setState(() {
      if (key == 'C') {
        _expr = '';
      } else if (key == '⌫') {
        if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
      } else {
        _expr += key;
      }
    });
  }

  double? _evaluate() {
    if (_expr.trim().isEmpty) return null;
    try {
      final p = Parser();
      final cm = ContextModel();
      final exp = p.parse(_expr.replaceAll('×', '*').replaceAll('÷', '/'));
      final v = exp.evaluate(EvaluationType.REAL, cm);
      if (v is num && v.isFinite) return v.toDouble();
    } catch (_) {}
    return double.tryParse(_expr);
  }

  @override
  Widget build(BuildContext context) {
    final value = _evaluate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(width: 3),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _expr.isEmpty ? '0' : _expr,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                value == null ? '—' : value.toStringAsFixed(2),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _keys(['7', '8', '9', '÷']),
        _keys(['4', '5', '6', '×']),
        _keys(['1', '2', '3', '-']),
        _keys(['C', '0', '.', '+']),
        const SizedBox(height: 8),
        NBButton(
          label: 'Use amount',
          color: NBColors.budget,
          onPressed: value == null || value <= 0
              ? null
              : () => widget.onAmount(value),
        ),
      ],
    );
  }

  Widget _keys(List<String> row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: row
            .map(
              (k) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: NBColors.budget.withValues(alpha: 0.15),
                    child: InkWell(
                      onTap: () => _tap(k),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(width: 2),
                        ),
                        child: Text(k, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
