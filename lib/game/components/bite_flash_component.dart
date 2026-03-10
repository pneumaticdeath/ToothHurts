import 'dart:ui';

import 'package:flame/components.dart';

import '../../utils/constants.dart';

/// Full-screen red flash that plays when the baby bites.
/// Removes itself after the animation completes.
class BiteFlashComponent extends PositionComponent {
  double _alpha = 0.85;
  static const _fadeDuration = 0.55;
  double _elapsed = 0.0;

  BiteFlashComponent()
      : super(
          position: Vector2.zero(),
          size: Vector2(kDesignWidth, kDesignHeight),
          priority: 200,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _alpha = (0.85 * (1.0 - _elapsed / _fadeDuration)).clamp(0.0, 1.0);
    if (_elapsed >= _fadeDuration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = kBiteFlashColor.withOpacity(_alpha * kBiteFlashColor.opacity),
    );
  }
}
