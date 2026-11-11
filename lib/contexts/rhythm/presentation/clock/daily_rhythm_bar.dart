import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../../shared/i18n/public.dart';
import '../../../../shared/ui/public.dart' show ClockRhythmSpace;
import '../../domain/rhythm_configuration.dart';
import 'daily_rhythm_timeline.dart';

/// Today's Daily Rhythm at a glance: focus stretches as filled segments,
/// rest as gaps, and a marker at the current moment. The bar is a visual
/// summary; the caption carries the readable window.
final class DailyRhythmBar extends StatelessWidget {
  const DailyRhythmBar({
    required this.configuration,
    required this.now,
    this.compact = false,
    super.key,
  });

  final RhythmConfiguration configuration;
  final DateTime now;

  /// A slimmer bar for small cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final DailyRhythmTimeline timeline = DailyRhythmTimeline.at(
      configuration: configuration,
      moment: now,
    );
    final String window =
        '${configuration.dailyRhythm.start.text} – '
        '${configuration.dailyRhythm.end.text}';
    return Column(
      key: const ValueKey<String>('daily-rhythm-bar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                copy.clockDailyRhythmCaption(
                  configuration.focusDuration.minutes,
                  configuration.restDuration.minutes,
                ),
                style: theme.textTheme.labelSmall,
              ),
            ),
            Text(
              window,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : ClockRhythmSpace.space8),
        ExcludeSemantics(
          child: SizedBox(
            height: compact ? 8 : 10,
            child: CustomPaint(
              painter: _DailyRhythmBarPainter(
                timeline: timeline,
                track: Color.lerp(
                  theme.scaffoldBackgroundColor,
                  theme.colorScheme.surface,
                  0.5,
                )!,
                focus: theme.colorScheme.surfaceContainerHigh,
                marker: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _DailyRhythmBarPainter extends CustomPainter {
  const _DailyRhythmBarPainter({
    required this.timeline,
    required this.track,
    required this.focus,
    required this.marker,
  });

  final DailyRhythmTimeline timeline;
  final Color track;
  final Color focus;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect trackShape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.save();
    canvas.clipRRect(trackShape);
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    final Paint focusPaint = Paint()..color = focus;
    for (final TimelineSpan span in timeline.focusSpans) {
      canvas.drawRect(
        Rect.fromLTRB(
          span.start * size.width,
          0,
          span.end * size.width,
          size.height,
        ),
        focusPaint,
      );
    }
    canvas.restore();
    final double? momentFraction = timeline.momentFraction;
    if (momentFraction != null) {
      final double x = momentFraction * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - 1, -3, x + 1, size.height + 3),
          const Radius.circular(1),
        ),
        Paint()..color = marker,
      );
    }
  }

  @override
  bool shouldRepaint(_DailyRhythmBarPainter oldDelegate) {
    return oldDelegate.timeline.momentFraction != timeline.momentFraction ||
        !listEquals(oldDelegate.timeline.focusSpans, timeline.focusSpans) ||
        oldDelegate.track != track ||
        oldDelegate.focus != focus ||
        oldDelegate.marker != marker;
  }
}
