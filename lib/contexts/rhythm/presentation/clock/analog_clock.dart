import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A quiet watch face: a recessed dial, short hour bars, round-capped hands
/// and an accent second hand. Faces large enough to read them also mark the
/// minutes; small faces draw heavier hands instead.
final class AnalogClock extends StatelessWidget {
  const AnalogClock({required this.now, this.size = 200, super.key});

  /// Faces at least this large mark every minute.
  static const double minuteMarkMinimumSize = 160;

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
              detailed: size >= minuteMarkMinimumSize,
              face: Color.lerp(
                theme.scaffoldBackgroundColor,
                colors.surface,
                0.5,
              )!,
              rim: colors.outlineVariant,
              minuteMark: colors.outline,
              hourMark: colors.onSurfaceVariant,
              hand: colors.onSurface,
              second: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints in a 200-unit design space scaled to the face size.
final class _AnalogClockPainter extends CustomPainter {
  const _AnalogClockPainter({
    required this.now,
    required this.detailed,
    required this.face,
    required this.rim,
    required this.minuteMark,
    required this.hourMark,
    required this.hand,
    required this.second,
  });

  static const double _designSize = 200;

  final DateTime now;
  final bool detailed;
  final Color face;
  final Color rim;
  final Color minuteMark;
  final Color hourMark;
  final Color hand;
  final Color second;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = math.min(size.width, size.height) / _designSize;
    final Offset center = size.center(Offset.zero);
    canvas.drawCircle(center, 96 * unit, Paint()..color = face);
    canvas.drawCircle(
      center,
      96 * unit,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, unit),
    );

    if (detailed) {
      final Paint minutePaint = Paint()..color = minuteMark;
      for (int minute = 0; minute < 60; minute += 1) {
        if (minute % 5 != 0) {
          canvas.drawCircle(
            _point(center, 86 * unit, minute * math.pi / 30),
            0.9 * unit,
            minutePaint,
          );
        }
      }
    }
    final double hourMarkLength = detailed ? 3.5 : 4;
    final Paint hourPaint = Paint()
      ..color = hourMark
      ..strokeWidth = 1.4 * unit;
    for (int hour = 0; hour < 12; hour += 1) {
      final double angle = hour * math.pi / 6;
      canvas.drawLine(
        _point(center, (84 - hourMarkLength) * unit, angle),
        _point(center, (84 + hourMarkLength) * unit, angle),
        hourPaint,
      );
    }

    final double seconds = now.second + now.millisecond / 1000;
    final double minutes = now.minute + seconds / 60;
    final double hours = (now.hour % 12) + minutes / 60;
    _drawHand(
      canvas,
      center,
      angle: hours * math.pi / 6,
      from: -8 * unit,
      to: 46 * unit,
      width: (detailed ? 5 : 7) * unit,
      color: hand,
    );
    _drawHand(
      canvas,
      center,
      angle: minutes * math.pi / 30,
      from: -10 * unit,
      to: 70 * unit,
      width: (detailed ? 3 : 4.5) * unit,
      color: hand,
    );
    _drawHand(
      canvas,
      center,
      angle: seconds * math.pi / 30,
      from: -18 * unit,
      to: 76 * unit,
      width: math.max(1, (detailed ? 1.5 : 2.5) * unit),
      color: second,
    );
    canvas.drawCircle(
      center,
      (detailed ? 4 : 6) * unit,
      Paint()..color = second,
    );
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
    required double from,
    required double to,
    required double width,
    required Color color,
  }) {
    canvas.drawLine(
      _point(center, from, angle),
      _point(center, to, angle),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AnalogClockPainter oldDelegate) {
    return now != oldDelegate.now ||
        detailed != oldDelegate.detailed ||
        face != oldDelegate.face ||
        rim != oldDelegate.rim ||
        minuteMark != oldDelegate.minuteMark ||
        hourMark != oldDelegate.hourMark ||
        hand != oldDelegate.hand ||
        second != oldDelegate.second;
  }
}
