import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

enum _FootState { hidden, kicking, held, retracting }

/// A baby foot that kicks in from the side, covering part of the mouth.
///
/// Appears from alternating left/right sides for variety.
class FootComponent extends PositionComponent with TapCallbacks {
  _FootState _state = _FootState.hidden;
  double _stateTimer = 0.0;
  double _nextDelay = 0.0;
  double _wiggle = 0.0;
  bool _fromLeft = true;

  final Random _random = Random();

  late double _parentW;
  late double _parentH;

  double _xShown = 0.0;
  double _xHidden = 0.0;

  static const _slideTime = 0.4;
  static const _holdDuration = 2.8;
  static const _minDelay = 12.0;
  static const _maxDelay = 22.0;

  // Foot size relative to parent (mouth component)
  static const _footW = 80.0;
  static const _footH = 50.0;

  FootComponent()
      : super(
          size: Vector2(_footW, _footH),
          anchor: Anchor.topLeft,
        );

  @override
  void onMount() {
    super.onMount();
    final parent = this.parent as PositionComponent;
    _parentW = parent.size.x;
    _parentH = parent.size.y;
    _resetPosition();
    _nextDelay = _minDelay + _random.nextDouble() * (_maxDelay - _minDelay);
  }

  void _resetPosition() {
    _fromLeft = _random.nextBool();
    if (_fromLeft) {
      _xHidden = -size.x - 4;
      _xShown = -size.x * 0.35; // overlaps from left
    } else {
      _xHidden = _parentW + 4;
      _xShown = _parentW - size.x * 0.65; // overlaps from right
    }
    position = Vector2(_xHidden, _parentH / 2 - size.y / 2);
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _wiggle += dt * 5.0;

    switch (_state) {
      case _FootState.hidden:
        _stateTimer += dt;
        if (_stateTimer >= _nextDelay) {
          _stateTimer = 0;
          _resetPosition();
          _state = _FootState.kicking;
        }
        break;

      case _FootState.kicking:
        _stateTimer += dt;
        final t = (_stateTimer / _slideTime).clamp(0.0, 1.0);
        // Overshoot spring
        final eased = 1 - pow(1 - t, 3).toDouble();
        final overshoot = sin(t * pi) * 12 * (_fromLeft ? 1 : -1);
        position.x = _xHidden + (_xShown - _xHidden) * eased + overshoot;
        if (t >= 1.0) {
          position.x = _xShown;
          _stateTimer = 0;
          _state = _FootState.held;
        }
        break;

      case _FootState.held:
        _stateTimer += dt;
        // Toes wiggle
        position.y =
            _parentH / 2 - size.y / 2 + sin(_wiggle * 2) * 3;
        if (_stateTimer >= _holdDuration) {
          _stateTimer = 0;
          _state = _FootState.retracting;
        }
        break;

      case _FootState.retracting:
        _stateTimer += dt;
        final t = (_stateTimer / _slideTime).clamp(0.0, 1.0);
        final eased = pow(t, 2).toDouble();
        position.x = _xShown + (_xHidden - _xShown) * eased;
        if (t >= 1.0) {
          position.x = _xHidden;
          _stateTimer = 0;
          _state = _FootState.hidden;
          _nextDelay = _minDelay + _random.nextDouble() * (_maxDelay - _minDelay);
        }
        break;
    }
  }

  bool get isBlocking =>
      _state == _FootState.kicking ||
      _state == _FootState.held ||
      _state == _FootState.retracting;

  @override
  bool containsLocalPoint(Vector2 point) {
    if (!isBlocking) return false;
    return point.x >= 0 &&
        point.x <= size.x &&
        point.y >= 0 &&
        point.y <= size.y;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isBlocking) event.handled = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isBlocking) event.handled = true;
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!isBlocking) return;

    canvas.save();
    // Mirror horizontally for right-entry foot
    if (!_fromLeft) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    _drawFoot(canvas);
    canvas.restore();
  }

  void _drawFoot(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    final skinColor = const Color(0xFFFFC896);
    final skinDark = const Color(0xFFE8A870);

    // Heel — large oval on the right side (origin = left entry)
    final heelPaint = Paint()..color = skinDark;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.68, h * 0.55), width: 40, height: 34),
      heelPaint,
    );

    // Sole
    final solePath = Path()
      ..moveTo(w * 0.15, h * 0.3)
      ..quadraticBezierTo(w * 0.0, h * 0.55, w * 0.2, h * 0.85)
      ..lineTo(w * 0.85, h * 0.85)
      ..quadraticBezierTo(w * 0.95, h * 0.55, w * 0.9, h * 0.3)
      ..quadraticBezierTo(w * 0.5, h * 0.0, w * 0.15, h * 0.3)
      ..close();
    canvas.drawPath(solePath, Paint()..color = skinColor);

    // Toes — 5 circles across the top with a wiggle offset
    const toeSizes = [12.0, 13.0, 12.0, 10.5, 9.0];
    final toeXs = [
      w * 0.08,
      w * 0.22,
      w * 0.36,
      w * 0.49,
      w * 0.60,
    ];
    for (int i = 0; i < 5; i++) {
      final wiggleOffset = sin(_wiggle + i * 0.8) * 2.5;
      final r = toeSizes[i];
      canvas.drawCircle(
        Offset(toeXs[i], h * 0.18 + wiggleOffset),
        r,
        Paint()..color = skinColor,
      );
      // Toenail
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(toeXs[i], h * 0.08 + wiggleOffset),
            width: r * 0.9,
            height: r * 0.55),
        Paint()..color = const Color(0xFFFFEEDD),
      );
    }

    // Arch shadow
    canvas.drawPath(
      solePath,
      Paint()
        ..color = skinDark.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 6),
    );

    // Label so the player knows what this is
    if (_state == _FootState.held) {
      final para = _buildLabel('FOOT!');
      canvas.drawParagraph(para, Offset(w * 0.12, h * 0.52));
    }
  }

  Paragraph _buildLabel(String text) {
    final style = ParagraphStyle(textAlign: TextAlign.center, maxLines: 1);
    final builder = ParagraphBuilder(style)
      ..pushStyle(TextStyle(
        color: const Color(0xFFCC4400),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ))
      ..addText(text);
    final p = builder.build();
    p.layout(const ParagraphConstraints(width: 50));
    return p;
  }
}
