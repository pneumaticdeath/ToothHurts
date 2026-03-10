import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../config/difficulty_config.dart';
import '../../utils/constants.dart';
import '../../utils/haptic_util.dart';
import '../tooth_hurts_game.dart';

enum _TongueState { hidden, sliding, held, leaving }

/// A small tongue blob that wanders around the mouth, blocking 1–2 teeth at a time.
/// Slides to a random tooth position, pauses, then moves to another spot before retreating.
class TongueComponent extends PositionComponent with TapCallbacks {
  final double mouthHeight;

  _TongueState _state = _TongueState.hidden;
  double _stateTimer = 0.0;
  double _nextDelay = 0.0;
  int _wanderCount = 0;
  int _maxWanders = 2;

  final Random _random = Random();
  late DifficultyConfig _diff;

  Vector2 _fromPos = Vector2.zero();
  Vector2 _targetPos = Vector2.zero();

  static const _tongueW = 38.0;
  static const _tongueH = 17.0;
  static const _slideTime = 0.22;

  TongueComponent({required this.mouthHeight})
      : super(
          size: Vector2(_tongueW, _tongueH),
          anchor: Anchor.topLeft,
        );

  @override
  void onMount() {
    super.onMount();
    position = Vector2(-_tongueW - 10, 0);
    _diff = (findGame() as ToothHurtsGame).levelState.difficulty;
    _nextDelay = _randomDelay();
  }

  double _randomDelay() =>
      _diff.tongueMinDelay +
      _random.nextDouble() * (_diff.tongueMaxDelay - _diff.tongueMinDelay);

  /// Pick a random position over the top or bottom teeth row.
  Vector2 _randomBlockPosition() {
    final onBottom = _random.nextBool();
    final maxX = kMouthWidth - _tongueW;
    final x = 4.0 + _random.nextDouble() * (maxX - 4.0);
    // Bottom teeth span y = (mouthHeight - kToothHeight)..mouthHeight
    // Top teeth span y = 0..kToothHeight
    final y = onBottom
        ? mouthHeight - kToothHeight + 2.0
        : kToothHeight - _tongueH - 2.0;
    return Vector2(x, y);
  }

  Vector2 _offscreenExit() {
    // Exit off whichever horizontal edge is closer
    final exitX = position.x < kMouthWidth / 2
        ? -_tongueW - 10
        : kMouthWidth + 10;
    return Vector2(exitX, position.y);
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    final game = findGame() as ToothHurtsGame?;
    if (game != null) _diff = game.levelState.difficulty;

    switch (_state) {
      case _TongueState.hidden:
        _stateTimer += dt;
        if (_stateTimer >= _nextDelay) {
          _stateTimer = 0;
          _wanderCount = 0;
          _maxWanders = 2 + _random.nextInt(3); // 2–4 spots per visit
          _startSlide(_randomBlockPosition());
          HapticUtil.tongueIn();
          game?.audioManager.playTongueSlurp();
        }
        break;

      case _TongueState.sliding:
        _stateTimer += dt;
        final st = (_stateTimer / _slideTime).clamp(0.0, 1.0);
        final eased = 1 - pow(1 - st, 3).toDouble();
        position.x = _fromPos.x + (_targetPos.x - _fromPos.x) * eased;
        position.y = _fromPos.y + (_targetPos.y - _fromPos.y) * eased;
        if (st >= 1.0) {
          position.setFrom(_targetPos);
          _stateTimer = 0;
          _state = _TongueState.held;
        }
        break;

      case _TongueState.held:
        _stateTimer += dt;
        if (_stateTimer >= _diff.tongueHoldDuration) {
          _stateTimer = 0;
          _wanderCount++;
          if (_wanderCount < _maxWanders) {
            _startSlide(_randomBlockPosition());
          } else {
            _startSlide(_offscreenExit());
            _state = _TongueState.leaving;
          }
        }
        break;

      case _TongueState.leaving:
        _stateTimer += dt;
        final lt = (_stateTimer / _slideTime).clamp(0.0, 1.0);
        final eased = pow(lt, 2).toDouble();
        position.x = _fromPos.x + (_targetPos.x - _fromPos.x) * eased;
        position.y = _fromPos.y + (_targetPos.y - _fromPos.y) * eased;
        if (lt >= 1.0) {
          position = Vector2(-_tongueW - 10, 0);
          _stateTimer = 0;
          _state = _TongueState.hidden;
          _nextDelay = _randomDelay();
        }
        break;
    }
  }

  void _startSlide(Vector2 target) {
    _fromPos = position.clone();
    _targetPos = target;
    _stateTimer = 0;
    _state = _TongueState.sliding;
  }

  // ── Hit detection ──────────────────────────────────────────────────────────

  bool get isBlocking =>
      _state == _TongueState.sliding || _state == _TongueState.held;

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
    event.handled = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    event.handled = true;
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    // Visible whenever not fully off-screen (mouth clips the canvas anyway)
    if (position.x < -_tongueW + 2 && _state == _TongueState.hidden) return;

    final w = size.x;
    final h = size.y;

    // Body — pink rounded pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(h * 0.5),
      ),
      Paint()..color = kTongueColor,
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(h * 0.5),
      ),
      Paint()
        ..color = kTongueDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Center crease
    canvas.drawLine(
      Offset(w / 2, h * 0.18),
      Offset(w / 2, h * 0.82),
      Paint()
        ..color = kTongueDark
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Taste buds
    final budPaint = Paint()..color = kTongueDark;
    for (final bud in [
      [0.22, 0.35],
      [0.5, 0.28],
      [0.78, 0.35],
      [0.33, 0.68],
      [0.67, 0.68],
    ]) {
      canvas.drawCircle(Offset(w * bud[0], h * bud[1]), 2.2, budPaint);
    }

    // Shine
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.32, h * 0.3),
        width: w * 0.22,
        height: h * 0.22,
      ),
      Paint()..color = const Color(0x55FFFFFF),
    );
  }
}
