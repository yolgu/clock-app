import 'package:flutter/material.dart';

import '../../../../shared/ui/public.dart'
    show ClockRhythmSpace, LineGlyph, LineIcon;

final class SoundActionContent extends StatelessWidget {
  const SoundActionContent({
    required this.icon,
    required this.label,
    required this.stacked,
    super.key,
  });

  static const double iconSize = 20;
  static const double gap = ClockRhythmSpace.space8;

  final LineGlyph icon;
  final Widget label;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        children: <Widget>[
          LineIcon(icon, size: iconSize),
          const SizedBox(height: gap),
          Expanded(child: Center(child: label)),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LineIcon(icon, size: iconSize),
        const SizedBox(width: gap),
        Flexible(child: label),
      ],
    );
  }
}
