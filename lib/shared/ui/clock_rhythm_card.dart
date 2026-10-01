import 'package:flutter/material.dart';

import 'design_tokens.dart';

enum _ClockRhythmCardPadding { responsive, none }

/// A borderless grouped surface: content is separated from the page by fill
/// contrast alone, the way Apple's inset grouped lists are.
final class ClockRhythmCard extends StatelessWidget {
  const ClockRhythmCard.padded({
    required this.child,
    this.color,
    this.borderColor,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  }) : _padding = _ClockRhythmCardPadding.responsive;

  const ClockRhythmCard.unpadded({
    required this.child,
    this.color,
    this.borderColor,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  }) : _padding = _ClockRhythmCardPadding.none;

  final Widget child;
  final Color? color;

  /// Draws an outline only when a caller needs one, such as a selection.
  final Color? borderColor;
  final Clip clipBehavior;
  final _ClockRhythmCardPadding _padding;

  /// A faint light edge that lifts dark grouped surfaces off the page, like
  /// the hairline stroke on macOS widgets.
  static Color highlightFor(ThemeData theme) {
    return theme.colorScheme.onSurface.withValues(alpha: 0.07);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius borderRadius = BorderRadius.circular(
      ClockRhythmRadius.card,
    );
    final Widget content = switch (_padding) {
      _ClockRhythmCardPadding.responsive => Padding(
        padding: EdgeInsets.all(
          ClockRhythmLayout.cardPaddingFor(MediaQuery.sizeOf(context).width),
        ),
        child: child,
      ),
      _ClockRhythmCardPadding.none => child,
    };
    final Color? outline = borderColor;
    return Material(
      color: color ?? theme.colorScheme.surface,
      clipBehavior: clipBehavior,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: outline == null
            ? BorderSide(color: highlightFor(theme), width: 0.5)
            : BorderSide(color: outline, width: 2),
      ),
      child: content,
    );
  }
}
