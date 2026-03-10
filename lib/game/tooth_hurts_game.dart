import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';

import '../audio/audio_manager.dart';
import '../utils/constants.dart';
import '../utils/haptic_util.dart';
import 'components/baby_face_component.dart';
import 'components/bite_flash_component.dart';
import 'components/hud_component.dart';
import 'state/game_state.dart';
import 'systems/bite_system.dart';
import 'systems/score_system.dart';

export 'state/game_state.dart';

/// Root Flame game class.
///
/// Owns all subsystems and manages the round lifecycle.
/// Communicates with the Flutter UI via named overlays and callbacks.
class ToothHurtsGame extends FlameGame {
  // ── External callbacks ──────────────────────────────────────────────────
  final void Function(int finalScore, bool passed)? onRoundComplete;
  final void Function()? onGameOver;
  final void Function()? onMainMenu;

  // ── State ───────────────────────────────────────────────────────────────
  late final PlayerState playerState;
  late final LevelState levelState;

  final phaseNotifier = _PhaseNotifier(RoundPhase.spawning);

  // ── Logic systems ───────────────────────────────────────────────────────
  late BiteSystem biteSystem;
  late final ScoreSystem scoreSystem;
  late final AudioManager audioManager;

  // ── Component references ────────────────────────────────────────────────
  late BabyFaceComponent _babyFace;
  late HudComponent _hud;

  // ── Round tracking ──────────────────────────────────────────────────────
  int _countedTeeth = 0;
  double _roundTimer = 0.0;

  // ── Autonomous snap / random bite ────────────────────────────────────────
  final _random = Random();
  double _snapTimer = 0.0;
  double _nextSnapDelay = 5.0;

  // ── Safe-area passthrough from Flutter ──────────────────────────────────
  double topInset = 0.0;

  // ── Constructor ─────────────────────────────────────────────────────────

  ToothHurtsGame({
    this.onRoundComplete,
    this.onGameOver,
    this.onMainMenu,
  }) {
    playerState = PlayerState();
    levelState = LevelState();
    scoreSystem = ScoreSystem();
    audioManager = AudioManager();
    biteSystem = BiteSystem(
      biteThreshold: levelState.difficulty.biteThresholdSeconds,
    );
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Fix the camera to a known design resolution so layout is consistent
    // across all device sizes. Must be done after super.onLoad() so that
    // camera is already connected to the world.
    camera.viewfinder.visibleGameSize = Vector2(kDesignWidth, kDesignHeight);
    camera.viewfinder.position = Vector2(kDesignWidth / 2, kDesignHeight / 2);
    camera.viewfinder.anchor = Anchor.center;

    // Preload audio in background (game works silently without audio files)
    audioManager.preloadAll();

    // Background gradient
    await world.add(_BackgroundComponent());

    // Baby face (contains MouthComponent → teeth + tongue)
    _babyFace = BabyFaceComponent();
    await world.add(_babyFace);

    // HUD in screen space (camera.viewport)
    _hud = HudComponent();
    await camera.viewport.add(_hud);

    _beginRound();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final phase = phaseNotifier.value;
    if (phase != RoundPhase.counting && phase != RoundPhase.tongueActive) {
      return;
    }

    _roundTimer += dt;

    // Update hold-duration bites
    final biters = biteSystem.update(dt);
    if (biters.isNotEmpty) {
      _handleBite();
      return;
    }

    // Autonomous random snap
    _snapTimer += dt;
    if (_snapTimer >= _nextSnapDelay) {
      _snapTimer = 0;
      _scheduleNextSnap();
      _handleSnap();
    }
  }

  // ── Round management ─────────────────────────────────────────────────────

  void _beginRound() {
    _countedTeeth = 0;
    _roundTimer = 0.0;
    _snapTimer = 0.0;
    _scheduleNextSnap();
    biteSystem.cancelAll();
    biteSystem.updateThreshold(levelState.difficulty.biteThresholdSeconds);

    _babyFace.resetPosition();
    _babyFace.spawnTeeth(levelState.difficulty).then((_) {
      phaseNotifier.value = RoundPhase.counting;
    });
  }

  void _scheduleNextSnap() {
    final diff = levelState.difficulty;
    _nextSnapDelay = diff.snapMinDelay +
        _random.nextDouble() * (diff.snapMaxDelay - diff.snapMinDelay);
  }

  /// Baby randomly snaps: bite if player has a tooth held down, else warning shake.
  void _handleSnap() {
    if (phaseNotifier.value == RoundPhase.biting) return;
    if (biteSystem.hasActiveHolds) {
      _handleBite();
    } else {
      // Near-miss warning: quick shake without penalty
      _babyFace.add(
        MoveEffect.by(
          Vector2(8, 0),
          EffectController(
            duration: 0.05,
            reverseDuration: 0.05,
            repeatCount: 2,
          ),
        ),
      );
    }
  }

  /// Called by ToothComponent when a counted tooth is re-tapped — lose all progress.
  void onCountReset() {
    if (phaseNotifier.value != RoundPhase.counting &&
        phaseNotifier.value != RoundPhase.tongueActive) return;
    _countedTeeth = 0;
    _babyFace.mouth.resetAllTeeth();
    HapticUtil.countTick();
  }

  /// Called by ToothComponent when a tooth is successfully tapped.
  void onToothCounted(int toothIndex) {
    if (phaseNotifier.value != RoundPhase.counting &&
        phaseNotifier.value != RoundPhase.tongueActive) {
      return;
    }
    _countedTeeth++;
    audioManager.playCountTick();

    final totalTeeth = levelState.difficulty.toothCount;
    if (_countedTeeth >= totalTeeth) {
      _completeRound();
    }
  }

  void _completeRound() {
    phaseNotifier.value = RoundPhase.submitting;
    biteSystem.cancelAll();

    final roundScore = scoreSystem.calculateRoundScore(
      teethCounted: _countedTeeth,
      totalTeeth: levelState.difficulty.toothCount,
      elapsedSeconds: _roundTimer,
      livesRemaining: playerState.lives,
    );
    playerState.addScore(roundScore);

    final passed = scoreSystem.isPassing(roundScore);
    audioManager.playLevelClear();
    phaseNotifier.value = RoundPhase.resultShown;
    overlays.add(kResultOverlay);
    onRoundComplete?.call(roundScore, passed);
  }

  void _handleBite() {
    if (phaseNotifier.value == RoundPhase.biting) return;
    phaseNotifier.value = RoundPhase.biting;
    biteSystem.cancelAll();

    playerState.loseLife();
    HapticUtil.bite();
    audioManager.playBite();

    // Flash the screen red
    camera.viewport.add(BiteFlashComponent());

    // Shake the baby face
    _babyFace.add(
      MoveEffect.by(
        Vector2(12, 0),
        EffectController(
          duration: 0.06,
          reverseDuration: 0.06,
          repeatCount: 3,
          atMaxDuration: 0.0,
        ),
      ),
    );

    if (playerState.isDead) {
      Future.delayed(const Duration(milliseconds: 700), _triggerGameOver);
    } else {
      // Resume counting after brief pause
      Future.delayed(
        const Duration(milliseconds: 600),
        () => phaseNotifier.value = RoundPhase.counting,
      );
    }
  }

  void _triggerGameOver() {
    phaseNotifier.value = RoundPhase.resultShown;
    audioManager.playGameOver();
    overlays.add(kGameOverOverlay);
    onGameOver?.call();
  }

  // ── Called from overlay buttons ───────────────────────────────────────────

  void advanceLevel() {
    overlays.remove(kResultOverlay);
    levelState.advance();
    biteSystem.updateThreshold(levelState.difficulty.biteThresholdSeconds);
    _beginRound();
  }

  void restartGame() {
    overlays.remove(kGameOverOverlay);
    overlays.remove(kResultOverlay);
    playerState.resetForNewGame();
    levelState.reset();
    biteSystem.updateThreshold(levelState.difficulty.biteThresholdSeconds);
    _beginRound();
  }

  void pauseGame() {
    pauseEngine();
    overlays.add(kPauseOverlay);
  }

  void resumeGame() {
    overlays.remove(kPauseOverlay);
    resumeEngine();
  }
}

// ── Phase notifier (simple observable) ────────────────────────────────────────

class _PhaseNotifier {
  RoundPhase _value;

  _PhaseNotifier(this._value);

  RoundPhase get value => _value;

  set value(RoundPhase newValue) {
    _value = newValue;
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _BackgroundComponent extends PositionComponent {
  _BackgroundComponent()
      : super(
          position: Vector2.zero(),
          size: Vector2(kDesignWidth, kDesignHeight),
          priority: -1,
        );

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, 0),
          Offset(0, size.y),
          [kBackgroundTop, kBackgroundBottom],
        ),
    );

    // Decorative clouds
    _drawCloud(canvas, 60, 80, 1.0);
    _drawCloud(canvas, 260, 55, 0.8);
    _drawCloud(canvas, 340, 100, 0.65);

    // Decorative stars/sparkles
    _drawSparkles(canvas);
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double scale) {
    final paint = Paint()..color = const Color(0xCCFFFFFF);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 70, height: 36), paint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-22, -14), width: 42, height: 32), paint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(16, -16), width: 36, height: 28), paint);
    canvas.restore();
  }

  void _drawSparkles(Canvas canvas) {
    final sparkPaint = Paint()..color = const Color(0x99FFE066);
    const sparkles = [
      [50.0, 700.0],
      [320.0, 720.0],
      [180.0, 760.0],
      [80.0, 790.0],
      [340.0, 780.0],
    ];
    for (final s in sparkles) {
      canvas.drawCircle(Offset(s[0], s[1]), 3, sparkPaint);
    }
  }
}
