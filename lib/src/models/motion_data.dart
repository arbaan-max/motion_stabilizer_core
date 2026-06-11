import 'dart:math' as math;

import '../utils/math_utils.dart';

/// An immutable snapshot of device motion at a single instant.
///
/// Raw accelerometer readings mix gravity with the user's real-world
/// acceleration. [MotionData] separates the two so the cue widgets can react to
/// genuine vehicle motion ([linearAcceleration]) while still knowing which way
/// is down ([gravity]).
class MotionData {
  const MotionData({
    required this.gravity,
    required this.linearAcceleration,
    required this.rotationRate,
    required this.timestamp,
  });

  /// A "device flat, perfectly still" reading.
  static const MotionData zero = MotionData(
    gravity: Vector3(0, 0, kStandardGravity),
    linearAcceleration: Vector3.zero(),
    rotationRate: Vector3.zero(),
    timestamp: Duration.zero,
  );

  /// Estimated gravity vector in m/s^2 (low-pass filtered accelerometer).
  final Vector3 gravity;

  /// Real-world linear acceleration in m/s^2, with gravity removed.
  final Vector3 linearAcceleration;

  /// Angular velocity from the gyroscope in rad/s. Zero when unavailable.
  final Vector3 rotationRate;

  /// Time since the controller started sampling.
  final Duration timestamp;

  /// Magnitude of the horizontal (screen-plane) acceleration in m/s^2.
  double get horizontalIntensity => math.sqrt(
    linearAcceleration.x * linearAcceleration.x +
        linearAcceleration.y * linearAcceleration.y,
  );

  /// Device roll in radians, derived from gravity (left/right tilt).
  ///
  /// `0` when the screen faces up; positive as the right edge dips down.
  double get roll => math.atan2(gravity.x, gravity.z);

  /// Device pitch in radians, derived from gravity (front/back tilt).
  double get pitch => math.atan2(
    gravity.y,
    math.sqrt(gravity.x * gravity.x + gravity.z * gravity.z),
  );

  MotionData copyWith({
    Vector3? gravity,
    Vector3? linearAcceleration,
    Vector3? rotationRate,
    Duration? timestamp,
  }) {
    return MotionData(
      gravity: gravity ?? this.gravity,
      linearAcceleration: linearAcceleration ?? this.linearAcceleration,
      rotationRate: rotationRate ?? this.rotationRate,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() =>
      'MotionData(linear: $linearAcceleration, gravity: $gravity, '
      'rotation: $rotationRate)';
}
