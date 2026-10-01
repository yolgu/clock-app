import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A watch face in the manner of Apple's Clock: numerals, fine minute
/// ticks, two-stage hour and minute hands and a slim accent second hand.
final class AnalogClock extends StatelessWidget {
  const AnalogClock({required this.now, this.size = 260, super.key});

  final DateTime now;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return ExcludeSemantics(
      child: RepaintBoundary(
        key: const ValueKey<String>('analog-clock-repaint-boundary'),
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _AnalogClockPainter(
              now: now,
              face: colors.surfaceContainerLowest,
              rim: colors.outlineVariant,
              tick: colors.onSurface,
              minorTick: colors.onSurfaceVariant,
              hand: colors.onSurface,
              second: colors.error,
              numeralStyle:
                  theme.textTheme.titleMedium ?? const TextStyle(fontSize: 17),
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
    required this.rim,
    required this.tick,
    required this.minorTick,
    required this.hand,
    required this.second,
    required this.numeralStyle,
  });

  final DateTime now;
  final Color face;
  final Color rim;
  final Color tick;
  final Color minorTick;
  final Color hand;
  final Color second;
  final TextStyle numeralStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2;
    canvas.drawCircle(center, radius, Paint()..color = face);
    canvas.drawCircle(
      center,
      radius - 0.75,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final Paint tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (int index = 0; index < 60; index += 1) {
      final double angle = index * math.pi / 30;
      final bool hourTick = index % 5 == 0;
      tickPaint
        ..color = hourTick ? tick : minorTick.withValues(alpha: 0.7)
        ..strokeWidth = hourTick ? radius * 0.018 : radius * 0.008;
      final double outerRadius = radius * 0.94;
      final double innerRadius = radius * (hourTick ? 0.86 : 0.9);
      canvas.drawLine(
        _point(center, innerRadius, angle),
        _point(center, outerRadius, angle),
        tickPaint,
      );
    }

    final TextStyle numerals = numeralStyle.copyWith(
      color: tick,
      fontSize: radius * 0.17,
      height: 1,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    for (int hour = 1; hour <= 12; hour += 1) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: '$hour', style: numerals),
        textDirection: TextDirection.ltr,
      )..layout();
      final Offset anchor = _point(center, radius * 0.71, hour * math.pi / 6);
      painter.paint(
        canvas,
        anchor - Offset(painter.width / 2, painter.height / 2),
      );
      painter.dispose();
    }

    final double seconds = now.second + now.millisecond / 1000;
    final double minutes = now.minute + seconds / 60;
    final double hours = (now.hour % 12) + minutes / 60;
    _drawHand(
      canvas,
      center,
      angle: hours * math.pi / 6,
      length: radius * 0.5,
      width: radius * 0.05,
      radius: radius,
    );
    _drawHand(
      canvas,
      center,
      angle: minutes * math.pi / 30,
      length: radius * 0.8,
      width: radius * 0.05,
      radius: radius,
    );
    canvas.drawCircle(center, radius * 0.045, Paint()..color = hand);

    final double secondAngle = seconds * math.pi / 30;
    canvas.drawLine(
      _point(center, -radius * 0.16, secondAngle),
      _point(center, radius * 0.88, secondAngle),
      Paint()
        ..color = second
        ..strokeWidth = math.max(1.2, radius * 0.012)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, radius * 0.032, Paint()..color = second);
    canvas.drawCircle(center, radius * 0.012, Paint()..color = face);
  }

  Offset _point(Offset center, double length, double angle) {
    return Offset(
      center.dx + math.sin(angle) * length,
      center.dy - math.cos(angle) * length,
    );
  }

  /// A thin stem leaving the hub, then a broad rounded blade.
  void _drawHand(
    Canvas canvas,
    Offset center, {
    required double angle,
    required double length,
    required double width,
    required double radius,
  }) {
    final double stem = radius * 0.12;
    canvas.drawLine(
      center,
      _point(center, stem, angle),
      Paint()
        ..color = hand
        ..strokeWidth = math.max(1.5, width * 0.4)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      _point(center, stem, angle),
      _point(center, length, angle),
      Paint()
        ..color = hand
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AnalogClockPainter oldDelegate) {
    return now != oldDelegate.now ||
        face != oldDelegate.face ||
        rim != oldDelegate.rim ||
        tick != oldDelegate.tick ||
        minorTick != oldDelegate.minorTick ||
        hand != oldDelegate.hand ||
        second != oldDelegate.second ||
        numeralStyle != oldDelegate.numeralStyle;
  }
}
