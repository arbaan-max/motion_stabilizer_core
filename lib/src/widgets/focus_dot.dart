import 'package:flutter/widgets.dart';

import '../controllers/motion_controller.dart';

/// A central fixation dot that counter-moves against device motion.
///
/// Staring at a stable point is a classic motion-sickness remedy. This dot
/// nudges *into* the motion offset so it appears pinned to the world rather
/// than to the shaking screen, giving the eyes something steady to fixate on.
class FocusDot extends StatelessWidget {
  const FocusDot({
    super.key,
    required this.controller,
    this.color = const Color(0xFFFFFFFF),
    this.radius = 6.0,
    this.haloRadius = 18.0,
    this.haloColor = const Color(0x33FFFFFF),
  });

  final MotionController controller;
  final Color color;
  final double radius;

  /// Radius of the soft halo drawn behind the dot. Set to `<= radius` to hide.
  final double haloRadius;
  final Color haloColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // Counter-move: shift opposite the dot field so the focus point
            // tracks the world.
            final shift = -controller.offset;
            return Transform.translate(
              offset: shift,
              child: CustomPaint(
                size: Size.square(haloRadius * 2),
                painter: _FocusDotPainter(
                  color: color,
                  radius: radius,
                  haloRadius: haloRadius,
                  haloColor: haloColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FocusDotPainter extends CustomPainter {
  _FocusDotPainter({
    required this.color,
    required this.radius,
    required this.haloRadius,
    required this.haloColor,
  });

  final Color color;
  final double radius;
  final double haloRadius;
  final Color haloColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (haloRadius > radius) {
      canvas.drawCircle(
        center,
        haloRadius,
        Paint()..color = haloColor,
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FocusDotPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.haloRadius != haloRadius ||
      old.haloColor != haloColor;
}
