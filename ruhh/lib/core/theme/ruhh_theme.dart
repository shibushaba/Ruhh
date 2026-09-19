import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ruhh/core/theme/portfolio_palette.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/theme/ruhh_scroll_behavior.dart';

class RuhhTheme {
  static ThemeData light() => _base(RuhhTokens.light, Brightness.light);
  static ThemeData dark() => _base(RuhhTokens.dark, Brightness.dark);

  static ThemeData _base(RuhhTokens t, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final dmSans = GoogleFonts.dmSansTextTheme();
    final base = dmSans.apply(
      bodyColor: t.textPrimary,
      displayColor: t.textPrimary,
    );
    final buttonFont = GoogleFonts.outfit();

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: PortfolioPalette.foreground,
            onPrimary: PortfolioPalette.background,
            secondary: t.surfaceSecondary,
            onSecondary: t.textPrimary,
            surface: t.surfacePrimary,
            onSurface: t.textPrimary,
            onSurfaceVariant: t.textSecondary,
            error: const Color(0xFFEF4444),
            onError: PortfolioPalette.foreground,
            outline: PortfolioPalette.border,
          )
        : ColorScheme.light(
            primary: PortfolioPalette.inkLight,
            onPrimary: PortfolioPalette.foreground,
            secondary: t.surfaceSecondary,
            onSecondary: t.textPrimary,
            surface: t.surfacePrimary,
            onSurface: t.textPrimary,
            onSurfaceVariant: t.textSecondary,
            error: const Color(0xFFDC2626),
            onError: PortfolioPalette.foreground,
            outline: PortfolioPalette.border,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      extensions: [t],
      colorScheme: colorScheme,
      textTheme: base.copyWith(
        displayLarge: t.screenTitle(base),
        headlineMedium: t.statLarge(base),
        titleLarge: t.cardTitle(base),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: t.textPrimary,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 22 / 15,
          color: t.textPrimary,
        ),
        bodyMedium: t.caption(base),
        bodySmall: t.micro(base),
        labelLarge: buttonFont.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: t.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: t.spaceScreenHorizontal,
        toolbarHeight: 56,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: t.textPrimary,
        ),
      ),
      dividerColor: t.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceSecondary.withValues(alpha: isDark ? 0.9 : 1),
        hintStyle: t.caption(base),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusInput),
          borderSide: BorderSide(color: PortfolioPalette.borderHighlight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusInput),
          borderSide: BorderSide(color: PortfolioPalette.borderHighlight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusInput),
          borderSide: BorderSide(color: t.textPrimary, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? PortfolioPalette.foreground : t.textPrimary,
        foregroundColor: isDark ? PortfolioPalette.background : t.surfacePrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.surfacePrimary,
        contentTextStyle: base.bodyMedium?.copyWith(color: t.textPrimary),
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusInput),
          side: BorderSide(color: PortfolioPalette.borderHighlight),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? PortfolioPalette.background : t.surfacePrimary;
          }
          return t.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PortfolioPalette.foreground;
          }
          return t.divider;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.textPrimary,
        textColor: t.textPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor:
            isDark ? PortfolioPalette.foreground : PortfolioPalette.inkLight,
        disabledColor: t.textTertiary.withValues(alpha: 0.4),
        showCheckmark: false,
        side: BorderSide(color: PortfolioPalette.borderHighlight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusChip),
        ),
        labelStyle: buttonFont.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: t.textPrimary,
        ),
        secondaryLabelStyle: buttonFont.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: isDark
              ? PortfolioPalette.background
              : PortfolioPalette.paperLight,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark
                  ? PortfolioPalette.background
                  : PortfolioPalette.paperLight;
            }
            if (states.contains(WidgetState.disabled)) {
              return t.textTertiary;
            }
            return t.textPrimary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark
                  ? PortfolioPalette.foreground
                  : PortfolioPalette.inkLight;
            }
            return Colors.transparent;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: PortfolioPalette.borderHighlight),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.radiusChip),
            ),
          ),
        ),
      ),
      scrollbarTheme: kRuhhScrollbarTheme,
    );
  }
}
