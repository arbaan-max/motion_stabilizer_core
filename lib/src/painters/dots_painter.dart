import 'package:flutter/widgets.dart';

import '../models/motion_cue_config.dart';

/// Paints the field of motion-cue dots ("bubbles").
///
/// Dots are laid out on a fixed grid determined by [MotionCueConfig.placement]
/// and [MotionCueConfig.dotSpacing], then translated by [offset] and faded by
/// [opacity]. Because the grid is fixed and only the translation animates, the
/// dots read as a single rigid "world" sliding behind the screen — the visual
/// signal that reduces the sensory conflict behind motion sickness.
///
/// Shape, per-bubble size jitter and glow come from [config].
class DotsPainter extends CustomPainter {
  DotsPainter({
    required this.config,
    required this.offset,
    required this.opacity,
  });

  final MotionCueConfig config;
  final Offset offset;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    final paint = Paint()
      ..color = config.dotColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final ring = config.dotShape == DotShape.ring;
    if (ring) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.dotRadius * 0.45;
    }

    final glowPaint = config.dotGlow
        ? (Paint()
          ..color = config.dotColor.withValues(alpha: opacity * 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.dotRadius))
        : null;

    final spacing = config.dotSpacing;
    final radius = config.dotRadius;

    final cols = (size.width / spacing).ceil() + 2;
    final rows = (size.height / spacing).ceil() + 2;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final base = Offset(
          (c - 1) * spacing + spacing / 2,
          (r - 1) * spacing + spacing / 2,
        );
        if (!_isVisible(base, size)) continue;

        final rr = radius * _sizeFactor(r, c);
        final centre = base + offset;
        if (glowPaint != null) {
          canvas.drawCircle(centre, rr * 1.2, glowPaint);
        }
        _drawShape(canvas, centre, rr, paint);
      }
    }
  }

  void _drawShape(Canvas canvas, Offset c, double r, Paint paint) {
    switch (config.dotShape) {
      case DotShape.circle:
      case DotShape.ring:
        canvas.drawCircle(c, r, paint);
      case DotShape.square:
        canvas.drawRect(Rect.fromCircle(center: c, radius: r), paint);
      case DotShape.diamond:
        final path = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r, c.dy)
          ..close();
        canvas.drawPath(path, paint);
    }
  }

  /// Deterministic per-cell size multiplier in `[1 - jitter, 1 + jitter]`.
  double _sizeFactor(int r, int c) {
    if (config.dotSizeJitter <= 0) return 1;
    // Stable integer hash → [0, 1).
    var h = (r * 73856093) ^ (c * 19349663);
    h &= 0x7fffffff;
    final unit = (h % 1000) / 1000.0;
    return 1 + (unit * 2 - 1) * config.dotSizeJitter;
  }

  /// Whether a dot at [base] should be drawn for the current placement.
  bool _isVisible(Offset base, Size size) {
    switch (config.placement) {
      case CuePlacement.fullScreen:
        return true;
      case CuePlacement.sides:
        final band = size.width * 0.22;
        return base.dx < band || base.dx > size.width - band;
      case CuePlacement.edges:
        final hBand = size.width * 0.22;
        final vBand = size.height * 0.16;
        final nearSide = base.dx < hBand || base.dx > size.width - hBand;
        final nearTopBottom =
            base.dy < vBand || base.dy > size.height - vBand;
        return nearSide || nearTopBottom;
      case CuePlacement.center:
        final dx = (base.dx - size.width / 2).abs();
        final dy = (base.dy - size.height / 2).abs();
        return dx < size.width * 0.3 && dy < size.height * 0.22;
    }
  }

  @override
  bool shouldRepaint(covariant DotsPainter old) =>
      old.offset != offset ||
      old.opacity != opacity ||
      old.config != config;
}
