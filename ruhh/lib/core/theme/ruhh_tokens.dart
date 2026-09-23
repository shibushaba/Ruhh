import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/portfolio_palette.dart';

/// Design tokens — portfolio (shabas.vercel.app) + module accents.
@immutable
class RuhhTokens extends ThemeExtension<RuhhTokens> {
  const RuhhTokens({
    required this.canvas,
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.accentMint,
    required this.accentMintPastel,
    required this.accentCoral,
    required this.accentCoralPastel,
    required this.accentAmber,
    required this.accentAmberPastel,
    required this.accentSky,
    required this.accentSkyPastel,
    required this.accentLavender,
    required this.accentLavenderPastel,
    required this.accentPeach,
    required this.accentPeachPastel,
    required this.accentSlate,
    required this.accentSlatePastel,
    required this.radiusCardLarge,
    required this.radiusCardMedium,
    required this.radiusButton,
    required this.radiusChip,
    required this.radiusInput,
    required this.radiusNavBar,
    required this.radiusNavActive,
    required this.spaceScreenHorizontal,
    required this.spaceStackGap,
    required this.spaceGridGap,
    required this.spaceCardPadding,
    required this.spaceCardPaddingCompact,
    required this.shadowCard,
    required this.shadowNav,
    required this.shadowPrimaryButton,
  });

  final Color canvas;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;

  final Color accentMint;
  final Color accentMintPastel;
  final Color accentCoral;
  final Color accentCoralPastel;
  final Color accentAmber;
  final Color accentAmberPastel;
  final Color accentSky;
  final Color accentSkyPastel;
  final Color accentLavender;
  final Color accentLavenderPastel;
  final Color accentPeach;
  final Color accentPeachPastel;
  final Color accentSlate;
  final Color accentSlatePastel;

  final double radiusCardLarge;
  final double radiusCardMedium;
  final double radiusButton;
  final double radiusChip;
  final double radiusInput;
  final double radiusNavBar;
  final double radiusNavActive;

  final double spaceScreenHorizontal;
  final double spaceStackGap;
  final double spaceGridGap;
  final double spaceCardPadding;
  final double spaceCardPaddingCompact;

  final List<BoxShadow> shadowCard;
  final List<BoxShadow> shadowNav;
  final List<BoxShadow> shadowPrimaryButton;

  static const light = RuhhTokens(
    canvas: PortfolioPalette.deskLight,
    surfacePrimary: PortfolioPalette.paperLight,
    surfaceSecondary: Color(0xFFF0F0F0),
    textPrimary: PortfolioPalette.inkLight,
    textSecondary: Color(0xFF5C5C5C),
    textTertiary: Color(0xFF949494),
    divider: Color(0xFF383838),
    accentMint: Color(0xFF059669),
    accentMintPastel: Color(0xFFE8F5EE),
    accentCoral: Color(0xFFE11D48),
    accentCoralPastel: Color(0xFFFFE4E6),
    accentAmber: Color(0xFFD97706),
    accentAmberPastel: Color(0xFFFEF3C7),
    accentSky: Color(0xFF0284C7),
    accentSkyPastel: Color(0xFFE0F2FE),
    accentLavender: Color(0xFF7C3AED),
    accentLavenderPastel: Color(0xFFEDE9FE),
    accentPeach: Color(0xFFEA580C),
    accentPeachPastel: Color(0xFFFFEDD5),
    accentSlate: Color(0xFF64748B),
    accentSlatePastel: Color(0xFFF1F5F9),
    radiusCardLarge: PortfolioPalette.radiusSm,
    radiusCardMedium: PortfolioPalette.radiusSm,
    radiusButton: 0,
    radiusChip: 0,
    radiusInput: PortfolioPalette.radiusMd,
    radiusNavBar: 0,
    radiusNavActive: 0,
    spaceScreenHorizontal: 20,
    spaceStackGap: 16,
    spaceGridGap: 12,
    spaceCardPadding: 16,
    spaceCardPaddingCompact: 12,
    shadowCard: [PortfolioPalette.shadowPaper],
    shadowNav: [PortfolioPalette.shadowSticker],
    shadowPrimaryButton: [PortfolioPalette.shadowSticker],
  );

  /// Portfolio dark — desk grid, paper cards, high-contrast ink (shabas.vercel.app).
  static const dark = RuhhTokens(
    canvas: PortfolioPalette.deskDark,
    surfacePrimary: PortfolioPalette.card,
    surfaceSecondary: PortfolioPalette.secondary,
    textPrimary: PortfolioPalette.foreground,
    textSecondary: PortfolioPalette.mutedForeground,
    textTertiary: Color(0xFF6B6B6B),
    divider: PortfolioPalette.border,
    accentMint: Color(0xFF4ADE80),
    accentMintPastel: Color(0xFF1A2E22),
    accentCoral: Color(0xFFFB7185),
    accentCoralPastel: Color(0xFF2A1518),
    accentAmber: Color(0xFFFBBF24),
    accentAmberPastel: Color(0xFF2A2410),
    accentSky: Color(0xFF38BDF8),
    accentSkyPastel: Color(0xFF102A38),
    accentLavender: Color(0xFFA78BFA),
    accentLavenderPastel: Color(0xFF221A38),
    accentPeach: Color(0xFFFB923C),
    accentPeachPastel: Color(0xFF2A1A10),
    accentSlate: Color(0xFF94A3B8),
    accentSlatePastel: Color(0xFF1A1E24),
    radiusCardLarge: PortfolioPalette.radiusSm,
    radiusCardMedium: PortfolioPalette.radiusSm,
    radiusButton: 0,
    radiusChip: 0,
    radiusInput: PortfolioPalette.radiusMd,
    radiusNavBar: 0,
    radiusNavActive: 0,
    spaceScreenHorizontal: 20,
    spaceStackGap: 16,
    spaceGridGap: 12,
    spaceCardPadding: 16,
    spaceCardPaddingCompact: 12,
    shadowCard: [PortfolioPalette.shadowPaper],
    shadowNav: [PortfolioPalette.shadowSticker],
    shadowPrimaryButton: [PortfolioPalette.shadowSticker],
  );

  /// Grayscale only — vector category differentiation.
  static final categoryAccents = [
    const Color(0xFF000000),
    const Color(0xFF333333),
    const Color(0xFF555555),
    const Color(0xFF777777),
    const Color(0xFF999999),
  ];

  /// Material [shadowColor] when [shadowCard] is empty (vector theme).
  Color get elevationShadowColor =>
      shadowCard.isNotEmpty
          ? shadowCard.first.color
          : const Color(0x40000000);

  Color pastelForAccent(Color accent) {
    if (accent == accentMint) return accentMintPastel;
    if (accent == accentCoral) return accentCoralPastel;
    if (accent == accentAmber) return accentAmberPastel;
    if (accent == accentSky) return accentSkyPastel;
    if (accent == accentLavender) return accentLavenderPastel;
    if (accent == accentPeach) return accentPeachPastel;
    if (accent == accentSlate) return accentSlatePastel;
    return accentSlatePastel;
  }

  Color categoryAccentAt(int index) =>
      categoryAccents[index % categoryAccents.length];

  TextStyle screenTitle(TextTheme base) => base.titleLarge!.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        height: 38 / 32,
        color: textPrimary,
      );

  TextStyle cardTitle(TextTheme base) => base.titleLarge!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 24 / 18,
        color: textPrimary,
      );

  TextStyle statHero(TextTheme base) => base.headlineMedium!.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 38 / 32,
        color: textPrimary,
      );

  TextStyle statLarge(TextTheme base) => base.titleLarge!.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 32 / 26,
        color: textPrimary,
      );

  TextStyle statMedium(TextTheme base) => base.titleMedium!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 26 / 20,
        color: textPrimary,
      );

  TextStyle caption(TextTheme base) => base.bodySmall!.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: textSecondary,
      );

  TextStyle micro(TextTheme base) => base.labelSmall!.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 14 / 11,
        color: textSecondary,
      );

  BoxDecoration cardDecoration({double? radius, Color? color}) =>
      BoxDecoration(
        color: color ?? surfacePrimary,
        borderRadius: BorderRadius.circular(radius ?? radiusCardLarge),
        border: Border.all(color: PortfolioPalette.borderHighlight, width: 1),
        boxShadow: shadowCard,
      );

  @override
  RuhhTokens copyWith({
    Color? canvas,
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? accentMint,
    Color? accentMintPastel,
    Color? accentCoral,
    Color? accentCoralPastel,
    Color? accentAmber,
    Color? accentAmberPastel,
    Color? accentSky,
    Color? accentSkyPastel,
    Color? accentLavender,
    Color? accentLavenderPastel,
    Color? accentPeach,
    Color? accentPeachPastel,
    Color? accentSlate,
    Color? accentSlatePastel,
    double? radiusCardLarge,
    double? radiusCardMedium,
    double? radiusButton,
    double? radiusChip,
    double? radiusInput,
    double? radiusNavBar,
    double? radiusNavActive,
    double? spaceScreenHorizontal,
    double? spaceStackGap,
    double? spaceGridGap,
    double? spaceCardPadding,
    double? spaceCardPaddingCompact,
    List<BoxShadow>? shadowCard,
    List<BoxShadow>? shadowNav,
    List<BoxShadow>? shadowPrimaryButton,
  }) {
    return RuhhTokens(
      canvas: canvas ?? this.canvas,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      accentMint: accentMint ?? this.accentMint,
      accentMintPastel: accentMintPastel ?? this.accentMintPastel,
      accentCoral: accentCoral ?? this.accentCoral,
      accentCoralPastel: accentCoralPastel ?? this.accentCoralPastel,
      accentAmber: accentAmber ?? this.accentAmber,
      accentAmberPastel: accentAmberPastel ?? this.accentAmberPastel,
      accentSky: accentSky ?? this.accentSky,
      accentSkyPastel: accentSkyPastel ?? this.accentSkyPastel,
      accentLavender: accentLavender ?? this.accentLavender,
      accentLavenderPastel: accentLavenderPastel ?? this.accentLavenderPastel,
      accentPeach: accentPeach ?? this.accentPeach,
      accentPeachPastel: accentPeachPastel ?? this.accentPeachPastel,
      accentSlate: accentSlate ?? this.accentSlate,
      accentSlatePastel: accentSlatePastel ?? this.accentSlatePastel,
      radiusCardLarge: radiusCardLarge ?? this.radiusCardLarge,
      radiusCardMedium: radiusCardMedium ?? this.radiusCardMedium,
      radiusButton: radiusButton ?? this.radiusButton,
      radiusChip: radiusChip ?? this.radiusChip,
      radiusInput: radiusInput ?? this.radiusInput,
      radiusNavBar: radiusNavBar ?? this.radiusNavBar,
      radiusNavActive: radiusNavActive ?? this.radiusNavActive,
      spaceScreenHorizontal: spaceScreenHorizontal ?? this.spaceScreenHorizontal,
      spaceStackGap: spaceStackGap ?? this.spaceStackGap,
      spaceGridGap: spaceGridGap ?? this.spaceGridGap,
      spaceCardPadding: spaceCardPadding ?? this.spaceCardPadding,
      spaceCardPaddingCompact:
          spaceCardPaddingCompact ?? this.spaceCardPaddingCompact,
      shadowCard: shadowCard ?? this.shadowCard,
      shadowNav: shadowNav ?? this.shadowNav,
      shadowPrimaryButton: shadowPrimaryButton ?? this.shadowPrimaryButton,
    );
  }

  @override
  RuhhTokens lerp(ThemeExtension<RuhhTokens>? other, double t) {
    if (other is! RuhhTokens) return this;
    return other;
  }
}

extension RuhhTokensContext on BuildContext {
  RuhhTokens get ruhh => Theme.of(this).extension<RuhhTokens>()!;
}

/// Floating nav pill + bottom margin (matches [RuhhFloatingNav] layout).
/// 16 bottom margin + 8 pad + ~48 icons + 8 pad ≈ 80; use 88 for breathing room.
const kRuhhFloatingNavBlockHeight = 88.0;

/// Module FAB width + trailing margin so scroll content stays left of the + button.
const kRuhhModuleFabEndInset = 72.0;

/// Bottom inset so content clears the floating global nav.
double ruhhGlobalNavBottomInset(BuildContext context) {
  final safe = MediaQuery.paddingOf(context).bottom;
  return safe + kRuhhFloatingNavBlockHeight + 16;
}

/// Module tab bodies inside [HomeShell] (nav overlays content).
double ruhhModuleShellBottomInset(
  BuildContext context, {
  bool hasFab = false,
}) {
  var inset = ruhhGlobalNavBottomInset(context);
  if (hasFab) {
    // FAB (~56) + gap above floating nav; must clear last list row under + button.
    inset += 88;
  }
  return inset;
}

/// Scroll padding at the bottom of lists (floating nav ± module FAB).
/// Prefer [RuhhShellScrollInsets] from [NBModuleScaffold] when inside a module tab.
double ruhhScrollBottomInset(
  BuildContext context, {
  double? shellInset,
}) {
  if (shellInset != null) return shellInset;
  return ruhhGlobalNavBottomInset(context);
}

/// Distance from screen bottom to the FAB's bottom edge (above nav).
double ruhhFabBottomClearance(double safeAreaBottom) {
  return safeAreaBottom + kRuhhFloatingNavBlockHeight + 16;
}
