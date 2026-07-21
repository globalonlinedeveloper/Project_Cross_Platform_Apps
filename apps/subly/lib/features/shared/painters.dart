import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Segmented donut (category breakdown). Draws a ring; the caller stacks the
/// centre label on top.
class DonutPainter extends CustomPainter {
  DonutPainter({required this.segments, this.stroke = 19});

  /// (value, color) pairs. Values need not be normalized.
  final List<MapEntry<double, Color>> segments;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final double total =
        segments.fold(0.0, (double a, MapEntry<double, Color> s) => a + s.key);
    if (total <= 0) return;

    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    double start = -math.pi / 2;
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    for (final MapEntry<double, Color> seg in segments) {
      final double sweep = seg.key / total * 2 * math.pi;
      p.color = seg.value;
      canvas.drawArc(rect, start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) =>
      old.segments != segments || old.stroke != stroke;
}

/// Progress ring for the budget gauge.
class RingPainter extends CustomPainter {
  RingPainter({
    required this.progress,
    required this.color,
    this.track = AppColors.line,
    this.stroke = 22,
  });

  final double progress; // 0..1
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, base);

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
        rect, -math.pi / 2, progress.clamp(0, 1) * 2 * math.pi, false, arc);
  }

  @override
  bool shouldRepaint(covariant RingPainter old) =>
      old.progress != progress || old.color != color;
}
