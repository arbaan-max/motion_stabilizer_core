import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../models/motion_data.dart';
import '../utils/math_utils.dart';
import '../utils/motion_filter.dart';

/// Streams fused [MotionData] from the device accelerometer and gyroscope.
///
/// The accelerometer drives the emission rate; each accelerometer sample is run
/// through a [MotionFilter] to split gravity from linear acceleration, and the
/// most recent gyroscope reading is attached for rotation-aware cues.
class SensorService {
  SensorService({
    MotionFilter? filter,
    this.samplingPeriod = SensorInterval.gameInterval,
  }) : _filter = filter ?? MotionFilter();

  final MotionFilter _filter;

  /// Sensor sampling cadence. [SensorInterval.gameInterval] (~20 ms) is a good
  /// balance of responsiveness and battery for motion cues.
  final Duration samplingPeriod;

  final _controller = StreamController<MotionData>.broadcast();
  final _stopwatch = Stopwatch();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  Vector3 _latestRotation = const Vector3.zero();
  bool _running = false;

  /// Whether the service is currently subscribed to sensors.
  bool get isRunning => _running;

  /// Broadcast stream of fused motion samples.
  Stream<MotionData> get stream => _controller.stream;

  /// Begins listening to the device sensors. Safe to call repeatedly.
  void start() {
    if (_running) return;
    _running = true;
    _filter.reset();
    _stopwatch
      ..reset()
      ..start();

    _accelSub = accelerometerEventStream(
      samplingPeriod: samplingPeriod,
    ).listen(_onAccelerometer, onError: _onSensorError, cancelOnError: false);

    _gyroSub = gyroscopeEventStream(samplingPeriod: samplingPeriod).listen(
      (event) => _latestRotation = Vector3(event.x, event.y, event.z),
      onError: (_) => _latestRotation = const Vector3.zero(),
      cancelOnError: false,
    );
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final raw = Vector3(event.x, event.y, event.z);
    final linear = _filter.addSample(raw);
    _controller.add(
      MotionData(
        gravity: _filter.gravity,
        linearAcceleration: linear,
        rotationRate: _latestRotation,
        timestamp: _stopwatch.elapsed,
      ),
    );
  }

  void _onSensorError(Object error, StackTrace stackTrace) {
    // A device may lack a sensor; surface the error to listeners without
    // tearing the stream down.
    if (!_controller.isClosed) {
      _controller.addError(error, stackTrace);
    }
  }

  /// Stops listening but keeps the stream open for a later [start].
  void stop() {
    if (!_running) return;
    _running = false;
    _stopwatch.stop();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
  }

  /// Permanently disposes the service and closes the stream.
  Future<void> dispose() async {
    stop();
    await _controller.close();
  }
}
