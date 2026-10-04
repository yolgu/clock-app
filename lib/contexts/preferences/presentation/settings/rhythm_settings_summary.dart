import 'package:flutter/material.dart';

import '../../../../shared/i18n/public.dart';
import '../../../../shared/ui/public.dart'
    show StableContentSlot, SemanticStatusAnnouncement;
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
    final ThemeData theme = Theme.of(context);
    return DefaultTextStyle.merge(
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StableContentSlot(
            labels: <String>[
              for (final String soundLabel in <String>[
                copy.soundDefaultLabel,
                copy.rhythmSettingsSummaryMuted,
                copy.rhythmSettingsSummaryZeroVolume,
                sound.customFileName ?? copy.soundCustomFallback,
              ])
                copy.rhythmSettingsSummary(
                  state.draft.rhythmConfiguration.focusDuration.minutes,
                  state.draft.rhythmConfiguration.restDuration.minutes,
                  state.draft.rhythmConfiguration.dailyRhythm.start.text,
                  state.draft.rhythmConfiguration.dailyRhythm.end.text,
                  soundLabel,
                ),
            ],
            child: Text(
              copy.rhythmSettingsSummary(
                state.draft.rhythmConfiguration.focusDuration.minutes,
                state.draft.rhythmConfiguration.restDuration.minutes,
                state.draft.rhythmConfiguration.dailyRhythm.start.text,
                state.draft.rhythmConfiguration.dailyRhythm.end.text,
                soundSummary,
              ),
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
          StableContentSlot(
            labels: <String>[copy.rhythmSettingsSummaryOutsideDailyRhythm],
            child: (preview?.isOutsideDailyRhythm ?? false)
                ? Text(
                    copy.rhythmSettingsSummaryOutsideDailyRhythm,
                    key: const ValueKey<String>(
                      'rhythm-summary-outside-window',
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          _buildSaveStatus(context, copy),
        ],
      ),
    );
  }

  Widget _buildSaveStatus(BuildContext context, AppLocalizations copy) {
    final bool failed =
        state.failure == PreferencesFailure.rhythmSave ||
        state.failure == PreferencesFailure.draftStore ||
        state.failure == PreferencesFailure.language;
    final bool saving = state.operation == PreferencesOperation.savingRhythm;
    final String message = failed
        ? copy.failurePreferencesSave
        : hasInvalidInput
        ? <String>[
            if (state.isDirty) copy.rhythmSettingsSummaryDirty,
            copy.rhythmSettingsSummaryInvalid,
          ].join('\n')
        : saving
        ? copy.rhythmSettingsSaving
        : state.isDirty
        ? copy.rhythmSettingsSummaryDirty
        : state.feedback == PreferencesFeedback.saved
        ? copy.messagePreferencesSaved
        : copy.rhythmSettingsSummaryClean;
    return StableContentSlot(
      labels: <String>[
        copy.rhythmSettingsSummaryClean,
        copy.rhythmSettingsSaving,
        copy.messagePreferencesSaved,
        copy.failurePreferencesSave,
        <String>[
          copy.rhythmSettingsSummaryDirty,
          copy.rhythmSettingsSummaryInvalid,
        ].join('\n'),
      ],
      child: SemanticStatusAnnouncement(
        message: message,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (hasInvalidInput && !failed) ...<Widget>[
              if (state.isDirty)
                Text(
                  copy.rhythmSettingsSummaryDirty,
                  key: const ValueKey<String>('rhythm-summary-dirty'),
                ),
              Text(
                copy.rhythmSettingsSummaryInvalid,
                key: const ValueKey<String>('rhythm-summary-invalid'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ] else
              Text(
                message,
                key: ValueKey<String>(
                  failed
                      ? 'preferences-failed-feedback'
                      : state.isDirty
                      ? 'rhythm-summary-dirty'
                      : state.feedback == PreferencesFeedback.saved
                      ? 'preferences-saved-feedback'
                      : 'rhythm-summary-status',
                ),
                style: failed
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
