import 'dart:math' as math;

/// A lightweight immutable 3D vector.
///
/// The package keeps its own tiny vector type so that consumers do not have to
/// pull in a heavier linear-algebra dependency just to read sensor data.
class Vector3 {
  const Vector3(this.x, this.y, this.z);

  const Vector3.zero() : x = 0, y = 0, z = 0;

  final double x;
  final double y;
  final double z;

  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);

  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);

  Vector3 operator *(double scalar) =>
      Vector3(x * scalar, y * scalar, z * scalar);

  /// Euclidean magnitude of the vector.
  double get length => math.sqrt(x * x + y * y + z * z);

  /// Squared magnitude — cheaper when only comparisons are needed.
  double get lengthSquared => x * x + y * y + z * z;

  /// Linear interpolation between [this] and [other] by [t] in `[0, 1]`.
  Vector3 lerp(Vector3 other, double t) => Vector3(
    x + (other.x - x) * t,
    y + (other.y - y) * t,
    z + (other.z - z) * t,
  );

  @override
  String toString() =>
      'Vector3(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, '
      '${z.toStringAsFixed(3)})';
}

/// Standard gravity in m/s^2.
const double kStandardGravity = 9.80665;

/// Clamps [value] into the inclusive range `[lower, upper]`.
double clampDouble(double value, double lower, double upper) {
  if (value < lower) return lower;
  if (value > upper) return upper;
  return value;
}

/// Linearly interpolates between [a] and [b] by [t].
double lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// Maps [value] from the range `[inMin, inMax]` to `[outMin, outMax]`.
///
/// The result is clamped to the output range so callers can use it directly to
/// drive opacity, scale or offset without worrying about overshoot.
double mapRange(
  double value,
  double inMin,
  double inMax,
  double outMin,
  double outMax,
) {
  if (inMax == inMin) return outMin;
  final t = clampDouble((value - inMin) / (inMax - inMin), 0, 1);
  return outMin + (outMax - outMin) * t;
}

/// A symmetric dead-zone: returns 0 while `|value| <= threshold`, otherwise the
/// portion of [value] beyond the threshold. Removes sensor jitter at rest.
double deadZone(double value, double threshold) {
  if (value.abs() <= threshold) return 0;
  return value > 0 ? value - threshold : value + threshold;
}
