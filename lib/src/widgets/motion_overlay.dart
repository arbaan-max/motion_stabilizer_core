import 'package:flutter/widgets.dart';

import '../controllers/motion_controller.dart';
import '../models/motion_cue_config.dart';
import '../painters/dots_painter.dart';
import 'focus_dot.dart';
import 'motion_divider.dart';

/// The in-app motion-cue layer. Composes — each piece toggled from
/// [MotionCueConfig] — the animated dot field, the Earth-stable divider and the
/// central focus dot, all driven by a [MotionController].
///
/// Place it above your content inside a `Stack`, or use [MotionStabilizer] to
/// wrap an entire subtree without managing the stack yourself.
class MotionOverlay extends StatelessWidget {
  const MotionOverlay({
    super.key,
    required this.controller,
    this.showFocusDot,
  });

  final MotionController controller;

  /// Optional override for [MotionCueConfig.showFocusDot]. When null, the value
  /// from the controller's config is used.
  final bool? showFocusDot;

  @override
  Widget build(BuildContext context) {
    final config = controller.config;
    final focusDot = showFocusDot ?? config.showFocusDot;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (config.dividerStyle != DividerStyle.none)
            MotionDivider(controller: controller),
          if (config.showDots)
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: DotsPainter(
                    config: controller.config,
                    offset: controller.offset,
                    opacity: _dotOpacity(controller),
                  ),
                );
              },
            ),
          if (focusDot)
            FocusDot(
              controller: controller,
              color: config.focusDotColor,
              radius: config.focusDotRadius,
              haloRadius: config.focusDotHaloRadius,
              haloColor: config.focusDotHaloColor,
            ),
        ],
      ),
    );
  }

  double _dotOpacity(MotionController c) {
    final cfg = c.config;
    if (!cfg.dotReactToMotionOpacity) return cfg.dotBaseOpacity;
    return cfg.dotBaseOpacity +
        (cfg.dotMaxOpacity - cfg.dotBaseOpacity) * c.intensity;
  }
}

/// Convenience wrapper that overlays motion cues on top of [child] and owns the
/// [MotionController] lifecycle.
///
/// ```dart
/// MotionStabilizer(
///   enabled: ridingInVehicle,
///   config: const MotionCueConfig.standard(),
///   child: MyApp(),
/// )
/// ```
class MotionStabilizer extends StatefulWidget {
  const MotionStabilizer({
    super.key,
    required this.child,
    this.enabled = true,
    this.config = const MotionCueConfig(),
    this.showFocusDot,
    this.controller,
  });

  final Widget child;

  /// When `false`, the cues are hidden and the sensors are released.
  final bool enabled;

  final MotionCueConfig config;

  /// Optional override for [MotionCueConfig.showFocusDot].
  final bool? showFocusDot;

  /// Provide your own controller to share it with other widgets. If omitted, a
  /// controller is created and disposed internally.
  final MotionController? controller;

  @override
  State<MotionStabilizer> createState() => _MotionStabilizerState();
}

class _MotionStabilizerState extends State<MotionStabilizer> {
  late MotionController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? MotionController(config: widget.config);
    _ownsController = widget.controller == null;
    if (widget.enabled) _controller.start();
  }

  @override
  void didUpdateWidget(covariant MotionStabilizer old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      if (_ownsController) _controller.dispose();
      _controller = widget.controller ?? MotionController(config: widget.config);
      _ownsController = widget.controller == null;
    }
    if (widget.config != _controller.config) {
      _controller.config = widget.config;
    }
    if (widget.enabled && !_controller.isRunning) {
      _controller.start();
    } else if (!widget.enabled && _controller.isRunning) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (widget.enabled)
          MotionOverlay(
            controller: _controller,
            showFocusDot: widget.showFocusDot,
          ),
      ],
    );
  }
}
