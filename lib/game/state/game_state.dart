import '../../config/difficulty_config.dart';

/// Phase of the active round (lives inside the Flame game).
enum RoundPhase {
  spawning, // Components loading; no input yet
  counting, // Normal gameplay: tap teeth
  tongueActive, // Tongue is blocking; taps on it are consumed
  biting, // Bite animation playing; input temporarily blocked
  submitting, // All teeth counted; calculating score
  resultShown, // Score overlay visible
}

class PlayerState {
  int lives;
  int score;
  int totalScore;
  int highScore;

  PlayerState({
    this.lives = 3,
    this.score = 0,
    this.totalScore = 0,
    this.highScore = 0,
  });

  bool get isDead => lives <= 0;

  void loseLife() {
    if (lives > 0) lives--;
  }

  void addScore(int points) {
    score += points;
    totalScore += points;
    if (totalScore > highScore) highScore = totalScore;
  }

  void resetForNewGame() {
    lives = 3;
    score = 0;
    totalScore = 0;
  }
}

class LevelState {
  int level;
  late DifficultyConfig difficulty;

  LevelState({this.level = 1}) {
    difficulty = DifficultyConfig(level: level);
  }

  void advance() {
    level++;
    difficulty = DifficultyConfig(level: level);
  }

  void reset() {
    level = 1;
    difficulty = DifficultyConfig(level: 1);
  }
}
