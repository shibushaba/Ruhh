import 'dart:ui';

/// Maps a normalized point on the 1080×2340 plate onto a screen that paints
/// that plate with [BoxFit.cover].
class PlateCover {
  PlateCover(this.size);

  final Size size;

  static const plateWidth = 1080.0;
  static const plateHeight = 2340.0;

  double get scale {
    final sx = size.width / plateWidth;
    final sy = size.height / plateHeight;
    return sx > sy ? sx : sy;
  }

  double get originX => (size.width - plateWidth * scale) / 2;
  double get originY => (size.height - plateHeight * scale) / 2;

  Offset at(double x, double y) {
    return Offset(
      originX + x * plateWidth * scale,
      originY + y * plateHeight * scale,
    );
  }
}
