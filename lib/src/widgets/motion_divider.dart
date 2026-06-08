import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../controllers/motion_controller.dart';
import '../models/motion_cue_config.dart';
import '../painters/divider_painter.dart';

/// A self-driving Earth-stable reference line in any [DividerStyle].
///
/// Drop it into a `Stack` (usually behind your content) to give riders a stable
/// horizon. It animates continuously via its own ticker, so wavy/filled styles
/// keep moving even when the device is still.
class MotionDivider extends StatefulWidget {
  const MotionDivider({
    super.key,
    required this.controller,
  });

  final MotionController controller;

  @override
  State<MotionDivider> createState() => _MotionDividerState();
}

class _MotionDividerState extends State<MotionDivider>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _phase = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final speed = widget.controller.config.waveSpeed;
      setState(() => _phase = elapsed.inMicroseconds / 1e6 * speed);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: MotionDividerPainter(
          config: c.config,
          roll: c.stableRoll,
          pitch: c.stablePitch,
          phase: _phase,
          intensity: c.intensity,
          flow: c.offset,
        ),
      ),
    );
  }
}
