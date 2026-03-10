import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticUtil {
  static bool? _hasVibrator;

  static Future<bool> _canVibrate() async {
    _hasVibrator ??= (await Vibration.hasVibrator()) ?? false;
    return _hasVibrator!;
  }

  /// Light tick when a tooth is successfully counted.
  static Future<void> countTick() async {
    await HapticFeedback.lightImpact();
  }

  /// Three-pulse chomp sensation when the baby bites.
  static Future<void> bite() async {
    await HapticFeedback.heavyImpact();
    try {
      if (await _canVibrate()) {
        Vibration.vibrate(pattern: [0, 90, 55, 90, 55, 130]);
      }
    } catch (_) {
      // Vibration unavailable — ignore.
    }
  }

  /// Soft rumble when the tongue slides in.
  static Future<void> tongueIn() async {
    await HapticFeedback.selectionClick();
    try {
      if (await _canVibrate()) {
        Vibration.vibrate(duration: 160);
      }
    } catch (_) {}
  }
}
