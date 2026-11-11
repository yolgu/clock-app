import 'package:flutter/material.dart';

/// The app's glyph set: thin round-capped line drawings on a 24-unit grid,
/// written as SVG path data so they stay identical to the design source.
enum LineGlyph {
  clock(<_Shape>[_Circle(12, 12, 9), _Line('M12 7v5l3 2')]),
  calendar(<_Shape>[_Box(3.5, 5, 17, 15, 2), _Line('M3.5 10h17M8 3v4M16 3v4')]),
  folder(<_Shape>[
    _Line(
      'M3.5 7a2 2 0 0 1 2-2h4l2 2h7a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-13'
      'a2 2 0 0 1-2-2z',
    ),
  ]),
  palette(<_Shape>[
    _Line(
      'M12 3.5a8.5 8.5 0 1 0 0 17c1.1 0 1.6-.8 1.6-1.6 0-1.2-1-1.4-1-2.5 '
      '0-.9.7-1.4 1.6-1.4h2.1a4.2 4.2 0 0 0 4.2-4.2C20.5 6.6 16.7 3.5 12 '
      '3.5z',
    ),
    _Circle(7.5, 11, 1),
    _Circle(10.5, 7.5, 1),
    _Circle(15, 8, 1),
  ]),
  sliders(<_Shape>[
    _Line('M4 7h10M18 7h2M4 17h4M12 17h8'),
    _Circle(16, 7, 2),
    _Circle(10, 17, 2),
  ]),
  play(<_Shape>[_Fill('M8 5.5v13l10.5-6.5z')]),
  pause(<_Shape>[_Fill('M7 5.5h3.2v13H7zM13.8 5.5H17v13h-3.2z')]),
  stop(<_Shape>[_Fill('M6.5 6.5h11v11h-11z')]),
  bell(<_Shape>[_Line('M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 1.5h-15zM10 20.5h4')]),
  chevronRight(<_Shape>[_Line('M9 6l6 6-6 6')], strokeWidth: 2),
  chevronLeft(<_Shape>[_Line('M15 6l-6 6 6 6')], strokeWidth: 2),
  chevronUp(<_Shape>[_Line('M6 15l6-6 6 6')], strokeWidth: 2),
  chevronDown(<_Shape>[_Line('M6 9l6 6 6-6')], strokeWidth: 2),
  unfold(<_Shape>[_Line('M8 9.5l4-4 4 4M8 14.5l4 4 4-4')], strokeWidth: 2),
  plus(<_Shape>[_Line('M12 5v14M5 12h14')]),
  minus(<_Shape>[_Line('M5 12h14')], strokeWidth: 2),
  dragDots(<_Shape>[
    _Line('M9 6h.01M15 6h.01M9 12h.01M15 12h.01M9 18h.01M15 18h.01'),
  ], strokeWidth: 2.5),
  moreVertical(<_Shape>[
    _Disc(12, 5.5, 1.6),
    _Disc(12, 12, 1.6),
    _Disc(12, 18.5, 1.6),
  ]),
  info(<_Shape>[_Circle(12, 12, 9), _Line('M12 11v5M12 8h.01')]),
  warning(<_Shape>[_Line('M12 4.5L3.5 19h17zM12 10v4M12 16.5h.01')]),
  trash(<_Shape>[_Line('M4.5 7h15M10 7V4.5h4V7M6.5 7l1 12.5h9l1-12.5')]),
  upload(<_Shape>[
    _Line(
      'M12 15V4M7.5 8.5L12 4l4.5 4.5M5 14v4.5a1.5 1.5 0 0 0 1.5 1.5h11'
      'a1.5 1.5 0 0 0 1.5-1.5V14',
    ),
  ]),
  download(<_Shape>[
    _Line(
      'M12 4v11M7.5 10.5L12 15l4.5-4.5M5 14v4.5a1.5 1.5 0 0 0 1.5 1.5h11'
      'a1.5 1.5 0 0 0 1.5-1.5V14',
    ),
  ]),
  check(<_Shape>[_Line('M5 12.5l4.5 4.5L19 7.5')], strokeWidth: 2.25),
  checkCircle(<_Shape>[
    _Circle(12, 12, 9),
    _Line('M8 12.5l2.7 2.7L16 9.8'),
  ], strokeWidth: 2.25),
  close(<_Shape>[_Line('M7 7l10 10M17 7L7 17')], strokeWidth: 2),
  speaker(<_Shape>[
    _Line('M4.5 9.5h3l4-3.5v12l-4-3.5h-3zM15 9.2a4 4 0 0 1 0 5.6'),
  ]),
  speakerMuted(<_Shape>[
    _Line('M4.5 9.5h3l4-3.5v12l-4-3.5h-3zM15.5 9.5l5 5M20.5 9.5l-5 5'),
  ]),
  musicNote(<_Shape>[
    _Line('M9.5 17.5V6l9-2v11.5'),
    _Circle(7.5, 17.5, 2),
    _Circle(16.5, 15.5, 2),
  ]);

  const LineGlyph(this._shapes, {this.strokeWidth = 1.75});

  final List<_Shape> _shapes;
  final double strokeWidth;
}

/// Draws a [LineGlyph] in the surrounding icon color and size, so it can
/// stand anywhere an [Icon] would, including inside buttons.
final class LineIcon extends StatelessWidget {
  const LineIcon(this.glyph, {this.size, this.color, super.key});

  final LineGlyph glyph;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double dimension = size ?? iconTheme.size ?? 24;
    final Color ink =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    // Like Icon, keep the glyph at its own size and centred even when a
    // parent such as an input decoration hands down a larger tight box.
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: Center(
          child: CustomPaint(
            size: Size.square(dimension),
            painter: _LineGlyphPainter(glyph: glyph, color: ink),
          ),
        ),
      ),
    );
  }
}

final class _LineGlyphPainter extends CustomPainter {
  const _LineGlyphPainter({required this.glyph, required this.color});

  static const double _grid = 24;

  final LineGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / _grid;
    canvas.save();
    canvas.scale(scale);
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = glyph.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final _Shape shape in glyph._shapes) {
      canvas.drawPath(shape.path, shape.filled ? fill : stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LineGlyphPainter oldDelegate) {
    return glyph != oldDelegate.glyph || color != oldDelegate.color;
  }
}

sealed class _Shape {
  const _Shape();

  bool get filled => false;

  Path get path;
}

final class _Line extends _Shape {
  const _Line(this.data);

  final String data;

  @override
  Path get path => _SvgPath.parse(data);
}

final class _Fill extends _Line {
  const _Fill(super.data);

  @override
  bool get filled => true;
}

final class _Circle extends _Shape {
  const _Circle(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;

  @override
  Path get path =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));
}

final class _Disc extends _Circle {
  const _Disc(super.x, super.y, super.radius);

  @override
  bool get filled => true;
}

final class _Box extends _Shape {
  const _Box(this.x, this.y, this.width, this.height, this.cornerRadius);

  final double x;
  final double y;
  final double width;
  final double height;
  final double cornerRadius;

  @override
  Path get path => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        Radius.circular(cornerRadius),
      ),
    );
}

/// The subset of SVG path data the glyphs use: move, line, horizontal,
/// vertical, elliptical arc, cubic curve and close, absolute or relative.
abstract final class _SvgPath {
  static final Map<String, Path> _cache = <String, Path>{};
  static final RegExp _token = RegExp(
    r'[MmLlHhVvAaCcZz]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?',
  );

  static Path parse(String data) {
    return _cache.putIfAbsent(data, () => _build(data));
  }

  static Path _build(String data) {
    final List<String> tokens = _token
        .allMatches(data)
        .map((Match match) => match.group(0)!)
        .toList(growable: false);
    final Path path = Path();
    Offset current = Offset.zero;
    Offset start = Offset.zero;
    String command = 'M';
    int index = 0;
    double next() => double.parse(tokens[index++]);
    while (index < tokens.length) {
      if (RegExp(r'^[A-Za-z]$').hasMatch(tokens[index])) {
        command = tokens[index++];
      }
      final bool relative = command == command.toLowerCase();
      Offset point(double x, double y) =>
          relative ? current + Offset(x, y) : Offset(x, y);
      switch (command.toUpperCase()) {
        case 'M':
          current = point(next(), next());
          start = current;
          path.moveTo(current.dx, current.dy);
          // Further pairs after a move are implicit lines.
          command = relative ? 'l' : 'L';
        case 'L':
          current = point(next(), next());
          path.lineTo(current.dx, current.dy);
        case 'H':
          final double x = next();
          current = Offset(relative ? current.dx + x : x, current.dy);
          path.lineTo(current.dx, current.dy);
        case 'V':
          final double y = next();
          current = Offset(current.dx, relative ? current.dy + y : y);
          path.lineTo(current.dx, current.dy);
        case 'A':
          final double rx = next();
          final double ry = next();
          final double rotation = next();
          final bool largeArc = next() != 0;
          final bool sweep = next() != 0;
          current = point(next(), next());
          path.arcToPoint(
            current,
            radius: Radius.elliptical(rx, ry),
            rotation: rotation,
            largeArc: largeArc,
            clockwise: sweep,
          );
        case 'C':
          final Offset first = point(next(), next());
          final Offset second = point(next(), next());
          current = point(next(), next());
          path.cubicTo(
            first.dx,
            first.dy,
            second.dx,
            second.dy,
            current.dx,
            current.dy,
          );
        case 'Z':
          path.close();
          current = start;
          if (index < tokens.length &&
              !RegExp(r'^[A-Za-z]$').hasMatch(tokens[index])) {
            throw FormatException('Coordinates after a close command', data);
          }
      }
    }
    return path;
  }
}
