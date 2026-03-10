import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

/// Thin wrapper around FlameAudio. Gracefully degrades if audio files are
/// absent — place .mp3 files in assets/audio/ to enable sounds.
class AudioManager {
  bool _ready = false;

  static const _files = [
    'bite.mp3',
    'count_tick.mp3',
    'level_clear.mp3',
    'tongue_slurp.mp3',
    'squirm.mp3',
    'game_over.mp3',
    'button_tap.mp3',
  ];

  Future<void> preloadAll() async {
    // Fire-and-forget with a timeout — game works silently without audio files.
    unawaited(
      Future(() async {
        try {
          await FlameAudio.audioCache.loadAll(_files)
              .timeout(const Duration(seconds: 3));
          _ready = true;
        } catch (_) {
          _ready = false;
        }
      }),
    );
  }

  Future<void> playBite() => _play('bite.mp3');
  Future<void> playCountTick() => _play('count_tick.mp3');
  Future<void> playLevelClear() => _play('level_clear.mp3');
  Future<void> playTongueSlurp() => _play('tongue_slurp.mp3');
  Future<void> playSquirm() => _play('squirm.mp3');
  Future<void> playGameOver() => _play('game_over.mp3');
  Future<void> playButtonTap() => _play('button_tap.mp3');

  Future<void> _play(String filename) async {
    if (!_ready) return;
    try {
      await FlameAudio.play(filename);
    } catch (_) {}
  }
}
