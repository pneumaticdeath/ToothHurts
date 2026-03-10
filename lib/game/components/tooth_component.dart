import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../utils/constants.dart';
import '../../utils/haptic_util.dart';
import '../tooth_hurts_game.dart';

/// A single tappable tooth inside the mouth.
///
/// Tap briefly  → tooth counted (turns gold + checkmark).
/// Hold too long → bite triggered via BiteSystem.
///
/// [sharp] = alligator style (narrow, pointed triangle)
/// [fishy] = fish style (curved fang)
/// [flipped] = top-row tooth (rendered upside-down); checkmark is counter-flipped
class ToothComponent extends PositionComponent with TapCallbacks {
  final int index;
  final bool sharp;   // alligator-style pointed tooth
  final bool fishy;   // fish-style curved fang
  final bool flipped; // top-row tooth — body is flipped, checkmark is not

  bool isCounted = false;
  bool _isPressed = false;

  // Pulse scale for "just counted" feedback
  double _pulseScale = 1.0;
  double _pulseTimer = 0.0;
  static const _pulseDuration = 0.25;

  ToothComponent({
    required this.index,
    required Vector2 position,
    double toothWidth = kToothWidth,
    this.sharp = false,
    this.fishy = false,
    this.flipped = false,
  }) : super(
          position: position,
          size: Vector2(toothWidth, kToothHeight),
          anchor: Anchor.topCenter,
        );

  ToothHurtsGame get _game => findGame()! as ToothHurtsGame;

  // ── Input ──────────────────────────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    if (!_canAcceptInput) return;
    if (isCounted) {
      // Still mark as pressed so onTapUp can fire the reset
      _isPressed = true;
      event.handled = true;
      return;
    }
    _isPressed = true;
    _game.biteSystem.startHold(index);
    event.handled = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_isPressed) return;
    _isPressed = false;
    _game.biteSystem.cancelHold(index);

    if (_canAcceptInput) {
      if (isCounted) {
        // Tapping a counted tooth loses all progress
        _game.onCountReset();
      } else {
        isCounted = true;
        _pulseTimer = _pulseDuration;
        _game.onToothCounted(index);
        HapticUtil.countTick();
      }
    }
    event.handled = true;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (_isPressed) {
      _isPressed = false;
      _game.biteSystem.cancelHold(index);
    }
  }

  bool get _canAcceptInput {
    final phase = _game.phaseNotifier.value;
    return phase == RoundPhase.counting || phase == RoundPhase.tongueActive;
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_pulseTimer > 0) {
      _pulseTimer -= dt;
      final t = (_pulseTimer / _pulseDuration).clamp(0.0, 1.0);
      // Ease out: quick expand then back to 1
      _pulseScale = 1.0 + 0.25 * t * (1 - t) * 4;
    } else {
      _pulseScale = 1.0;
    }
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    canvas.save();

    // Apply pulse scale around center of tooth
    if (_pulseScale != 1.0) {
      canvas.translate(size.x / 2, size.y / 2);
      canvas.scale(_pulseScale);
      canvas.translate(-size.x / 2, -size.y / 2);
    }

    _drawTooth(canvas);

    canvas.restore();
  }

  void _drawTooth(Canvas canvas) {
    if (sharp) {
      _drawSharpTooth(canvas);
    } else if (fishy) {
      _drawFishTooth(canvas);
    } else {
      _drawHumanTooth(canvas);
    }
  }

  void _drawHumanTooth(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    final bodyColor = isCounted
        ? kToothCountedColor
        : _isPressed
            ? kToothPressedColor
            : kToothColor;

    // Slightly tapered trapezoid
    final toothPath = Path()
      ..moveTo(w * 0.08, 0)
      ..lineTo(w * 0.92, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(toothPath, Paint()..color = bodyColor);

    if (!isCounted) {
      final shadePath = Path()
        ..moveTo(w * 0.7, 0)
        ..lineTo(w * 0.92, 0)
        ..lineTo(w, h)
        ..lineTo(w * 0.78, h)
        ..close();
      canvas.drawPath(shadePath, Paint()..color = const Color(0x22000000));
    }

    // Gum strip
    final gumPath = Path()
      ..moveTo(w * 0.08, 0)
      ..lineTo(w * 0.92, 0)
      ..lineTo(w * 0.88, 6)
      ..lineTo(w * 0.12, 6)
      ..close();
    canvas.drawPath(gumPath, Paint()..color = kGumColor);

    if (isCounted) _drawCheckmark(canvas, w, h);
  }

  void _drawSharpTooth(Canvas canvas) {
    // Alligator: narrow triangle with a slight curve and yellow tint
    final w = size.x;
    final h = size.y;

    final bodyColor = isCounted
        ? kToothCountedColor
        : _isPressed
            ? kToothPressedColor
            : const Color(0xFFF0EED0); // ivory

    // Sharp triangle
    final toothPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w * 0.5, h) // pointed tip
      ..close();

    canvas.drawPath(toothPath, Paint()..color = bodyColor);

    // Shading on right face
    if (!isCounted) {
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.55, 0)
          ..lineTo(w, 0)
          ..lineTo(w * 0.5, h)
          ..close(),
        Paint()..color = const Color(0x22000000),
      );
    }

    // Gum at base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 5),
      Paint()..color = const Color(0xFF4A7A00),
    );

    if (isCounted) _drawCheckmark(canvas, w, h);
  }

  void _drawFishTooth(Canvas canvas) {
    // Fish: curved fang shape, slightly translucent bluish-white
    final w = size.x;
    final h = size.y;

    final bodyColor = isCounted
        ? kToothCountedColor
        : _isPressed
            ? kToothPressedColor
            : const Color(0xFFDDEEFF); // pale blue-white

    final toothPath = Path()
      ..moveTo(w * 0.1, 0)
      ..lineTo(w * 0.9, 0)
      ..quadraticBezierTo(w * 1.1, h * 0.6, w * 0.5, h) // curved side
      ..quadraticBezierTo(-w * 0.1, h * 0.6, w * 0.1, 0)
      ..close();

    canvas.drawPath(toothPath, Paint()..color = bodyColor);

    // Iridescent shimmer line
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.3, 2)
        ..lineTo(w * 0.3, h * 0.7),
      Paint()
        ..color = const Color(0x5588CCFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Gum strip
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 5),
      Paint()..color = const Color(0xFF003366),
    );

    if (isCounted) _drawCheckmark(canvas, w, h);
  }

  void _drawCheckmark(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF1A6B1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    if (flipped) {
      // Counter-flip so the checkmark reads right-side-up on top teeth
      canvas.translate(w / 2, h / 2);
      canvas.scale(1, -1);
      canvas.translate(-w / 2, -h / 2);
    }
    final path = Path()
      ..moveTo(w * 0.18, h * 0.52)
      ..lineTo(w * 0.44, h * 0.78)
      ..lineTo(w * 0.82, h * 0.28);
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}
