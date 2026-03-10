import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../tooth_hurts_game.dart';

enum _ThrowUpState { hidden, warning, erupting, covering, draining }

/// Baby throw-up complication.
///
/// 1. Warning: baby face shows a queasy expression (handled via callback)
/// 2. Eruption: green goo shoots upward from the mouth
/// 3. Covering: goo pools over the mouth, blocking all tooth taps
/// 4. Draining: goo slowly slides down and disappears
class ThrowUpComponent extends PositionComponent with TapCallbacks {
  _ThrowUpState _state = _ThrowUpState.hidden;
  double _stateTimer = 0.0;
  double _nextDelay = 0.0;
  double _fillLevel = 0.0; // 0 = empty, 1 = full coverage
  double _wobble = 0.0;

  /// Called when warning starts so BabyFaceComponent can show queasy face.
  final void Function(bool queasy)? onQueasyChanged;

  final Random _random = Random();

  static const _warningDuration = 1.2;
  static const _eruptDuration = 0.5;
  static const _coverDuration = 3.0;
  static const _drainDuration = 2.0;
  static const _minDelay = 15.0;
  static const _maxDelay = 25.0;

  // Splat particles
  final List<_Splat> _splats = [];

  ThrowUpComponent({this.onQueasyChanged})
      : super(
          position: Vector2.zero(),
          anchor: Anchor.topLeft,
        );

  @override
  void onMount() {
    super.onMount();
    final parent = this.parent as PositionComponent;
    size = Vector2(parent.size.x, parent.size.y);
    _nextDelay = _minDelay + _random.nextDouble() * (_maxDelay - _minDelay);
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _wobble += dt * 4.0;

    switch (_state) {
      case _ThrowUpState.hidden:
        _stateTimer += dt;
        if (_stateTimer >= _nextDelay) {
          _stateTimer = 0;
          _state = _ThrowUpState.warning;
          onQueasyChanged?.call(true);
        }
        break;

      case _ThrowUpState.warning:
        _stateTimer += dt;
        if (_stateTimer >= _warningDuration) {
          _stateTimer = 0;
          _state = _ThrowUpState.erupting;
          _spawnSplats();
          onQueasyChanged?.call(false);
        }
        break;

      case _ThrowUpState.erupting:
        _stateTimer += dt;
        final t = (_stateTimer / _eruptDuration).clamp(0.0, 1.0);
        _fillLevel = t;
        _updateSplats(dt);
        if (t >= 1.0) {
          _stateTimer = 0;
          _state = _ThrowUpState.covering;
        }
        break;

      case _ThrowUpState.covering:
        _stateTimer += dt;
        _fillLevel = 1.0;
        _updateSplats(dt);
        if (_stateTimer >= _coverDuration) {
          _stateTimer = 0;
          _state = _ThrowUpState.draining;
        }
        break;

      case _ThrowUpState.draining:
        _stateTimer += dt;
        final t = (_stateTimer / _drainDuration).clamp(0.0, 1.0);
        _fillLevel = 1.0 - t;
        if (t >= 1.0) {
          _fillLevel = 0;
          _splats.clear();
          _stateTimer = 0;
          _state = _ThrowUpState.hidden;
          _nextDelay = _minDelay + _random.nextDouble() * (_maxDelay - _minDelay);
        }
        break;
    }
  }

  void _spawnSplats() {
    _splats.clear();
    for (int i = 0; i < 12; i++) {
      _splats.add(_Splat(
        x: size.x * (0.1 + _random.nextDouble() * 0.8),
        y: size.y * (0.0 + _random.nextDouble() * 0.6),
        radius: 4 + _random.nextDouble() * 14,
      ));
    }
  }

  void _updateSplats(double dt) {
    for (final s in _splats) {
      s.drip += dt * 6.0;
    }
  }

  bool get isBlocking =>
      _state == _ThrowUpState.erupting ||
      _state == _ThrowUpState.covering ||
      _state == _ThrowUpState.draining;

  @override
  bool containsLocalPoint(Vector2 point) {
    if (_fillLevel < 0.1) return false;
    return point.y >= 0 && point.y <= size.y * _fillLevel;
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
    if (_fillLevel <= 0) return;

    final w = size.x;
    final h = size.y;

    // Main goo fill from bottom up
    final gooHeight = h * _fillLevel;
    final gooTop = h - gooHeight;

    // Wobbly top edge path
    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, gooTop + sin(_wobble) * 4);
    // Wavy top
    for (double x = 0; x <= w; x += 8) {
      final waveY = gooTop + sin(_wobble + x * 0.15) * 5;
      path.lineTo(x, waveY);
    }
    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xCC7DC544));

    // Splat blobs
    final splatPaint = Paint()..color = const Color(0xDD8BD650);
    for (final s in _splats) {
      if (s.y + s.drip < h * _fillLevel + 10) {
        canvas.drawCircle(Offset(s.x, min(s.y + s.drip, h - 4)), s.radius, splatPaint);
      }
    }

    // Drip lines
    final dripPaint = Paint()
      ..color = const Color(0xAA5A9E30)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final dripPositions = [w * 0.2, w * 0.45, w * 0.7, w * 0.85];
    for (final dx in dripPositions) {
      final dripLen =
          12 + sin(_wobble + dx) * 6;
      canvas.drawLine(
        Offset(dx, gooTop + sin(_wobble + dx * 0.1) * 4),
        Offset(dx + sin(_wobble * 0.5) * 3, gooTop - dripLen),
        dripPaint,
      );
    }

    // Shine on goo surface
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.3, gooTop + 8), width: 22, height: 8),
      Paint()..color = const Color(0x44FFFFFF),
    );
  }
}

class _Splat {
  double x;
  double y;
  double radius;
  double drip = 0;

  _Splat({required this.x, required this.y, required this.radius});
}
