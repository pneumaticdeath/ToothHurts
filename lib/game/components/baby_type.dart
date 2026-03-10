/// Which type of baby the player is examining this level.
enum BabyType {
  human, // Classic baby, levels 1–4
  alligator, // Green snout, LOTS of sharp teeth, levels 5–8
  fish, // Round eyes, fins, weird teeth, levels 9+
}

extension BabyTypeDisplay on BabyType {
  String get emoji {
    switch (this) {
      case BabyType.human:
        return '👶';
      case BabyType.alligator:
        return '🐊';
      case BabyType.fish:
        return '🐟';
    }
  }

  String get label {
    switch (this) {
      case BabyType.human:
        return 'Baby';
      case BabyType.alligator:
        return 'Baby Gator';
      case BabyType.fish:
        return 'Baby Fish';
    }
  }

  /// Unlocked at this level (inclusive).
  static BabyType forLevel(int level) {
    if (level >= 9) return BabyType.fish;
    if (level >= 5) return BabyType.alligator;
    return BabyType.human;
  }
}
