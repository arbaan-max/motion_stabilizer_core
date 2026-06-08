import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/motion_cue_config.dart';

/// Paints the Earth-stable reference ("horizon" / divider) in any
/// [DividerStyle].
///
/// The figure is shifted by [pitch] and, when
/// [MotionCueConfig.levelWithHorizon] is set, counter-rotated by [roll] (use the
/// controller's *stabilized* angles to avoid shake-induced spin). [phase]
/// (seconds × speed) drives the flow; [intensity] and [flow] let the wave react
/// to device motion.
class MotionDividerPainter extends CustomPainter {
  MotionDividerPainter({
    required this.config,
    required this.roll,
    required this.pitch,
    required this.phase,
    this.intensity = 0,
    this.flow = Offset.zero,
  });

  final MotionCueConfig config;
  final double roll;
  final double pitch;
  final double phase;
  final double intensity;
  final Offset flow;

  @override
  void paint(Canvas canvas, Size size) {
    if (config.dividerStyle == DividerStyle.none) return;
    if (config.dividerOpacity <= 0.01) return;

    final center = Offset(size.width / 2, size.height / 2);
    final pitchShift = (pitch / (math.pi / 2)) * (size.height / 4);

    canvas.save();
    canvas.translate(center.dx, center.dy + pitchShift);
    if (config.levelWithHorizon) canvas.rotate(-roll);

    final half = size.longestSide;

    switch (config.dividerStyle) {
      case DividerStyle.none:
        break;
      case DividerStyle.line:
        _drawLine(canvas, half);
      case DividerStyle.dashed:
        _drawDashed(canvas, half);
      case DividerStyle.wavy:
        _drawWavy(canvas, half, fill: false);
      case DividerStyle.filledHorizon:
        _drawWavy(canvas, half, fill: true);
      case DividerStyle.dualRail:
        _drawDualRail(canvas, half);
      case DividerStyle.gradientBand:
        _drawGradientBand(canvas, half);
    }

    canvas.restore();
  }

  Color get _lineColor => config.dividerColor
      .withValues(alpha: config.dividerColor.a * config.dividerOpacity);

  Paint get _stroke => Paint()
    ..color = _lineColor
    ..strokeWidth = config.dividerThickness
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  void _drawLine(Canvas canvas, double half) {
    final glow = Paint()
      ..color = _lineColor.withValues(alpha: _lineColor.a * 0.4)
      ..strokeWidth = config.dividerThickness * 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(Offset(-half, 0), Offset(half, 0), glow);
    canvas.drawLine(Offset(-half, 0), Offset(half, 0), _stroke);
    _drawCentreTick(canvas);
  }

  void _drawDashed(Canvas canvas, double half) {
    const dash = 16.0;
    const gap = 12.0;
    final paint = _stroke;
    var x = -half;
    while (x < half) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
    _drawCentreTick(canvas);
  }

  /// Sampled height of the flowing surface at horizontal position [x].
  ///
  /// Two counter-travelling harmonics give a water-flow look rather than a
  /// clean sine; motion (when enabled) swells the amplitude and adds sway/bob.
  double _waveY(double x, double amp, double wl) {
    final reacts = config.waveReactsToMotion;
    final p = config.waveAnimated ? phase * 2 * math.pi : 0.0;
    final sway = reacts ? flow.dx * 0.04 : 0.0;
    final bob = reacts ? flow.dy * 0.35 : 0.0;
    final a = reacts ? amp * (1 + intensity * 1.5) : amp;
    final primary = math.sin((x / wl) * 2 * math.pi + p + sway) * a;
    final ripple = math.sin((x / (wl * 0.5)) * 2 * math.pi - p * 1.7) * a * 0.45;
    return primary + ripple + bob;
  }

  void _drawWavy(Canvas canvas, double half, {required bool fill}) {
    final amp = fill ? math.min(config.waveAmplitude, 9.0) : config.waveAmplitude;
    final wl = config.waveWavelength <= 0 ? 140.0 : config.waveWavelength;
    final path = Path();
    const step = 5.0;
    var first = true;
    for (var x = -half; x <= half; x += step) {
      final y = _waveY(x, amp, wl);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(half, half)
        ..lineTo(-half, half)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = config.horizonFillColor.withValues(
              alpha: config.horizonFillColor.a * config.dividerOpacity)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(path, _stroke);
  }

  void _drawDualRail(Canvas canvas, double half) {
    final paint = _stroke;
    final h = half;
    const nearGap = 0.32;
    const farGap = 0.06;
    final leftRail = Path()
      ..moveTo(-h * nearGap, h)
      ..lineTo(-h * farGap, -h);
    final rightRail = Path()
      ..moveTo(h * nearGap, h)
      ..lineTo(h * farGap, -h);
    canvas.drawPath(leftRail, paint);
    canvas.drawPath(rightRail, paint);
    for (var i = 1; i <= 4; i++) {
      final t = i / 5.0;
      final y = h - t * 2 * h;
      final gap = (nearGap + (farGap - nearGap) * t) * h;
      canvas.drawLine(
        Offset(-gap, y),
        Offset(gap, y),
        paint..strokeWidth = config.dividerThickness * (1 - t * 0.6),
      );
    }
  }

  void _drawGradientBand(Canvas canvas, double half) {
    final bandHalf = math.max(config.waveAmplitude * 4, 48.0);
    final rect = Rect.fromLTRB(-half, -bandHalf, half, bandHalf);
    final base = config.dividerColor
        .withValues(alpha: config.dividerColor.a * config.dividerOpacity);
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [base.withValues(alpha: 0), base, base.withValues(alpha: 0)],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shader);
    canvas.drawLine(Offset(-half, 0), Offset(half, 0), _stroke);
  }

  void _drawCentreTick(Canvas canvas) {
    canvas.drawLine(const Offset(0, -8), const Offset(0, 8), _stroke);
  }

  @override
  bool shouldRepaint(covariant MotionDividerPainter old) =>
      old.roll != roll ||
      old.pitch != pitch ||
      old.phase != phase ||
      old.intensity != intensity ||
      old.flow != flow ||
      old.config != config;
}
