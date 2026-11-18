import 'package:flutter/material.dart';

abstract final class V14Colors {
  static const base = Color(0xFF0E0F10);
  static const surface = Color(0xFF16181A);
  static const raised = Color(0xFF1F2225);
  static const hairline = Color(0xFF2A2E32);
  static const lineStrong = Color(0xFF3A3F44);
  static const text = Color(0xFFF4EEDC);
  static const muted = Color(0xFFB3B0A9);
  static const dim = Color(0xFF8F9194);
  static const missed = Color(0xFF7F9A96);
  static const jade = Color(0xFF3FC08A);
  static const amber = Color(0xFFF2A93B);
  static const lavender = Color(0xFFB9A6F2);
  static const gold = Color(0xFFE8C26A);

  static const moneyFills = <Color>[
    Color(0xFF7BD389),
    Color(0xFFF2A93B),
    Color(0xFF8F9194),
    Color(0xFF6CC3E8),
  ];
}

abstract final class V14Fonts {
  static const display = 'MochiyPopOne';
  static const body = 'ZenMaruGothic';
  static const companion = 'KiwiMaru';
  static const malayalam = 'NotoSansMalayalam';
  static const arabic = 'NotoNaskhArabic';
  static const fallback = <String>[malayalam, arabic, body];
}

TextStyle v14Text(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = V14Colors.text,
  String family = V14Fonts.body,
  double? height,
}) {
  return TextStyle(
    fontFamily: family,
    fontFamilyFallback: V14Fonts.fallback,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}
