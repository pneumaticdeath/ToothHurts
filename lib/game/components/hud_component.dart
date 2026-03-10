import 'dart:ui';

import 'package:flame/components.dart';

import '../../utils/constants.dart';
import '../tooth_hurts_game.dart';
import 'baby_type.dart';

/// Heads-up display rendered in camera viewport space (never moves/squirms).
/// Draws lives (hearts), current score, level badge.
class HudComponent extends PositionComponent {
  HudComponent()
      : super(
          position: Vector2.zero(),
          size: Vector2(kDesignWidth, kDesignHeight),
          priority: 100,
        );

  ToothHurtsGame get _game => findGame()! as ToothHurtsGame;

  @override
  void render(Canvas canvas) {
    _drawTopBar(canvas);
  }

  void _drawTopBar(Canvas canvas) {
    final game = _game;
    final barTop = game.topInset + 4;
    final barCY = barTop + 27;

    // Semi-transparent pill background
    final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(10, barTop, 370, 54), const Radius.circular(27));
    canvas.drawRRect(barRect, Paint()..color = kHudBg);

    // Hearts (lives)
    for (int i = 0; i < 3; i++) {
      final filled = i < game.playerState.lives;
      _drawHeart(canvas, Offset(36.0 + i * 40, barCY), filled);
    }

    // Score
    _drawText(
      canvas,
      'SCORE: ${game.playerState.score}',
      Offset(kDesignWidth / 2, barCY),
      fontSize: 18,
      color: kScoreColor,
      align: TextAlign.center,
    );

    // Level badge + baby type emoji
    final babyEmoji = game.levelState.difficulty.babyType.emoji;
    _drawText(
      canvas,
      '$babyEmoji LVL ${game.levelState.level}',
      Offset(348, barCY),
      fontSize: 15,
      color: kLevelColor,
      align: TextAlign.right,
    );

    // Pause hint
    _drawText(
      canvas,
      '⏸',
      Offset(375, barCY),
      fontSize: 20,
      color: const Color(0x88FFFFFF),
      align: TextAlign.right,
    );
  }

  void _drawHeart(Canvas canvas, Offset center, bool filled) {
    final paint = Paint()
      ..color = filled ? kHeartFull : kHeartEmpty
      ..style = PaintingStyle.fill;

    final path = _heartPath(center, 13);
    canvas.drawPath(path, paint);

    if (filled) {
      // Highlight glint
      canvas.drawCircle(
        Offset(center.dx - 3.5, center.dy - 4),
        2.5,
        Paint()..color = const Color(0x66FFFFFF),
      );
    }
  }

  Path _heartPath(Offset center, double r) {
    final cx = center.dx;
    final cy = center.dy;
    final path = Path();
    path.moveTo(cx, cy + r * 0.7);
    // Left lobe
    path.cubicTo(cx - r * 1.6, cy, cx - r * 1.6, cy - r * 1.1, cx, cy - r * 0.3);
    // Right lobe
    path.cubicTo(cx + r * 1.6, cy - r * 1.1, cx + r * 1.6, cy, cx, cy + r * 0.7);
    path.close();
    return path;
  }

  // ── Text helper ─────────────────────────────────────────────────────────────

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    double fontSize = 16,
    Color color = const Color(0xFFFFFFFF),
    TextAlign align = TextAlign.left,
    FontWeight weight = FontWeight.bold,
  }) {
    final paragraph = _buildParagraph(
      text,
      fontSize: fontSize,
      color: color,
      align: align,
      weight: weight,
    );
    final x = align == TextAlign.center
        ? position.dx - paragraph.maxIntrinsicWidth / 2
        : align == TextAlign.right
            ? position.dx - paragraph.maxIntrinsicWidth
            : position.dx;
    canvas.drawParagraph(
      paragraph,
      Offset(x, position.dy - fontSize * 0.6),
    );
  }

  Paragraph _buildParagraph(
    String text, {
    double fontSize = 16,
    Color color = const Color(0xFFFFFFFF),
    TextAlign align = TextAlign.left,
    FontWeight weight = FontWeight.bold,
  }) {
    final style = ParagraphStyle(
      textAlign: align,
      maxLines: 1,
    );
    final builder = ParagraphBuilder(style)
      ..pushStyle(TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
      ))
      ..addText(text);
    final paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    return paragraph;
  }
}
