import '../game/components/baby_type.dart';

/// All per-level tuning lives here. Tweak freely for game feel.
class DifficultyConfig {
  final int level;

  const DifficultyConfig({required this.level});

  // ── Baby type ──────────────────────────────────────────────────────────────
  BabyType get babyType => BabyTypeDisplay.forLevel(level);

  // ── Teeth ──────────────────────────────────────────────────────────────────
  /// Total number of teeth to count this level.
  int get toothCount {
    switch (babyType) {
      case BabyType.alligator:
        // Alligators have ~80 teeth — lots more to count!
        return (8 + (level - 5) * 4).clamp(8, 24);
      case BabyType.fish:
        return (4 + (level - 9) * 3).clamp(4, 18);
      case BabyType.human:
        return (2 + level * 2).clamp(2, 10);
    }
  }

  /// Whether teeth appear on both top and bottom of the mouth.
  bool get hasTwoRows {
    switch (babyType) {
      case BabyType.alligator:
        return true; // always two rows
      case BabyType.fish:
        return level >= 11;
      case BabyType.human:
        return level >= 3;
    }
  }

  int get bottomTeethCount => hasTwoRows ? (toothCount + 1) ~/ 2 : toothCount;
  int get topTeethCount => hasTwoRows ? toothCount ~/ 2 : 0;

  // ── Bite mechanic ──────────────────────────────────────────────────────────
  /// Seconds the player can hold a tooth before it bites back.
  double get biteThresholdSeconds => (1.0 - level * 0.04).clamp(0.35, 1.0);

  /// Random autonomous snap: fires every [snapMinDelay]..[snapMaxDelay] seconds.
  /// If the player has any tooth held at that moment, they get bitten.
  double get snapMinDelay => (5.0 - level * 0.2).clamp(2.0, 5.0);
  double get snapMaxDelay => snapMinDelay + 2.5;

  // ── Tongue ─────────────────────────────────────────────────────────────────
  double get tongueMinDelay => (7.0 - level * 0.4).clamp(3.0, 7.0);
  double get tongueMaxDelay => tongueMinDelay + 3.5;
  double get tongueHoldDuration => (2.0 - level * 0.05).clamp(1.0, 2.0);
  double get tongueSlideInDuration => 0.38;
  double get tongueSlideOutDuration => 0.48;

  // ── Squirm ─────────────────────────────────────────────────────────────────
  double get squirmMinDelay => (6.0 - level * 0.25).clamp(2.0, 6.0);
  double get squirmMaxDelay => squirmMinDelay + 3.0;
  double get squirmDuration => (0.33 + level * 0.025).clamp(0.33, 0.75);
  double get squirmMaxOffset => (18.0 + level * 3.0).clamp(18.0, 48.0);
  double get squirmMaxAngle => (0.12 + level * 0.018).clamp(0.12, 0.4);

  // ── Throw-up ───────────────────────────────────────────────────────────────
  /// Whether the throw-up complication is active this level.
  bool get hasThrowUp => level >= 2;

  // ── Pacifier ───────────────────────────────────────────────────────────────
  bool get hasPacifier => level >= 3;

  // ── Foot ───────────────────────────────────────────────────────────────────
  bool get hasFoot => level >= 4;

  // ── Helpers ────────────────────────────────────────────────────────────────
  @override
  String toString() =>
      '${babyType.label} Lv$level | ${toothCount}t '
      '| bite=${biteThresholdSeconds.toStringAsFixed(2)}s';
}
