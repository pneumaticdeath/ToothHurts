import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/difficulty_config.dart';
import '../../utils/constants.dart';
import 'baby_type.dart';
import 'foot_component.dart';
import 'pacifier_component.dart';
import 'throw_up_component.dart';
import 'tongue_component.dart';
import 'tooth_component.dart';

/// The baby's open mouth.
///
/// - Draws the dark mouth cavity and gum line.
/// - Clips all children to the mouth bounds.
/// - Owns permanent complications: tongue, throw-up, pacifier, foot.
/// - Teeth are spawned/cleared per round.
class MouthComponent extends PositionComponent {
  late final TongueComponent tongue;
  ThrowUpComponent? throwUp;
  PacifierComponent? pacifier;
  FootComponent? foot;

  final BabyType babyType;

  MouthComponent({this.babyType = BabyType.human})
      : super(
          position: Vector2(kMouthLocalX, kMouthLocalY),
          size: Vector2(kMouthWidth, kMouthHeight),
          anchor: Anchor.topLeft,
        );

  @override
  Future<void> onLoad() async {
    tongue = TongueComponent(mouthHeight: size.y);
    await add(tongue);
  }

  // ── Round management ───────────────────────────────────────────────────────

  Future<void> spawnTeeth(DifficultyConfig diff) async {
    // Remove teeth from previous round
    children.whereType<ToothComponent>().toList().forEach((t) => t.removeFromParent());

    // Add/remove complications based on difficulty
    await _syncComplications(diff);

    final bottomCount = diff.bottomTeethCount;
    final topCount = diff.topTeethCount;

    for (final t in _buildTeethRow(count: bottomCount, yPos: size.y - kToothHeight, startIndex: 0)) {
      await add(t);
    }
    for (final t in _buildTeethRow(count: topCount, yPos: 0, startIndex: bottomCount, flipY: true)) {
      await add(t);
    }

    // Tongue always on top — re-add so Z-order is correct after teeth
    tongue.removeFromParent();
    await add(tongue);

    // Complications on top of tongue
    if (throwUp != null) {
      throwUp!.removeFromParent();
      await add(throwUp!);
    }
    if (pacifier != null) {
      pacifier!.removeFromParent();
      await add(pacifier!);
    }
    if (foot != null) {
      foot!.removeFromParent();
      await add(foot!);
    }
  }

  Future<void> _syncComplications(DifficultyConfig diff) async {
    if (diff.hasThrowUp && throwUp == null) {
      throwUp = ThrowUpComponent();
      await add(throwUp!);
    } else if (!diff.hasThrowUp && throwUp != null) {
      throwUp!.removeFromParent();
      throwUp = null;
    }

    if (diff.hasPacifier && pacifier == null) {
      pacifier = PacifierComponent();
      await add(pacifier!);
    } else if (!diff.hasPacifier && pacifier != null) {
      pacifier!.removeFromParent();
      pacifier = null;
    }

    if (diff.hasFoot && foot == null) {
      foot = FootComponent();
      await add(foot!);
    } else if (!diff.hasFoot && foot != null) {
      foot!.removeFromParent();
      foot = null;
    }
  }

  List<ToothComponent> _buildTeethRow({
    required int count,
    required double yPos,
    required int startIndex,
    bool flipY = false,
  }) {
    if (count == 0) return [];

    // Scale tooth width down for alligator/fish or any case that would overflow
    const gap = kToothGap;
    final rawWidth = count * kToothWidth + (count - 1) * gap;
    final toothW = rawWidth > size.x
        ? ((size.x - (count - 1) * gap) / count).clamp(4.0, kToothWidth)
        : kToothWidth;

    final totalWidth = count * toothW + (count - 1) * gap;
    final startX = (size.x - totalWidth) / 2 + toothW / 2;

    return List.generate(count, (i) {
      final tooth = ToothComponent(
        index: startIndex + i,
        position: Vector2(startX + i * (toothW + gap), yPos),
        toothWidth: toothW,
        sharp: babyType == BabyType.alligator,
        fishy: babyType == BabyType.fish,
        flipped: flipY,
      );
      if (flipY) {
        tooth.scale = Vector2(1, -1);
        tooth.position.y = kToothHeight;
      }
      return tooth;
    });
  }

  List<ToothComponent> get teeth =>
      children.whereType<ToothComponent>().toList();

  void resetAllTeeth() {
    for (final tooth in teeth) {
      tooth.isCounted = false;
    }
  }

  // ── Rendering ──────────────────────────────────────────────────────────────

  @override
  void renderTree(Canvas canvas) {
    canvas.save();
    // Translate into this component's local space BEFORE clipping.
    // clipRRect must be in local space or it clips at the wrong position.
    canvas.translate(position.x, position.y);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: const Radius.circular(22),
      bottomRight: const Radius.circular(22),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    canvas.clipRRect(rrect);
    render(canvas);
    for (final child in children) {
      child.renderTree(canvas);
    }
    canvas.restore();
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Mouth cavity — color varies by baby type
    final mouthColor = _mouthColor;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: const Radius.circular(22),
      bottomRight: const Radius.circular(22),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    canvas.drawRRect(rrect, Paint()..color = mouthColor);

    // Gum strips
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 7), Paint()..color = _gumColor);
    canvas.drawRect(Rect.fromLTWH(0, h - 7, w, 7), Paint()..color = _gumColor);

    // Inner shadow
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 8),
    );
  }

  Color get _mouthColor {
    switch (babyType) {
      case BabyType.alligator:
        return const Color(0xFF1A2E00); // very dark green
      case BabyType.fish:
        return const Color(0xFF001A3A); // deep ocean blue-black
      case BabyType.human:
        return kMouthColor;
    }
  }

  Color get _gumColor {
    switch (babyType) {
      case BabyType.alligator:
        return const Color(0xFF4A7A00);
      case BabyType.fish:
        return const Color(0xFF003366);
      case BabyType.human:
        return kGumDark;
    }
  }
}
