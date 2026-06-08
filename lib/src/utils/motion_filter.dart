import 'math_utils.dart';

/// Separates gravity from linear acceleration and smooths the result.
///
/// A raw accelerometer reading is `gravity + userAcceleration + noise`. We
/// estimate gravity with a low-pass filter (it changes slowly relative to the
/// sampling rate) and subtract it to recover the user's real motion, then run
/// that through a second exponential smoother to remove high-frequency jitter.
class MotionFilter {
  MotionFilter({
    this.gravityFactor = 0.92,
    this.smoothingFactor = 0.78,
  })  : assert(gravityFactor >= 0 && gravityFactor < 1),
        assert(smoothingFactor >= 0 && smoothingFactor < 1);

  /// How strongly the gravity estimate resists change. Closer to 1 = slower,
  /// steadier gravity tracking.
  final double gravityFactor;

  /// How strongly the linear-acceleration output is smoothed. Closer to 1 =
  /// calmer cues but slightly more lag.
  final double smoothingFactor;

  Vector3 _gravity = const Vector3(0, 0, kStandardGravity);
  Vector3 _linear = const Vector3.zero();
  bool _seeded = false;

  /// Current low-pass gravity estimate.
  Vector3 get gravity => _gravity;

  /// Current smoothed linear acceleration.
  Vector3 get linearAcceleration => _linear;

  /// Feeds a raw accelerometer sample (m/s^2) and returns the smoothed linear
  /// acceleration with gravity removed.
  Vector3 addSample(Vector3 raw) {
    if (!_seeded) {
      // Seed gravity with the first reading so we do not start with a large
      // phantom acceleration spike while the filter converges.
      _gravity = raw;
      _seeded = true;
    } else {
      final a = gravityFactor;
      _gravity = _gravity * a + raw * (1 - a);
    }

    final instantaneousLinear = raw - _gravity;
    final s = smoothingFactor;
    _linear = _linear * s + instantaneousLinear * (1 - s);
    return _linear;
  }

  /// Resets the filter to its initial, unseeded state.
  void reset() {
    _gravity = const Vector3(0, 0, kStandardGravity);
    _linear = const Vector3.zero();
    _seeded = false;
  }
}

/// A scalar exponential smoother, handy for fading intensity values.
class ScalarSmoother {
  ScalarSmoother({this.factor = 0.85, double initial = 0})
      : assert(factor >= 0 && factor < 1),
        _value = initial;

  final double factor;
  double _value;

  double get value => _value;

  double add(double sample) {
    _value = _value * factor + sample * (1 - factor);
    return _value;
  }

  void reset([double value = 0]) => _value = value;
}
