/// Tracks how long each tooth has been held down.
/// Returns indices of teeth that triggered a bite this frame.
/// Intentionally has no Flame dependency — pure logic class.
class BiteSystem {
  final Map<int, double> _holdTimers = {};
  double biteThreshold;

  BiteSystem({required this.biteThreshold});

  void startHold(int toothIndex) {
    _holdTimers[toothIndex] = 0.0;
  }

  void cancelHold(int toothIndex) {
    _holdTimers.remove(toothIndex);
  }

  void cancelAll() {
    _holdTimers.clear();
  }

  bool get hasActiveHolds => _holdTimers.isNotEmpty;

  /// Call from the game's update loop. Returns indices of teeth that bit.
  List<int> update(double dt) {
    final biters = <int>[];
    for (final key in _holdTimers.keys.toList()) {
      final newTime = (_holdTimers[key] ?? 0) + dt;
      if (newTime >= biteThreshold) {
        _holdTimers.remove(key);
        biters.add(key);
      } else {
        _holdTimers[key] = newTime;
      }
    }
    return biters;
  }

  void updateThreshold(double newThreshold) {
    biteThreshold = newThreshold;
  }
}
