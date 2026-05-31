import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrangeRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color ringColor;

  OrangeRingPainter({
    required this.progress,
    required this.trackColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      ringPaint,
    );

    final dotAngle = -math.pi / 2 + sweepAngle;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);

    final dotOuterPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 7, dotOuterPaint);

    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 3.5, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant OrangeRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.ringColor != ringColor;
  }
}
