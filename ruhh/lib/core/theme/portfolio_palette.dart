import 'package:flutter/material.dart';

/// Design tokens from https://shabas.vercel.app (Tailwind / shadcn CSS variables).
abstract final class PortfolioPalette {
  static const deskDark = Color(0xFF050505);
  static const background = Color(0xFF0A0A0A);
  static const foreground = Color(0xFFF5F5F5);
  static const card = Color(0xFF141414);
  static const paper = Color(0xFF0F0F0F);
  static const gridLineDark = Color(0xFF1F1F1F);
  static const border = Color(0xFF383838);
  static const borderHighlight = Color(0x8CFFFFFF);
  static const mutedForeground = Color(0xFF949494);
  static const secondary = Color(0xFF1F1F1F);

  static const deskLight = Color(0xFFEBEBEB);
  static const backgroundLight = Color(0xFFF5F5F5);
  static const paperLight = Color(0xFFFFFFFF);
  static const gridLineLight = Color(0xFFE0E0E0);
  static const inkLight = Color(0xFF0A0A0A);

  static const gridStep = 22.0;
  static const radiusSm = 2.0;
  static const radiusMd = 3.0;

  static const shadowPaper = BoxShadow(
    color: Color(0xB3000000),
    offset: Offset(0, 8),
    blurRadius: 40,
  );

  static const shadowSticker = BoxShadow(
    color: Color(0x80000000),
    offset: Offset(2, 4),
    blurRadius: 0,
  );

  static const deskGradientDark = LinearGradient(
    begin: Alignment(0.5, -1),
    end: Alignment(0.5, 1),
    colors: [
      Color(0x80242424),
      Color(0x00000000),
    ],
    stops: [0, 0.55],
  );

  static const deskGradientAccentDark = RadialGradient(
    center: Alignment(-0.9, 0.9),
    radius: 0.55,
    colors: [
      Color(0x661A1A1A),
      Color(0x00000000),
    ],
  );
}

class PortfolioGridPainter extends CustomPainter {
  PortfolioGridPainter({
    required this.lineColor,
    this.step = PortfolioPalette.gridStep,
  });

  final Color lineColor;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PortfolioGridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.step != step;
}
