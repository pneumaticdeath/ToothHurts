import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../config/difficulty_config.dart';
import '../../utils/constants.dart';
import '../tooth_hurts_game.dart';
import 'baby_type.dart';
import 'mouth_component.dart';
import 'throw_up_component.dart';

/// The baby's face — all visuals drawn on Canvas, no image assets required.
///
/// Owns MouthComponent as a child.
/// Handles squirm, eye-blink, and queasy (pre-throwup) expressions.
/// Renders differently based on [babyType].
class BabyFaceComponent extends PositionComponent {
  late MouthComponent mouth;
  BabyType _babyType = BabyType.human;

  // ── Squirm ──────────────────────────────────────────────────────────────
  final Random _random = Random();
  double _squirmCooldown = 0;
  bool _isSquirming = false;

  // ── Blink ────────────────────────────────────────────────────────────────
  double _blinkCooldown = 3.0;
  double _blinkProgress = 0.0;
  bool _isBlinking = false;

  // ── Expression ───────────────────────────────────────────────────────────
  bool _isQueasy = false; // set true just before throw-up erupts

  BabyFaceComponent()
      : super(
          position: Vector2(kFaceCenterX, kFaceCenterY),
          size: Vector2(kBabyFaceWidth, kBabyFaceHeight),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    mouth = MouthComponent(babyType: _babyType);
    await add(mouth);
    _resetSquirmTimer();
  }

  // ── Round management ───────────────────────────────────────────────────

  Future<void> spawnTeeth(DifficultyConfig diff) async {
    // If baby type changed, rebuild mouth with new type
    if (_babyType != diff.babyType) {
      _babyType = diff.babyType;
      mouth.removeFromParent();
      mouth = MouthComponent(babyType: _babyType);
      await add(mouth);
      await mouth.mounted;
    }

    // Wire up queasy callback to throw-up component
    await mouth.spawnTeeth(diff);
    if (mouth.throwUp != null) {
      // Replace with a new ThrowUpComponent that has the queasy callback wired
      mouth.throwUp!.removeFromParent();
      mouth.throwUp = null;
      final tu = _makeThrowUp();
      mouth.throwUp = tu;
      await mouth.add(tu);
    }
  }

  ThrowUpComponent _makeThrowUp() {
    return ThrowUpComponent(
      onQueasyChanged: (queasy) {
        _isQueasy = queasy;
      },
    );
  }

  void resetPosition() {
    position = Vector2(kFaceCenterX, kFaceCenterY);
    angle = 0;
    _isSquirming = false;
    _isQueasy = false;
  }

  // ── Update ─────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _updateSquirm(dt);
    _updateBlink(dt);
  }

  void _resetSquirmTimer() {
    final diff = (findGame() as ToothHurtsGame?)?.levelState.difficulty;
    final min = diff?.squirmMinDelay ?? 5.0;
    final max = diff?.squirmMaxDelay ?? 8.0;
    _squirmCooldown = min + _random.nextDouble() * (max - min);
  }

  void _updateSquirm(double dt) {
    if (_isSquirming) return;
    _squirmCooldown -= dt;
    if (_squirmCooldown > 0) return;

    final game = findGame() as ToothHurtsGame?;
    if (game == null) return;

    final diff = game.levelState.difficulty;
    final dur = diff.squirmDuration;
    final dx = (_random.nextDouble() - 0.5) * 2 * diff.squirmMaxOffset;
    final da = (_random.nextDouble() - 0.5) * 2 * diff.squirmMaxAngle;

    _isSquirming = true;
    game.audioManager.playSquirm();

    final moveEffect = MoveEffect.by(
      Vector2(dx, 0),
      EffectController(duration: dur, reverseDuration: dur),
    );
    moveEffect.onComplete = () => _isSquirming = false;
    add(moveEffect);
    add(RotateEffect.by(da, EffectController(duration: dur, reverseDuration: dur)));

    _resetSquirmTimer();
  }

  void _updateBlink(double dt) {
    if (_isBlinking) {
      _blinkProgress += dt * 6;
      if (_blinkProgress >= 1.0) {
        _blinkProgress = 1.0;
        _isBlinking = false;
        _blinkCooldown = 0.12;
      }
    } else if (_blinkCooldown <= 0) {
      if (_blinkProgress > 0) {
        _blinkProgress -= dt * 5;
        if (_blinkProgress < 0) {
          _blinkProgress = 0;
          _blinkCooldown = 2.8 + _random.nextDouble() * 2.4;
        }
      } else {
        _blinkCooldown -= dt;
        if (_blinkCooldown <= 0) _isBlinking = true;
      }
    } else {
      _blinkCooldown -= dt;
    }
  }

  // ── Render dispatch ─────────────────────────────────────────────────────

  double get _cx => size.x / 2;
  double get _cy => size.y / 2;

  @override
  void render(Canvas canvas) {
    switch (_babyType) {
      case BabyType.human:
        _renderHuman(canvas);
        break;
      case BabyType.alligator:
        _renderAlligator(canvas);
        break;
      case BabyType.fish:
        _renderFish(canvas);
        break;
    }
  }

  // ── Human baby ────────────────────────────────────────────────────────────

  void _renderHuman(Canvas canvas) {
    _drawHumanFace(canvas);
    _drawEars(canvas, kSkinShadow);
    _drawHair(canvas);
    _drawEyebrows(canvas, const Color(0xFF8B5E3C));
    _drawHumanEyes(canvas);
    _drawHumanNose(canvas);
    _drawCheeks(canvas);
  }

  void _drawHumanFace(Canvas canvas) {
    final cx = _cx, cy = _cy;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: size.x * 0.88, height: size.y * 0.9),
      Paint()..color = kSkinColor,
    );
    // Jaw shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + size.y * 0.28), width: size.x * 0.6, height: 18),
      Paint()..color = kSkinShadow..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Forehead highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - size.y * 0.28), width: size.x * 0.44, height: size.y * 0.22),
      Paint()..color = kSkinHighlight..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  void _drawEars(Canvas canvas, Color color) {
    final cx = _cx, cy = _cy;
    final paint = Paint()..color = color;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - size.x * 0.44, cy - 4), width: 22, height: 32), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + size.x * 0.44, cy - 4), width: 22, height: 32), paint);
  }

  void _drawHair(Canvas canvas) {
    final cx = _cx, cy = _cy;
    const hairColor = Color(0xFFC68642);
    const hairDark = Color(0xFFA0522D);
    const hairLight = Color(0xFFD4956A);

    // Hair cap — covers the top of the head
    final capPath = Path()
      ..moveTo(cx - size.x * 0.42, cy - size.y * 0.18)
      ..cubicTo(
        cx - size.x * 0.44, cy - size.y * 0.52,
        cx + size.x * 0.44, cy - size.y * 0.52,
        cx + size.x * 0.42, cy - size.y * 0.18,
      )
      ..close();
    canvas.drawPath(capPath, Paint()..color = hairColor);

    // Darker base — gives depth at the hairline
    final baseGrad = Paint()
      ..color = hairDark
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy - size.y * 0.18),
          width: size.x * 0.84,
          height: 18),
      baseGrad,
    );

    // Wispy individual strands (a few curved lines)
    final strandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    // Center tuft curling to the right
    strandPaint.color = hairLight;
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - size.y * 0.44)
        ..cubicTo(cx + 8, cy - size.y * 0.54, cx + 18, cy - size.y * 0.52, cx + 12, cy - size.y * 0.42),
      strandPaint,
    );

    // Left wisp
    strandPaint.color = hairColor;
    canvas.drawPath(
      Path()
        ..moveTo(cx - 14, cy - size.y * 0.42)
        ..cubicTo(cx - 20, cy - size.y * 0.54, cx - 8, cy - size.y * 0.56, cx - 4, cy - size.y * 0.44),
      strandPaint,
    );

    // Right wisp
    canvas.drawPath(
      Path()
        ..moveTo(cx + 14, cy - size.y * 0.41)
        ..cubicTo(cx + 22, cy - size.y * 0.53, cx + 32, cy - size.y * 0.50, cx + 26, cy - size.y * 0.40),
      strandPaint,
    );

    // Highlight sheen across the top of the cap
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - 8, cy - size.y * 0.38),
          width: size.x * 0.3,
          height: 10),
      Paint()
        ..color = const Color(0x44FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawEyebrows(Canvas canvas, Color color) {
    final cx = _cx, cy = _cy;
    final browPaint = Paint()
      ..color = _isQueasy ? const Color(0xFF6B4226) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Queasy = furrowed brows (inner ends lower)
    final innerDip = _isQueasy ? 8.0 : 0.0;

    canvas.drawPath(
      Path()
        ..moveTo(cx - 52, cy - size.y * 0.16)
        ..quadraticBezierTo(cx - 36, cy - size.y * 0.2, cx - 22, cy - size.y * 0.16 + innerDip),
      browPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 22, cy - size.y * 0.16 + innerDip)
        ..quadraticBezierTo(cx + 36, cy - size.y * 0.2, cx + 52, cy - size.y * 0.16),
      browPaint,
    );
  }

  void _drawHumanEyes(Canvas canvas) {
    final cx = _cx, cy = _cy;
    const eyeOffX = 36.0;
    final eyeY = cy - size.y * 0.06;
    _drawEyeball(canvas, cx - eyeOffX, eyeY, const Color(0xFF6B4226));
    _drawEyeball(canvas, cx + eyeOffX, eyeY, const Color(0xFF6B4226));
  }

  void _drawEyeball(Canvas canvas, double ex, double ey, Color irisColor) {
    const eyeRx = 14.0;
    const eyeRy = 13.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(ex, ey), width: eyeRx * 2, height: eyeRy * 2),
      Paint()..color = kEyeWhite,
    );

    final openRy = eyeRy * (1.0 - _blinkProgress);
    if (_isQueasy) {
      // Queasy: wavy/spiral eyes drawn as Xs
      _drawQueasyEye(canvas, ex, ey, eyeRx);
    } else if (openRy > 0.5) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey), width: eyeRx * 1.1, height: openRy * 2 * 1.1),
        Paint()..color = irisColor,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey), width: eyeRx * 0.56, height: openRy * 2 * 0.56),
        Paint()..color = kPupilColor,
      );
      canvas.drawCircle(
        Offset(ex - eyeRx * 0.25, ey - openRy * 0.3), 2.2,
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }

    // Blink lid
    if (_blinkProgress > 0) {
      canvas.drawRect(
        Rect.fromLTWH(ex - eyeRx, ey - eyeRy, eyeRx * 2, eyeRy * _blinkProgress),
        Paint()..color = kSkinColor,
      );
    }

    // Lashes
    final lashPaint = Paint()..color = const Color(0xFF4A2C0A)..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(Offset(ex + i * 4.5, ey - eyeRy), Offset(ex + i * 5.0, ey - eyeRy - 4), lashPaint);
    }
  }

  void _drawQueasyEye(Canvas canvas, double ex, double ey, double r) {
    // Spiral / dizzy X eyes
    final paint = Paint()
      ..color = const Color(0xFF2D1B00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ex - r * 0.5, ey - r * 0.5), Offset(ex + r * 0.5, ey + r * 0.5), paint);
    canvas.drawLine(Offset(ex + r * 0.5, ey - r * 0.5), Offset(ex - r * 0.5, ey + r * 0.5), paint);
  }

  void _drawHumanNose(Canvas canvas) {
    final cx = _cx, cy = _cy;
    final nosePaint = Paint()
      ..color = kSkinShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()..moveTo(cx - 8, cy + 12)..quadraticBezierTo(cx, cy + 18, cx + 8, cy + 12),
      nosePaint,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 6, cy + 14), width: 6, height: 4), Paint()..color = kSkinShadow.withOpacity(0.6));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 6, cy + 14), width: 6, height: 4), Paint()..color = kSkinShadow.withOpacity(0.6));
  }

  void _drawCheeks(Canvas canvas) {
    final cx = _cx, cy = _cy;
    final cheekPaint = Paint()..color = kCheekColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 46, cy + 20), width: 46, height: 30), cheekPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 46, cy + 20), width: 46, height: 30), cheekPaint);
  }

  // ── Alligator baby ────────────────────────────────────────────────────────

  void _renderAlligator(Canvas canvas) {
    _drawGatorBody(canvas);
    _drawGatorEyes(canvas);
    _drawGatorNostrils(canvas);
    _drawGatorScales(canvas);
  }

  void _drawGatorBody(Canvas canvas) {
    final cx = _cx, cy = _cy;
    final green = const Color(0xFF4A7A1E);
    final greenDark = const Color(0xFF2E5A0A);

    // Elongated snout body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 10), width: size.x * 0.9, height: size.y * 0.55),
      Paint()..color = green,
    );
    // Forehead bump
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - size.y * 0.22), width: size.x * 0.65, height: size.y * 0.3),
      Paint()..color = green,
    );
    // Snout protrusion (lower)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 10), width: size.x * 0.72, height: size.y * 0.45),
      Paint()..color = greenDark,
    );
    // Underbelly — yellowish
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: size.x * 0.55, height: size.y * 0.28),
      Paint()..color = const Color(0xFFCCDD88),
    );
  }

  void _drawGatorEyes(Canvas canvas) {
    final cx = _cx, cy = _cy;
    // Gator eyes protrude on top of head, wide-set
    for (final ex in [cx - 44.0, cx + 44.0]) {
      final ey = cy - size.y * 0.25;
      // Eye bump
      canvas.drawCircle(Offset(ex, ey), 16, Paint()..color = const Color(0xFF3E6A18));
      // Sclera
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, ey), width: 22, height: 18),
        Paint()..color = const Color(0xFFDDCC44),
      );
      // Slit pupil
      final openH = 14.0 * (1 - _blinkProgress);
      if (openH > 1) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(ex, ey), width: 5, height: openH),
          Paint()..color = const Color(0xFF111100),
        );
      }
      // Blink lid
      if (_blinkProgress > 0) {
        canvas.drawRect(
          Rect.fromLTWH(ex - 11, ey - 9, 22, 18 * _blinkProgress),
          Paint()..color = const Color(0xFF3E6A18),
        );
      }
    }
  }

  void _drawGatorNostrils(Canvas canvas) {
    final cx = _cx, cy = _cy;
    final np = Paint()..color = const Color(0xFF1A3A00);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 12, cy - 2), width: 10, height: 7), np);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 12, cy - 2), width: 10, height: 7), np);
  }

  void _drawGatorScales(Canvas canvas) {
    final cx = _cx, cy = _cy;
    final scalePaint = Paint()
      ..color = const Color(0xFF2E5A0A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // A few hex-ish scale outlines on the top of the head
    for (int row = 0; row < 2; row++) {
      for (int col = -2; col <= 2; col++) {
        final sx = cx + col * 20.0 + (row % 2 == 0 ? 0 : 10);
        final sy = cy - size.y * 0.32 + row * 14;
        canvas.drawOval(Rect.fromCenter(center: Offset(sx, sy), width: 16, height: 10), scalePaint);
      }
    }
  }

  // ── Fish baby ─────────────────────────────────────────────────────────────

  void _renderFish(Canvas canvas) {
    _drawFishBody(canvas);
    _drawFishFins(canvas);
    _drawFishEyes(canvas);
    _drawFishScalePattern(canvas);
  }

  void _drawFishBody(Canvas canvas) {
    final cx = _cx, cy = _cy;
    final blue = const Color(0xFF2255AA);
    final blueLight = const Color(0xFF4488DD);

    // Main body oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: size.x * 0.82, height: size.y * 0.75),
      Paint()..color = blue,
    );

    // Iridescent highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 20, cy - 20), width: size.x * 0.4, height: size.y * 0.3),
      Paint()..color = blueLight..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + size.y * 0.15), width: size.x * 0.5, height: size.y * 0.3),
      Paint()..color = const Color(0xFFAADDFF),
    );
  }

  void _drawFishFins(Canvas canvas) {
    final cx = _cx, cy = _cy;
    final finColor = const Color(0xFF1144AA);

    // Left pectoral fin
    final leftFin = Path()
      ..moveTo(cx - size.x * 0.38, cy)
      ..cubicTo(cx - size.x * 0.55, cy - 20, cx - size.x * 0.5, cy + 30, cx - size.x * 0.35, cy + 20)
      ..close();
    canvas.drawPath(leftFin, Paint()..color = finColor);

    // Right pectoral fin
    final rightFin = Path()
      ..moveTo(cx + size.x * 0.38, cy)
      ..cubicTo(cx + size.x * 0.55, cy - 20, cx + size.x * 0.5, cy + 30, cx + size.x * 0.35, cy + 20)
      ..close();
    canvas.drawPath(rightFin, Paint()..color = finColor);

    // Dorsal fin on top
    final dorsalFin = Path()
      ..moveTo(cx - 20, cy - size.y * 0.35)
      ..cubicTo(cx - 5, cy - size.y * 0.55, cx + 10, cy - size.y * 0.52, cx + 20, cy - size.y * 0.35)
      ..close();
    canvas.drawPath(dorsalFin, Paint()..color = finColor);
  }

  void _drawFishEyes(Canvas canvas) {
    final cx = _cx, cy = _cy;
    // Fish eyes are on the SIDES of the head, large and round
    for (final side in [-1.0, 1.0]) {
      final ex = cx + side * size.x * 0.3;
      final ey = cy - size.y * 0.08;

      canvas.drawCircle(Offset(ex, ey), 16, Paint()..color = const Color(0xFFFFFFEE));
      final openR = 11.0 * (1 - _blinkProgress);
      if (openR > 1) {
        canvas.drawCircle(Offset(ex, ey), openR, Paint()..color = const Color(0xFFFF8800));
        canvas.drawCircle(Offset(ex, ey), openR * 0.45, Paint()..color = const Color(0xFF000000));
        canvas.drawCircle(Offset(ex - 3, ey - 3), 2.5, Paint()..color = const Color(0xAAFFFFFF));
      }
      if (_blinkProgress > 0) {
        canvas.drawRect(
          Rect.fromLTWH(ex - 16, ey - 16, 32, 32 * _blinkProgress),
          Paint()..color = const Color(0xFF2255AA),
        );
      }
    }
  }

  void _drawFishScalePattern(Canvas canvas) {
    final cx = _cx, cy = _cy;
    final scalePaint = Paint()
      ..color = const Color(0x441133AA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int row = 0; row < 3; row++) {
      for (int col = -2; col <= 2; col++) {
        final sx = cx + col * 18.0 + (row % 2 == 0 ? 0 : 9);
        final sy = cy + row * 12.0 - 10;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(sx, sy), width: 18, height: 12),
          0, pi, false,
          scalePaint,
        );
      }
    }
  }
}

