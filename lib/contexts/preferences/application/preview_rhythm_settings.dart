import '../../rhythm/public_model.dart';
import '../domain/rhythm_settings_draft.dart';

final class RhythmSettingsPreview {
  const RhythmSettingsPreview({
    required this.nextEvent,
    required this.isOutsideDailyRhythm,
  });

  final RhythmEvent nextEvent;
  final bool isOutsideDailyRhythm;
}

final class PreviewRhythmSettings {
  const PreviewRhythmSettings();

  RhythmSettingsPreview execute({
    required RhythmSettingsDraft draft,
    required DateTime observedAt,
  }) {
    if (observedAt.isUtc) {
      throw ArgumentError.value(
        observedAt,
        'observedAt',
        'must be a local civil time',
      );
    }
    final RhythmConfiguration configuration = draft.rhythmConfiguration;
    return RhythmSettingsPreview(
      nextEvent: RhythmSchedule(
        configuration: configuration,
      ).nextEventAfter(observedAt),
      isOutsideDailyRhythm:
          configuration.dailyRhythm.windowContaining(observedAt) == null,
    );
  }
}
