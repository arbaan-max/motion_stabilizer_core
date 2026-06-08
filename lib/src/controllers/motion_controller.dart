import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../models/motion_cue_config.dart';
import '../models/motion_data.dart';
import '../services/sensor_service.dart';
import '../utils/math_utils.dart';
import '../utils/motion_filter.dart';

/// The reactive brain of the in-app cues.
///
/// Subscribes to a [SensorService], converts each [MotionData] sample into a
/// screen-space cue [offset], an [intensity] in `[0, 1]` and a horizon angle,
/// then notifies listeners. Widgets such as `MotionOverlay`, `FocusDot` and
/// `HorizonLine` rebuild from this single source of truth.
class MotionController extends ChangeNotifier {
  MotionController({
    MotionCueConfig config = const MotionCueConfig(),
    SensorService? sensorService,
  })  : _config = config,
        _sensorService = sensorService ?? SensorService(),
        _ownsSensorService = sensorService == null;

  final SensorService _sensorService;
  final bool _ownsSensorService;
  final ScalarSmoother _intensitySmoother = ScalarSmoother(factor: 0.8);

  MotionCueConfig _config;
  StreamSubscription<MotionData>? _sub;

  MotionData _latest = MotionData.zero;
  Offset _offset = Offset.zero;
  double _intensity = 0;
  double _stableRoll = 0;
  double _stablePitch = 0;
  bool _angleSeeded = false;

  /// The current configuration driving the cue maths.
  MotionCueConfig get config => _config;

  /// Most recent fused sensor sample.
  MotionData get motion => _latest;

  /// Screen-space displacement (logical pixels) the cue dots should move by.
  ///
  /// Points *opposite* to the device's acceleration so the dots appear to lag
  /// behind real-world motion, the way scenery does through a window.
  Offset get offset => _offset;

  /// Normalised motion strength in `[0, 1]`, suitable for driving opacity.
  double get intensity => _intensity;

  /// Raw device roll in radians.
  double get roll => _latest.roll;

  /// Raw device pitch in radians.
  double get pitch => _latest.pitch;

  /// Heavily-smoothed roll for the horizon — ignores quick shakes and only
  /// follows sustained tilt (see [MotionCueConfig.horizonStabilization]).
  double get stableRoll => _stableRoll;

  /// Heavily-smoothed pitch for the horizon.
  double get stablePitch => _stablePitch;

  /// Whether the underlying sensor stream is active.
  bool get isRunning => _sensorService.isRunning;

  /// Replaces the active configuration and recomputes derived values.
  set config(MotionCueConfig value) {
    if (value == _config) return;
    _config = value;
    _recompute(_latest);
    notifyListeners();
  }

  /// Begins sampling and emitting cue updates.
  void start() {
    if (_sub != null) return;
    _intensitySmoother.reset();
    _angleSeeded = false;
    _sub = _sensorService.stream.listen(
      _onSample,
      onError: (_) {/* keep cues at rest on sensor error */},
    );
    _sensorService.start();
  }

  /// Pauses sampling; the last offset/intensity are retained.
  void stop() {
    _sensorService.stop();
    _sub?.cancel();
    _sub = null;
  }

  void _onSample(MotionData data) {
    _recompute(data);
    notifyListeners();
  }

  void _recompute(MotionData data) {
    _latest = data;

    // Map device-frame linear acceleration into screen axes.
    var ax = data.linearAcceleration.x;
    var ay = data.linearAcceleration.y;
    if (_config.swapAxes) {
      final t = ax;
      ax = ay;
      ay = t;
    }
    if (_config.invertX) ax = -ax;
    if (_config.invertY) ay = -ay;

    // Dead-zone removes resting jitter; gain converts m/s^2 -> pixels.
    final threshold = _config.activationThreshold;
    final dx = deadZone(ax, threshold) * _config.gain;
    // Screen Y grows downward, so negate to make "forward" push dots down.
    final dy = -deadZone(ay, threshold) * _config.gain;

    final travel = _config.maxTravel;
    _offset = Offset(
      clampDouble(-dx, -travel, travel),
      clampDouble(-dy, -travel, travel),
    );

    final raw = mapRange(
      data.horizontalIntensity,
      _config.activationThreshold,
      _config.maxIntensity,
      0,
      1,
    );
    _intensity = _intensitySmoother.add(raw);

    // Heavily smooth the horizon angle so quick shakes don't rotate it; only
    // sustained tilt gets through.
    final s = clampDouble(_config.horizonStabilization, 0, 0.99);
    if (!_angleSeeded) {
      _stableRoll = data.roll;
      _stablePitch = data.pitch;
      _angleSeeded = true;
    } else {
      _stableRoll = _stableRoll * s + data.roll * (1 - s);
      _stablePitch = _stablePitch * s + data.pitch * (1 - s);
    }
  }

  @override
  void dispose() {
    stop();
    if (_ownsSensorService) {
      // Fire-and-forget close of the service we created.
      unawaited(_sensorService.dispose());
    }
    super.dispose();
  }
}
