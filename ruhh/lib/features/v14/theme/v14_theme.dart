import 'package:flutter/material.dart';
import 'package:ruhh/features/v14/theme/v14_colors.dart';

class V14Theme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: V14Colors.jade,
      onPrimary: V14Colors.base,
      secondary: V14Colors.amber,
      onSecondary: V14Colors.base,
      surface: V14Colors.surface,
      onSurface: V14Colors.text,
      error: V14Colors.missed,
      onError: V14Colors.base,
      outline: V14Colors.hairline,
    );
    final text = TextTheme(
      displayLarge: v14Text(
        32,
        family: V14Fonts.display,
        weight: FontWeight.w400,
      ),
      headlineMedium: v14Text(
        22,
        family: V14Fonts.display,
        weight: FontWeight.w400,
      ),
      titleLarge: v14Text(18, weight: FontWeight.w700),
      titleMedium: v14Text(15, weight: FontWeight.w700),
      bodyLarge: v14Text(15),
      bodyMedium: v14Text(13, color: V14Colors.muted),
      bodySmall: v14Text(12, color: V14Colors.dim),
      labelLarge: v14Text(14, weight: FontWeight.w700),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: V14Colors.base,
      colorScheme: scheme,
      textTheme: text,
      fontFamily: V14Fonts.body,
      fontFamilyFallback: V14Fonts.fallback,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: V14Colors.base,
        foregroundColor: V14Colors.text,
        elevation: 0,
        titleTextStyle: v14Text(18, family: V14Fonts.display),
      ),
      dividerColor: V14Colors.hairline,
    );
  }
}
