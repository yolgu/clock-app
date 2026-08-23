import 'package:flutter/material.dart';

import '../../../../shared/i18n/public.dart';
import '../../application/preview_rhythm_settings.dart';
import '../../domain/notification_sound_preference.dart';
import '../preferences_view_state.dart';

final class RhythmSettingsSummary extends StatelessWidget {
  const RhythmSettingsSummary({
    required this.state,
    required this.hasInvalidInput,
    required this.observedAt,
    super.key,
  });

  final PreferencesViewState state;
  final bool hasInvalidInput;
  final DateTime observedAt;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final NotificationSoundPreference sound =
        state.preferences.notificationSound;
    final RhythmSettingsPreview? preview = hasInvalidInput
        ? null
        : const PreviewRhythmSettings().execute(
            draft: state.draft,
            observedAt: observedAt,
          );
    final String soundSummary = switch (sound.mode) {
      NotificationSoundMode.muted => copy.rhythmSettingsSummaryMuted,
      _ when sound.volume == 0 => copy.rhythmSettingsSummaryZeroVolume,
      NotificationSoundMode.bundledDefault => copy.soundDefaultLabel,
      NotificationSoundMode.custom =>
        sound.customFileName ?? copy.soundCustomFallback,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          copy.rhythmSettingsSummary(
            state.draft.rhythmConfiguration.focusDuration.minutes,
            state.draft.rhythmConfiguration.restDuration.minutes,
            state.draft.rhythmConfiguration.dailyRhythm.start.text,
            state.draft.rhythmConfiguration.dailyRhythm.end.text,
            soundSummary,
          ),
        ),
        if (preview case final RhythmSettingsPreview value)
          Text(
            copy.rhythmSettingsNextEvent(
              const ClockTimeFormatter().formatLocalDateTime(
                value.nextEvent.occursAt,
              ),
            ),
            key: const ValueKey<String>('rhythm-settings-next-event'),
          )
        else
          Text(
            copy.rhythmSettingsNextEventUnavailable,
            key: const ValueKey<String>(
              'rhythm-settings-next-event-unavailable',
            ),
          ),
        if (preview?.isOutsideDailyRhythm ?? false)
          Text(
            copy.rhythmSettingsSummaryOutsideDailyRhythm,
            key: const ValueKey<String>('rhythm-summary-outside-window'),
          ),
        if (state.isDirty)
          Text(
            copy.rhythmSettingsSummaryDirty,
            key: const ValueKey<String>('rhythm-summary-dirty'),
          ),
        if (hasInvalidInput)
          Text(
            copy.rhythmSettingsSummaryInvalid,
            key: const ValueKey<String>('rhythm-summary-invalid'),
          ),
      ],
    );
  }
}
