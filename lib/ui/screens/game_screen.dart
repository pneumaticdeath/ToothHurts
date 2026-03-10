import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/components/baby_type.dart';
import '../../game/tooth_hurts_game.dart';
import '../../utils/constants.dart';
import 'main_menu_screen.dart';

/// Host widget for the Flame game. Supplies overlay builders for
/// pause, result, and game-over screens.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final ToothHurtsGame _game;

  @override
  void initState() {
    super.initState();
    // Lock to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _game = ToothHurtsGame(
      onMainMenu: _goToMainMenu,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pass safe-area top inset so HUD clears the notch/Dynamic Island
    _game.topInset = MediaQuery.of(context).viewPadding.top;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _goToMainMenu() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget<ToothHurtsGame>(
        game: _game,
        errorBuilder: (context, error) => Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Game error:\n$error',
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        overlayBuilderMap: {
          kPauseOverlay: (context, game) => _PauseOverlay(game: game),
          kResultOverlay: (context, game) => _ResultOverlay(game: game),
          kGameOverOverlay: (context, game) =>
              _GameOverOverlay(game: game, onMainMenu: _goToMainMenu),
        },
      ),
    );
  }
}

// ── Pause Overlay ─────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final ToothHurtsGame game;
  const _PauseOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return _OverlayScaffold(
      children: [
        const Text('⏸ PAUSED',
            style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 32),
        _OverlayButton(
          label: '▶ Resume',
          color: const Color(0xFF44BB66),
          onTap: game.resumeGame,
        ),
        const SizedBox(height: 16),
        _OverlayButton(
          label: '🏠 Main Menu',
          color: const Color(0xFF5588DD),
          onTap: () {
            game.resumeGame();
            game.onMainMenu?.call();
          },
        ),
      ],
    );
  }
}

// ── Result Overlay ────────────────────────────────────────────────────────────

class _ResultOverlay extends StatelessWidget {
  final ToothHurtsGame game;
  const _ResultOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    final score = game.playerState.score;
    final level = game.levelState.level;
    final diff = game.levelState.difficulty;
    final teeth = diff.toothCount;
    final babyLabel = diff.babyType.label;

    return _OverlayScaffold(
      children: [
        const Text('🦷 Round Clear!',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 12),
        Text(
          '$babyLabel  •  Lv $level  •  $teeth teeth',
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 24),
        _ScoreDisplay(score: score),
        const SizedBox(height: 28),
        _OverlayButton(
          label: '➡ Next Level',
          color: const Color(0xFFFF6B8A),
          onTap: game.advanceLevel,
        ),
        const SizedBox(height: 14),
        _OverlayButton(
          label: '🏠 Main Menu',
          color: const Color(0xFF5588DD),
          onTap: game.onMainMenu ?? () {},
        ),
      ],
    );
  }
}

// ── Game Over Overlay ─────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final ToothHurtsGame game;
  final VoidCallback onMainMenu;
  const _GameOverOverlay({required this.game, required this.onMainMenu});

  @override
  Widget build(BuildContext context) {
    final total = game.playerState.totalScore;
    final best = game.playerState.highScore;

    return _OverlayScaffold(
      backgroundColor: const Color(0xDD2D0000),
      children: [
        const Text('😵 GAME OVER',
            style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF5555))),
        const SizedBox(height: 8),
        const Text('The baby got your finger!',
            style: TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 24),
        _ScoreDisplay(score: total, label: 'TOTAL SCORE'),
        const SizedBox(height: 8),
        Text('Best: $best',
            style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFFFE066),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 28),
        _OverlayButton(
          label: '🔄 Try Again',
          color: const Color(0xFFFF6B8A),
          onTap: game.restartGame,
        ),
        const SizedBox(height: 14),
        _OverlayButton(
          label: '🏠 Main Menu',
          color: const Color(0xFF5588DD),
          onTap: onMainMenu,
        ),
      ],
    );
  }
}

// ── Shared UI widgets ─────────────────────────────────────────────────────────

class _OverlayScaffold extends StatelessWidget {
  final List<Widget> children;
  final Color backgroundColor;

  const _OverlayScaffold({
    required this.children,
    this.backgroundColor = const Color(0xDD1A1A2E),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final int score;
  final String label;

  const _ScoreDisplay({required this.score, this.label = 'SCORE'});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, color: Colors.white54, letterSpacing: 2),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFE066),
          ),
        ),
      ],
    );
  }
}
