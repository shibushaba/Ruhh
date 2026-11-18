import 'package:ruhh/features/v14/logic/level_curve.dart';

class WorldBand {
  const WorldBand(this.world, this.startLevel, this.endLevel);
  final int world;
  final int startLevel;
  final int endLevel;
}

/// Presentation map only. It does not define the XP curve.
const v14WorldBands = <WorldBand>[
  WorldBand(1, 1, 24),
  WorldBand(2, 25, 44),
  WorldBand(3, 45, 64),
  WorldBand(4, 65, 84),
  WorldBand(5, 85, 100),
];

class WorldProgress {
  const WorldProgress({
    required this.level,
    required this.world,
    required this.subStage,
    required this.lifetimeXp,
    required this.xpToNext,
  });

  final int level;
  final int world;
  final int subStage;
  final int lifetimeXp;
  final int xpToNext;
}

class WorldMap {
  const WorldMap({
    this.curve = const Phase1LevelCurve(),
    this.bands = v14WorldBands,
  });

  final LevelCurve curve;
  final List<WorldBand> bands;

  WorldProgress progress(int lifetimeXp) {
    final xp = lifetimeXp < 0 ? 0 : lifetimeXp;
    final level = curve.levelFor(xp);
    final band = _band(level);
    return WorldProgress(
      level: level,
      world: band.world,
      subStage: _subStage(level, band),
      lifetimeXp: xp,
      xpToNext: curve.xpToNext(xp),
    );
  }

  WorldBand _band(int level) {
    for (final band in bands) {
      if (level <= band.endLevel) return band;
    }
    return bands.last;
  }

  /// Four quarters of the world's level span. 0 is the earliest form.
  int _subStage(int level, WorldBand band) {
    final span = band.endLevel - band.startLevel + 1;
    final offset = (level - band.startLevel).clamp(0, span - 1);
    final index = (offset * 4) ~/ span;
    if (index < 0) return 0;
    if (index > 3) return 3;
    return index;
  }
}
