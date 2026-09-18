import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

class RuhhTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? NBColors.darkBg : NBColors.offWhite;
    final fg = isDark ? NBColors.offWhite : NBColors.black;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: NBColors.prayer,
        onPrimary: NBColors.black,
        secondary: NBColors.habit,
        onSecondary: NBColors.black,
        error: const Color(0xFFEF4444),
        onError: NBColors.offWhite,
        surface: bg,
        onSurface: fg,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w800,
          fontSize: 32,
          color: fg,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: fg,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: fg,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: fg,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: fg,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: fg,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: fg,
        ),
      ),
      dividerColor: NBColors.black,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NBMetrics.radius),
          borderSide: const BorderSide(
            color: NBColors.black,
            width: NBMetrics.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NBMetrics.radius),
          borderSide: const BorderSide(
            color: NBColors.black,
            width: NBMetrics.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NBMetrics.radius),
          borderSide: const BorderSide(
            color: NBColors.black,
            width: NBMetrics.borderWidth,
          ),
        ),
      ),
    );
  }
}
