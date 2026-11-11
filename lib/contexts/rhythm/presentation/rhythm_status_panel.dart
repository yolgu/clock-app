import 'package:flutter/material.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart'
    show ClockRhythmSpace, ClockRhythmStatusChip;
import '../application/rhythm_status_snapshot.dart';
import '../domain/rhythm_event.dart';
import '../domain/rhythm_session.dart';

/// Session state as a compact read-out: the status chip with the next
/// notification time underneath.
final class RhythmStatusPanel extends StatelessWidget {
  const RhythmStatusPanel({required this.snapshot, super.key});

  final RhythmStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('rhythm-status-panel'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RhythmStatusChip(snapshot: snapshot),
        const SizedBox(height: ClockRhythmSpace.space8),
        RhythmScheduleNote(snapshot: snapshot, textAlign: TextAlign.center),
      ],
    );
  }
}

/// The session state as a quiet chip, for page headers and summaries.
final class RhythmStatusChip extends StatelessWidget {
  const RhythmStatusChip({required this.snapshot, super.key});

  final RhythmStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final _StatusLook status = _StatusLook.of(
      snapshot.status,
      copy,
      Theme.of(context).colorScheme,
    );
    return Semantics(
      container: true,
      label: copy.rhythmStatusTitle,
      child: ClockRhythmStatusChip(
        key: const ValueKey<String>('rhythm-status-chip'),
        label: status.label,
        labelKey: const ValueKey<String>('rhythm-status-value'),
        tone: status.tone,
      ),
    );
  }
}

/// The session state as plain text, for summaries that list several facts.
final class RhythmStatusText extends StatelessWidget {
  const RhythmStatusText({required this.snapshot, this.style, super.key});

  final RhythmStatusSnapshot snapshot;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      _StatusLook.of(
        snapshot.status,
        AppLocalizations.of(context),
        Theme.of(context).colorScheme,
      ).label,
      style: style,
    );
  }
}

/// How each session state is named and colored wherever it is shown.
final class _StatusLook {
  const _StatusLook(this.label, this.tone);

  factory _StatusLook.of(
    RhythmSessionStatus status,
    AppLocalizations copy,
    ColorScheme colors,
  ) {
    return switch (status) {
      RhythmSessionStatus.idle => _StatusLook(
        copy.rhythmStatusIdle,
        colors.onSurfaceVariant,
      ),
      RhythmSessionStatus.running => _StatusLook(
        copy.rhythmStatusRunning,
        colors.secondary,
      ),
      RhythmSessionStatus.paused => _StatusLook(
        copy.rhythmStatusPaused,
        _pausedTone,
      ),
      RhythmSessionStatus.stoppedForToday => _StatusLook(
        copy.rhythmStatusStoppedForToday,
        colors.error,
      ),
    };
  }

  static const Color _pausedTone = Color(0xFFFF9F0A);

  final String label;
  final Color tone;
}

/// When the next notification arrives, and whether now is outside the
/// focus window.
final class RhythmScheduleNote extends StatelessWidget {
  const RhythmScheduleNote({
    required this.snapshot,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final RhythmStatusSnapshot snapshot;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final RhythmEvent? nextEvent = snapshot.nextEvent;
    if (nextEvent == null) {
      return const SizedBox.shrink();
    }
    final bool outsideWindow = snapshot.observedAt.isBefore(
      nextEvent.windowStartsAt,
    );
    final TextStyle? style = theme.textTheme.labelSmall;
    return Column(
      crossAxisAlignment: switch (textAlign) {
        TextAlign.center => CrossAxisAlignment.center,
        _ => CrossAxisAlignment.start,
      },
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          copy.rhythmSettingsNextEvent(
            const ClockTimeFormatter().formatLocalDateTime(nextEvent.occursAt),
          ),
          key: const ValueKey<String>('next-rhythm-event'),
          textAlign: textAlign,
          style: style,
        ),
        if (outsideWindow)
          Text(
            copy.rhythmSettingsOutsideDailyRhythm,
            key: const ValueKey<String>('outside-daily-rhythm'),
            textAlign: textAlign,
            style: style,
          ),
      ],
    );
  }
}
