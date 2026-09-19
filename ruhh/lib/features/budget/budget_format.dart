/// Safe money formatting for budget UI (handles corrupt / NaN ledger values).
abstract final class BudgetFormat {
  static double sanitize(double value) =>
      value.isFinite ? value : 0;

  static String money(
    double value, {
    int decimals = 2,
    bool showSign = false,
    String symbol = '\$',
  }) {
    final v = sanitize(value);
    final core = v.toStringAsFixed(decimals);
    if (!showSign) return '$symbol$core';
    if (v >= 0) return '+$symbol$core';
    return '-$symbol${v.abs().toStringAsFixed(decimals)}';
  }

  static String compact(double value, {String symbol = '\$'}) {
    final v = sanitize(value);
    if (v.abs() >= 1000) {
      return '$symbol${(v / 1000).toStringAsFixed(1)}k';
    }
    return money(v, decimals: 0);
  }
}
