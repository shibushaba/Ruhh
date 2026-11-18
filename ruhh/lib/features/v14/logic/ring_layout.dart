import 'dart:math' as math;
import 'dart:ui';

class RingSlot {
  const RingSlot({
    required this.id,
    required this.center,
    required this.parentId,
  });
  final String id;
  final Offset center;
  final String? parentId;
}

class RingLayout {
  const RingLayout({
    required this.origin,
    required this.radius,
    required this.leftHand,
  });

  final Offset origin;
  final double radius;
  final bool leftHand;

  static const hitRadius = 26.0;

  List<RingSlot> nodes(List<String> ids) {
    return [
      for (var i = 0; i < ids.length; i++)
        RingSlot(
          id: ids[i],
          center: _at(i, ids.length, radius),
          parentId: null,
        ),
    ];
  }

  List<RingSlot> subs(
    String parentId,
    int parentIndex,
    int parentCount,
    List<String> subIds,
  ) {
    final base = _angle(parentIndex, parentCount);
    return [
      for (var i = 0; i < subIds.length; i++)
        RingSlot(
          id: subIds[i],
          center:
              origin +
              _vec(base + (i - (subIds.length - 1) / 2) * 0.32, radius + 78),
          parentId: parentId,
        ),
    ];
  }

  String? hit(Offset point, List<RingSlot> slots) {
    String? found;
    var best = hitRadius;
    for (final slot in slots) {
      final d = (slot.center - point).distance;
      if (d <= best) {
        best = d;
        found = slot.id;
      }
    }
    return found;
  }

  Offset _at(int index, int count, double r) =>
      origin + _vec(_angle(index, count), r);

  double _angle(int index, int count) {
    const lift = 0.35;
    if (count <= 1) return leftHand ? -math.pi / 2 : math.pi * 1.5;
    final t = index / (count - 1);
    // Upper half, lifted off the horizontal so nodes clear the orb.
    // Left-hand starts on the right and sweeps toward the left.
    final start = leftHand ? -lift : math.pi + lift;
    final sweep = leftHand ? -(math.pi - lift * 2) : (math.pi - lift * 2);
    return start + sweep * t;
  }

  Offset _vec(double angle, double r) =>
      Offset(math.cos(angle) * r, math.sin(angle) * r);
}
