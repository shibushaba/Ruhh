import 'dart:math' as math;

/// Lifetime XP to level. The only approved curve is [Phase1LevelCurve].
abstract class LevelCurve {
  const LevelCurve();

  /// XP required to be at [level]. Level 1 is 0.
  int threshold(int level);

  int levelFor(int lifetimeXp) {
    final xp = math.max(0, lifetimeXp);
    var level = 1;
    while (level < 100000 && threshold(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  int xpToNext(int lifetimeXp) {
    final level = levelFor(lifetimeXp);
    return math.max(0, threshold(level + 1) - math.max(0, lifetimeXp));
  }
}

/// `floor(50 * (level - 1) ^ 1.55)`. No daily cap.
class Phase1LevelCurve extends LevelCurve {
  const Phase1LevelCurve();

  @override
  int threshold(int level) {
    if (level <= 1) return 0;
    return (50 * math.pow(level - 1, 1.55)).floor();
  }
}

/// Test double. Production must not use this as the default.
class LinearLevelCurve extends LevelCurve {
  const LinearLevelCurve(this.step);
  final int step;

  @override
  int threshold(int level) {
    if (level <= 1) return 0;
    return step * (level - 1);
  }
}
