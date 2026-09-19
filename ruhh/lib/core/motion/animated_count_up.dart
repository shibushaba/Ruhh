import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// B.4 — animates numeric display with easing.
class AnimatedCountUp extends StatelessWidget {
  const AnimatedCountUp({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 700),
    this.formatter,
    this.prefix = '',
    this.suffix = '',
  });

  final double value;
  final TextStyle style;
  final Duration duration;
  final String Function(double v)? formatter;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, v, _) {
        final text = formatter != null
            ? formatter!(v)
            : _formatDefault(v);
        return Text(
          '$prefix$text$suffix',
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  String _formatDefault(double v) {
    if (v == v.roundToDouble()) {
      return v.round().toString();
    }
    return v.toStringAsFixed(1);
  }
}

class AnimatedCurrencyCountUp extends StatelessWidget {
  const AnimatedCurrencyCountUp({
    super.key,
    required this.amount,
    required this.style,
    this.locale = 'en_IN',
    this.symbol = '₹',
  });

  final double amount;
  final TextStyle style;
  final String locale;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: 0);
    return AnimatedCountUp(
      value: amount,
      style: style,
      duration: const Duration(milliseconds: 800),
      formatter: (v) => fmt.format(v),
    );
  }
}
