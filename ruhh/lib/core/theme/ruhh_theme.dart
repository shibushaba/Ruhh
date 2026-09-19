import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

class RuhhTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fg = isDark ? NBColors.white : NBColors.black;
    final muted = NBColors.mutedText(brightness);
    final surface = NBColors.surfaceFill(brightness);
    final canvas = NBColors.canvas(brightness);

    final base = GoogleFonts.interTextTheme().apply(
      bodyColor: fg,
      displayColor: fg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: fg,
        onPrimary: isDark ? NBColors.black : NBColors.white,
        secondary: NBColors.movie,
        onSecondary: NBColors.black,
        surface: surface,
        onSurface: fg,
        onSurfaceVariant: muted,
        error: const Color(0xFFDC2626),
        onError: NBColors.white,
      ),
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 28,
          height: 1.15,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          height: 1.2,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          height: 1.25,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1.3,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          height: 1.45,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.45,
          color: muted,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.4,
          color: muted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: fg,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 64,
        indicatorColor: fg.withValues(alpha: isDark ? 0.15 : 0.08),
        labelTextStyle: WidgetStatePropertyAll(
          base.labelLarge?.copyWith(fontSize: 12),
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: fg, size: 22)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: fg,
        unselectedLabelColor: muted,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: NBColors.glassBorder(brightness),
        labelStyle: base.labelLarge,
        unselectedLabelStyle: base.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      dividerColor: NBColors.glassBorder(brightness).withValues(alpha: 0.35),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        titleTextStyle: base.titleMedium,
        subtitleTextStyle: base.bodyMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: base.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NBMetrics.radius),
          borderSide: BorderSide(color: NBColors.glassBorder(brightness), width: NBMetrics.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NBMetrics.radius),
          borderSide: BorderSide(color: NBColors.glassBorder(brightness), width: NBMetrics.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NBMetrics.radius),
          borderSide: BorderSide(color: fg, width: NBMetrics.borderWidth),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fg,
        foregroundColor: isDark ? NBColors.black : NBColors.white,
        elevation: 0,
        extendedTextStyle: base.labelLarge?.copyWith(
          color: isDark ? NBColors.black : NBColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NBMetrics.radius),
          side: BorderSide(color: NBColors.glassBorder(brightness), width: NBMetrics.borderWidth),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: fg,
        contentTextStyle: base.bodyMedium?.copyWith(
          color: isDark ? NBColors.black : NBColors.white,
        ),
      ),
    );
  }
}
