import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../utils/constants.dart';
import '../tooth_hurts_game.dart';

enum _PacifierState { hidden, entering, held, leaving }

/// A pacifier that pops into the baby's mouth and blocks tooth access.
/// The player can tap it to knock it out early, or wait for it to leave.
class PacifierComponent extends PositionComponent with TapCallbacks {
  _PacifierState _state = _PacifierState.hidden;
  double _stateTimer = 0.0;
  double _nextDelay = 0.0;
  double _wobble = 0.0; // idle wobble angle

  final Random _random = Random();

  // Entry/exit: slides in from the right
  late double _xHidden;
  late double _xVisible;
  late double _parentW;
  late double _parentH;

  // How long the pacifier stays before leaving on its own
  static const _holdDuration = 3.5;
  static const _slideTime = 0.3;
  static const _minDelay = 10.0;
  static const _maxDelay = 18.0;

  PacifierComponent()
      : super(
          size: Vector2(96, 88),
          anchor: Anchor.center,
        );

  @override
  void onMount() {
    super.onMount();
    final parent = this.parent as PositionComponent;
    _parentW = parent.size.x;
    _parentH = parent.size.y;

    // Center of mouth area
    _xVisible = _parentW / 2;
    _xHidden = _parentW + size.x;
    position = Vector2(_xHidden, _parentH / 2);
    _nextDelay = _minDelay + _random.nextDouble() * (_maxDelay - _minDelay);
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _wobble += dt * 3.0;

    switch (_state) {
      case _PacifierState.hidden:
        _stateTimer += dt;
        if (_stateTimer >= _nextDelay) {
          _stateTimer = 0;
          _state = _PacifierState.entering;
        }
        break;

      case _PacifierState.entering:
        _stateTimer += dt;
        final t = (_stateTimer / _slideTime).clamp(0.0, 1.0);
        final eased = 1 - pow(1 - t, 3).toDouble();
        position.x = _xHidden + (_xVisible - _xHidden) * eased;
        if (t >= 1.0) {
          position.x = _xVisible;
          _stateTimer = 0;
          _state = _PacifierState.held;
        }
        break;

      case _PacifierState.held:
        _stateTimer += dt;
        // Gentle bob
        position.y = _parentH / 2 + sin(_wobble * 1.5) * 4;
        if (_stateTimer >= _holdDuration) {
          _stateTimer = 0;
          _state = _PacifierState.leaving;
        }
        break;

      case _PacifierState.leaving:
        _stateTimer += dt;
        final t = (_stateTimer / _slideTime).clamp(0.0, 1.0);
        final eased = pow(t, 2).toDouble();
        position.x = _xVisible + (_xHidden - _xVisible) * eased;
        if (t >= 1.0) {
          position.x = _xHidden;
          position.y = _parentH / 2;
          _stateTimer = 0;
          _state = _PacifierState.hidden;
          _nextDelay = _minDelay + _random.nextDouble() * (_maxDelay - _minDelay);
        }
        break;
    }
  }

  bool get isBlocking =>
      _state == _PacifierState.entering ||
      _state == _PacifierState.held ||
      _state == _PacifierState.leaving;

  @override
  bool containsLocalPoint(Vector2 point) {
    if (!isBlocking) return false;
    // Circular hit area
    final center = size / 2;
    final dx = point.x - center.x;
    final dy = point.y - center.y;
    return dx * dx + dy * dy <= (size.x / 2) * (size.x / 2);
  }

  // ── Tap — player knocks it out early ──────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    if (_state != _PacifierState.held) return;
    _ejectEarly();
    event.handled = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    event.handled = true;
  }

  void _ejectEarly() {
    _stateTimer = 0;
    _state = _PacifierState.leaving;
    // Bump upward as if knocked out
    position.y -= 8;
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!isBlocking) return;

    final cx = size.x / 2;
    final cy = size.y / 2;

    // Idle wobble rotation
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(sin(_wobble) * 0.15);
    canvas.translate(-cx, -cy);

    _drawPacifier(canvas, cx, cy);

    canvas.restore();
  }

  void _drawPacifier(Canvas canvas, double cx, double cy) {
    final w = size.x;
    final h = size.y;

    // Shield — rounded rectangle filling most of the component
    final shieldW = w * 0.82;
    final shieldH = h * 0.58;
    final shieldPaint = Paint()..color = const Color(0xFFFFAA44);
    final shieldRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + h * 0.05), width: shieldW, height: shieldH),
      Radius.circular(shieldW * 0.18),
    );
    canvas.drawRRect(shieldRect, shieldPaint);

    // Shield border
    canvas.drawRRect(
      shieldRect,
      Paint()
        ..color = const Color(0xFFDD8822)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Nipple — oval in center
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.05), width: w * 0.22, height: h * 0.30),
      Paint()..color = const Color(0xFFFFCC88),
    );

    // Nipple border
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.05), width: w * 0.22, height: h * 0.30),
      Paint()
        ..color = const Color(0xFFDD9944)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Handle ring at top
    canvas.drawCircle(
      Offset(cx, cy - h * 0.28),
      w * 0.11,
      Paint()
        ..color = const Color(0xFFDD8822)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Shine on shield
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - w * 0.14, cy - h * 0.04),
          width: w * 0.18,
          height: h * 0.1),
      Paint()..color = const Color(0x55FFFFFF),
    );

    // TAP hint when fully held
    if (_state == _PacifierState.held) {
      final para = _buildText('TAP!');
      canvas.drawParagraph(para, Offset(cx - 20, cy + h * 0.35));
    }
  }

  Paragraph _buildText(String text) {
    final builder = ParagraphBuilder(
      ParagraphStyle(textAlign: TextAlign.center, maxLines: 1),
    )
      ..pushStyle(TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ))
      ..addText(text);
    final p = builder.build();
    p.layout(const ParagraphConstraints(width: 40));
    return p;
  }
}
