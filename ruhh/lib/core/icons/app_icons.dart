import 'package:flutter/widgets.dart';

/// Phosphor icon codepoints (Regular / Fill / Duotone) — fonts bundled in assets.
/// Matches phosphor_flutter 2.1.0; no dependency on the broken package on Flutter 3.38+.
abstract final class AppIcons {
  static IconData _regular(int cp) => IconData(
        cp,
        fontFamily: 'PhosphorRegular',
        matchTextDirection: true,
      );

  static IconData _fill(int cp) => IconData(
        cp,
        fontFamily: 'PhosphorFill',
        matchTextDirection: true,
      );

  static IconData _duotone(int cp) => IconData(
        cp,
        fontFamily: 'PhosphorDuotone',
        matchTextDirection: true,
      );

  static IconData home({bool filled = false}) =>
      filled ? _fill(0xe2c2) : _regular(0xe2c2);

  static IconData wallet({bool filled = false}) =>
      filled ? _fill(0xe68a) : _regular(0xe68a);

  static IconData habit({bool filled = false}) =>
      filled ? _fill(0xe184) : _regular(0xe184);

  static IconData prayer({bool filled = false}) =>
      filled ? _fill(0xe58e) : _regular(0xe58e);

  static IconData movie({bool filled = false}) =>
      filled ? _fill(0xe8c2) : _regular(0xe8c2);

  static IconData settings({bool filled = false}) =>
      filled ? _fill(0xe272) : _regular(0xe272);

  static IconData bell({bool filled = false}) =>
      filled ? _fill(0xe0ce) : _regular(0xe0ce);

  static IconData plus({bool filled = false}) =>
      filled ? _fill(0xe3d4) : _regular(0xe3d4);

  static IconData minus({bool filled = false}) =>
      filled ? _fill(0xe32a) : _regular(0xe32a);

  static IconData trendUp({bool filled = false}) =>
      filled ? _fill(0xe58c) : _regular(0xe58c);

  static IconData trendDown({bool filled = false}) =>
      filled ? _fill(0xe586) : _regular(0xe586);

  static IconData arrowDownLeft({bool filled = false}) =>
      filled ? _fill(0xe05c) : _regular(0xe05c);

  static IconData arrowUpRight({bool filled = false}) =>
      filled ? _fill(0xe068) : _regular(0xe068);

  static IconData calendarBlank({bool filled = false}) =>
      filled ? _fill(0xe100) : _regular(0xe100);

  static IconData caretRight({bool filled = false}) =>
      filled ? _fill(0xe13c) : _regular(0xe13c);

  static IconData caretLeft({bool filled = false}) =>
      filled ? _fill(0xe138) : _regular(0xe138);

  static IconData caretDown({bool filled = false}) =>
      filled ? _fill(0xe136) : _regular(0xe136);

  static IconData caretUp({bool filled = false}) =>
      filled ? _fill(0xe13a) : _regular(0xe13a);

  static IconData flame({bool filled = false}) =>
      filled ? _fill(0xe624) : _regular(0xe624);

  static IconData starFill({bool filled = true}) => _fill(0xe46a);

  static IconData star({bool filled = false}) =>
      filled ? _fill(0xe46a) : _regular(0xe46a);

  static IconData pencilSimple({bool filled = false}) =>
      filled ? _fill(0xe3b4) : _regular(0xe3b4);

  static IconData trash({bool filled = false}) =>
      filled ? _fill(0xe54a) : _regular(0xe54a);

  static IconData magnifyingGlass({bool filled = false}) =>
      filled ? _fill(0xe30c) : _regular(0xe30c);

  static IconData checkCircle({bool filled = false}) =>
      filled ? _fill(0xe184) : _regular(0xe184);

  static IconData xCircle({bool filled = false}) =>
      filled ? _fill(0xe578) : _regular(0xe578);

  static IconData slidersHorizontal({bool filled = false}) =>
      filled ? _fill(0xe466) : _regular(0xe466);

  static IconData notePencil({bool filled = false}) =>
      filled ? _fill(0xe363) : _regular(0xe363);

  static IconData moon({bool filled = false}) =>
      filled ? _fill(0xe378) : _regular(0xe378);

  static IconData bolt({bool filled = false}) =>
      filled ? _fill(0xe2fe) : _regular(0xe2fe);

  static IconData close({bool filled = false}) =>
      filled ? _fill(0xe574) : _regular(0xe574);

  static IconData person({bool filled = false}) =>
      filled ? _fill(0xe548) : _regular(0xe548);

  static IconData listBullets({bool filled = false}) =>
      filled ? _fill(0xe2f8) : _regular(0xe2f8);

  static IconData chartLine({bool filled = false}) =>
      filled ? _fill(0xe154) : _regular(0xe154);

  static IconData film({bool filled = false}) =>
      filled ? _fill(0xe240) : _regular(0xe240);

  static IconData check({bool filled = false}) =>
      filled ? _fill(0xe182) : _regular(0xe182);

  static IconData emptyHabitsDuotone() => _duotone(0xe184);

  static IconData emptyPrayerDuotone() => _duotone(0xe58e);

  static IconData emptyMovieDuotone() => _duotone(0xe8c2);

  static IconData emptyBudgetDuotone() => _duotone(0xe68a);
}
