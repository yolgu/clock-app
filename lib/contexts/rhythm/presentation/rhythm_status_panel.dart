import 'package:flutter/material.dart';

import '../../../shared/i18n/public.dart';
import '../application/rhythm_status_snapshot.dart';
import '../domain/rhythm_event.dart';
import '../domain/rhythm_session.dart';

final class RhythmStatusPanel extends StatelessWidget {
  const RhythmStatusPanel({required this.snapshot, super.key});

  final RhythmStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final ({IconData icon, String label}) status = _status(copy);
    final RhythmEvent? nextEvent = snapshot.nextEvent;
    final bool outsideWindow =
        nextEvent != null &&
        snapshot.observedAt.isBefore(nextEvent.windowStartsAt);
    return Card(
      key: const ValueKey<String>('rhythm-status-panel'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(copy.rhythmStatusTitle),
            Row(
              children: <Widget>[
                Icon(status.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.label,
                    key: const ValueKey<String>('rhythm-status-value'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            if (nextEvent != null)
              Text(
                copy.rhythmSettingsNextEvent(
                  const ClockTimeFormatter().formatLocalDateTime(
                    nextEvent.occursAt,
                  ),
                ),
                key: const ValueKey<String>('next-rhythm-event'),
              ),
            if (outsideWindow)
              Text(
                copy.rhythmSettingsOutsideDailyRhythm,
                key: const ValueKey<String>('outside-daily-rhythm'),
              ),
          ],
        ),
      ),
    );
  }

  ({IconData icon, String label}) _status(AppLocalizations copy) {
    return switch (snapshot.status) {
      RhythmSessionStatus.idle => (
        icon: Icons.hourglass_empty,
        label: copy.rhythmStatusIdle,
      ),
      RhythmSessionStatus.running => (
        icon: Icons.play_circle,
        label: copy.rhythmStatusRunning,
      ),
      RhythmSessionStatus.paused => (
        icon: Icons.pause_circle,
        label: copy.rhythmStatusPaused,
      ),
      RhythmSessionStatus.stoppedForToday => (
        icon: Icons.event_busy,
        label: copy.rhythmStatusStoppedForToday,
      ),
    };
  }
}
