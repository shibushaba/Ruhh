import 'dart:math' as math;
import 'dart:ui';

class TreemapTile {
  const TreemapTile({
    required this.label,
    required this.value,
    required this.rect,
  });
  final String label;
  final double value;
  final Rect rect;
}

/// Squarified treemap. Values must be positive. Empty input returns an empty list.
List<TreemapTile> layoutTreemap(Rect bounds, Map<String, double> values) {
  final entries = values.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (entries.isEmpty || bounds.width <= 0 || bounds.height <= 0) {
    return const [];
  }
  final total = entries.fold<double>(0, (s, e) => s + e.value);
  final tiles = <TreemapTile>[];
  _squarify(entries, total, bounds, tiles);
  return tiles;
}

void _squarify(
  List<MapEntry<String, double>> entries,
  double total,
  Rect bounds,
  List<TreemapTile> out,
) {
  if (entries.isEmpty) return;
  if (entries.length == 1) {
    out.add(
      TreemapTile(
        label: entries.first.key,
        value: entries.first.value,
        rect: bounds,
      ),
    );
    return;
  }
  final vertical = bounds.width < bounds.height;
  final side = vertical ? bounds.height : bounds.width;
  var running = 0.0;
  var lastWorst = double.infinity;
  var split = 1;
  for (var i = 0; i < entries.length; i++) {
    running += entries[i].value;
    final worst = _worst(
      entries.sublist(0, i + 1),
      running,
      side,
      bounds,
      total,
    );
    if (worst > lastWorst && i > 0) {
      split = i;
      running -= entries[i].value;
      break;
    }
    lastWorst = worst;
    split = i + 1;
  }
  final rowSum = entries.take(split).fold<double>(0, (s, e) => s + e.value);
  final span = (vertical ? bounds.height : bounds.width) * (rowSum / total);
  var cursor = vertical ? bounds.top : bounds.left;
  for (final entry in entries.take(split)) {
    final frac = entry.value / rowSum;
    final length = (vertical ? bounds.width : bounds.height) * frac;
    final rect = vertical
        ? Rect.fromLTWH(bounds.left, cursor, length, span)
        : Rect.fromLTWH(cursor, bounds.top, span, length);
    out.add(TreemapTile(label: entry.key, value: entry.value, rect: rect));
    cursor += length;
  }
  final rest = entries.sublist(split);
  if (rest.isEmpty) return;
  final restTotal = rest.fold<double>(0, (s, e) => s + e.value);
  final restBounds = vertical
      ? Rect.fromLTWH(
          bounds.left,
          bounds.top + span,
          bounds.width,
          bounds.height - span,
        )
      : Rect.fromLTWH(
          bounds.left + span,
          bounds.top,
          bounds.width - span,
          bounds.height,
        );
  _squarify(rest, restTotal, restBounds, out);
}

double _worst(
  List<MapEntry<String, double>> row,
  double rowSum,
  double side,
  Rect bounds,
  double total,
) {
  final rowLen =
      (bounds.width < bounds.height ? bounds.height : bounds.width) *
      (rowSum / total);
  if (rowLen <= 0) return double.infinity;
  var worst = 0.0;
  for (final entry in row) {
    final length =
        (bounds.width < bounds.height ? bounds.width : bounds.height) *
        (entry.value / rowSum);
    final ratio = math.max(rowLen, length) / math.min(rowLen, length);
    if (ratio > worst) worst = ratio;
  }
  return worst;
}
