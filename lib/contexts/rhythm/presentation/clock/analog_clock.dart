import 'dart:math' as math;

import 'package:flutter/material.dart';

final class AnalogClock extends StatelessWidget {
  const AnalogClock({required this.now, this.size = 260, super.key});

  final DateTime now;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: RepaintBoundary(
        key: const ValueKey<String>('analog-clock-repaint-boundary'),
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _AnalogClockPainter(
              now: now,
              face: colors.surface,
              tick: colors.onSurface,
              hourMinute: colors.primary,
              second: colors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

final class _AnalogClockPainter extends CustomPainter {
  const _AnalogClockPainter({
    required this.now,
    required this.face,
    required this.tick,
    required this.hourMinute,
    required this.second,
  });

  final DateTime now;
  final Color face;
  final Color tick;
  final Color hourMinute;
  final Color second;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2;
    canvas.drawCircle(center, radius, Paint()..color = face);

    final Paint tickPaint = Paint()
      ..color = tick
      ..strokeCap = StrokeCap.round;
    for (int index = 0; index < 60; index += 1) {
      final double angle = index * math.pi / 30;
      final bool hourTick = index % 5 == 0;
      tickPaint.strokeWidth = hourTick ? 3 : 1;
      final double outerRadius = radius * 0.9;
      final double innerRadius = radius * (hourTick ? 0.78 : 0.84);
      canvas.drawLine(
        _point(center, innerRadius, angle),
        _point(center, outerRadius, angle),
        tickPaint,
      );
    }

    final double seconds = now.second + now.millisecond / 1000;
    final double minutes = now.minute + seconds / 60;
    final double hours = (now.hour % 12) + minutes / 60;
    _drawHand(
      canvas,
      center,
      angle: hours * math.pi / 6,
      length: radius * 0.48,
      width: 7,
      color: hourMinute,
    );
    _drawHand(
      canvas,
      center,
      angle: minutes * math.pi / 30,
      length: radius * 0.68,
      width: 5,
      color: hourMinute,
    );
    _drawHand(
      canvas,
      center,
      angle: seconds * math.pi / 30,
      length: radius * 0.76,
      width: 2,
      color: second,
    );
    canvas.drawCircle(center, 6, Paint()..color = second);
  }

  Offset _point(Offset center, double length, double angle) {
    return Offset(
      center.dx + math.sin(angle) * length,
      center.dy - math.cos(angle) * length,
    );
  }

  void _drawHand(
    Canvas canvas,
    Offset center, {
    required double angle,
    required double length,
    required double width,
    required Color color,
  }) {
    canvas.drawLine(
      center,
      _point(center, length, angle),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AnalogClockPainter oldDelegate) {
    return now != oldDelegate.now ||
        face != oldDelegate.face ||
        tick != oldDelegate.tick ||
        hourMinute != oldDelegate.hourMinute ||
        second != oldDelegate.second;
  }
}
