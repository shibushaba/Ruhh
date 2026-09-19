import 'package:intl/intl.dart';

/// Indian rupee formatting (en_IN) — Section 2 & 8.
abstract final class BudgetInr {
  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _currencyPrecise = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(num amount, {bool precise = false}) {
    final v = amount.isFinite ? amount : 0;
    return precise ? _currencyPrecise.format(v) : _currency.format(v);
  }

  static String formatSigned(num amount, {bool precise = false}) {
    final v = amount.isFinite ? amount : 0;
    if (v >= 0) return '+${format(v, precise: precise)}';
    return '-${format(v.abs(), precise: precise)}';
  }

  static double? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[₹,\s]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
