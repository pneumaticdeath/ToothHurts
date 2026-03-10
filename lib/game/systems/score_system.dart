/// Pure scoring logic — no state, no Flame dependency.
class ScoreSystem {
  /// Calculate points earned for completing a round.
  ///
  /// [teethCounted]    how many teeth the player successfully tapped
  /// [totalTeeth]      how many teeth existed this round
  /// [elapsedSeconds]  how long the round took
  /// [livesRemaining]  lives left after the round
  int calculateRoundScore({
    required int teethCounted,
    required int totalTeeth,
    required double elapsedSeconds,
    required int livesRemaining,
  }) {
    if (totalTeeth == 0) return 0;

    // Accuracy: 0–100 points based on fraction of teeth found.
    final accuracy = (teethCounted / totalTeeth).clamp(0.0, 1.0);
    final accuracyScore = (accuracy * 100).round();

    // Speed bonus: up to 50 extra points, decays over 45 seconds.
    final speedBonus =
        ((1.0 - (elapsedSeconds / 45.0)).clamp(0.0, 1.0) * 50).round();

    // Life bonus: 10 per remaining life.
    final lifeBonus = livesRemaining * 10;

    return accuracyScore + speedBonus + lifeBonus;
  }

  /// Minimum score to pass (advance to next level): 50 points.
  static const int passingScore = 50;

  bool isPassing(int score) => score >= passingScore;
}
