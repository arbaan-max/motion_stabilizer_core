import 'package:flutter_test/flutter_test.dart';
import 'package:motion_stabilizer_core/motion_stabilizer_core.dart';
import 'package:motion_stabilizer_core/src/utils/math_utils.dart';
import 'package:motion_stabilizer_core/src/utils/motion_filter.dart';

void main() {
  group('MotionFilter', () {
    test('removes gravity from a steady reading', () {
      final filter = MotionFilter();
      // Phone lying flat: ~9.81 m/s^2 on Z, nothing else.
      const gravityOnly = Vector3(0, 0, kStandardGravity);
      var linear = filter.addSample(gravityOnly);
      for (var i = 0; i < 50; i++) {
        linear = filter.addSample(gravityOnly);
      }
      expect(linear.length, lessThan(0.05));
      expect(filter.gravity.z, closeTo(kStandardGravity, 0.1));
    });

    test('reports a transient acceleration spike', () {
      final filter = MotionFilter();
      const rest = Vector3(0, 0, kStandardGravity);
      filter.addSample(rest);
      // A forward jolt on X.
      final linear = filter.addSample(const Vector3(6, 0, kStandardGravity));
      expect(linear.x.abs(), greaterThan(0.1));
    });
  });

  group('math_utils', () {
    test('deadZone suppresses small values', () {
      expect(deadZone(0.2, 0.5), 0);
      expect(deadZone(0.8, 0.5), closeTo(0.3, 1e-9));
      expect(deadZone(-0.8, 0.5), closeTo(-0.3, 1e-9));
    });

    test('mapRange clamps to the output range', () {
      expect(mapRange(5, 0, 10, 0, 1), 0.5);
      expect(mapRange(-5, 0, 10, 0, 1), 0);
      expect(mapRange(50, 0, 10, 0, 1), 1);
    });
  });

  group('MotionCueConfig', () {
    test('round-trips through a map', () {
      const config = MotionCueConfig(
        gain: 20,
        placement: CuePlacement.center,
        dotShape: DotShape.diamond,
        dotSizeJitter: 0.4,
        dotReactToMotionOpacity: false,
        dotGlow: true,
        invertY: true,
        showDots: false,
        dividerStyle: DividerStyle.filledHorizon,
        waveAnimated: false,
        waveReactsToMotion: false,
        horizonStabilization: 0.95,
        showFocusDot: true,
      );
      final restored = MotionCueConfig.fromMap(config.toMap());
      expect(restored.gain, config.gain);
      expect(restored.placement, CuePlacement.center);
      expect(restored.dotShape, DotShape.diamond);
      expect(restored.dotSizeJitter, 0.4);
      expect(restored.dotReactToMotionOpacity, isFalse);
      expect(restored.dotGlow, isTrue);
      expect(restored.invertY, isTrue);
      expect(restored.showDots, isFalse);
      expect(restored.dividerStyle, DividerStyle.filledHorizon);
      expect(restored.waveAnimated, isFalse);
      expect(restored.waveReactsToMotion, isFalse);
      expect(restored.horizonStabilization, 0.95);
      expect(restored.showFocusDot, isTrue);
    });

    test('presets carry their intent', () {
      expect(const MotionCueConfig.calmHorizon().showDots, isFalse);
      expect(const MotionCueConfig.intense().placement,
          CuePlacement.fullScreen);
      expect(const MotionCueConfig.gentle().dividerStyle, DividerStyle.line);
    });
  });
}
