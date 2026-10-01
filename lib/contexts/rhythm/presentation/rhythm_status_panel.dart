import 'package:flutter/material.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart'
    show ClockRhythmRadius, ClockRhythmSpace;
import '../application/rhythm_status_snapshot.dart';
import '../domain/rhythm_event.dart';
import '../domain/rhythm_session.dart';

/// Session state as a compact, centered read-out: a tinted status pill and
/// the next notification time underneath.
final class RhythmStatusPanel extends StatelessWidget {
  const RhythmStatusPanel({required this.snapshot, super.key});

  final RhythmStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final ({String label, Color tone}) status = _status(
      copy,
      theme.colorScheme,
    );
    final RhythmEvent? nextEvent = snapshot.nextEvent;
    final bool outsideWindow =
        nextEvent != null &&
        snapshot.observedAt.isBefore(nextEvent.windowStartsAt);
    final TextStyle? detailStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      label: copy.rhythmStatusTitle,
      child: Column(
        key: const ValueKey<String>('rhythm-status-panel'),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: status.tone.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(ClockRhythmRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ClockRhythmSpace.space12,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: status.tone,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 8),
                  ),
                  const SizedBox(width: ClockRhythmSpace.space8),
                  Flexible(
                    child: Text(
                      status.label,
                      key: const ValueKey<String>('rhythm-status-value'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (nextEvent != null) ...<Widget>[
            const SizedBox(height: ClockRhythmSpace.space8),
            Text(
              copy.rhythmSettingsNextEvent(
                const ClockTimeFormatter().formatLocalDateTime(
                  nextEvent.occursAt,
                ),
              ),
              key: const ValueKey<String>('next-rhythm-event'),
              textAlign: TextAlign.center,
              style: detailStyle,
            ),
          ],
          if (outsideWindow)
            Text(
              copy.rhythmSettingsOutsideDailyRhythm,
              key: const ValueKey<String>('outside-daily-rhythm'),
              textAlign: TextAlign.center,
              style: detailStyle,
            ),
        ],
      ),
    );
  }

  ({String label, Color tone}) _status(
    AppLocalizations copy,
    ColorScheme colors,
  ) {
    return switch (snapshot.status) {
      RhythmSessionStatus.idle => (
        label: copy.rhythmStatusIdle,
        tone: colors.onSurfaceVariant,
      ),
      RhythmSessionStatus.running => (
        label: copy.rhythmStatusRunning,
        tone: colors.secondary,
      ),
      RhythmSessionStatus.paused => (
        label: copy.rhythmStatusPaused,
        tone: const Color(0xFFFF9F0A),
      ),
      RhythmSessionStatus.stoppedForToday => (
        label: copy.rhythmStatusStoppedForToday,
        tone: colors.error,
      ),
    };
  }
}
