import 'package:clock_rhythm/contexts/preferences/application/preview_rhythm_settings.dart';
import 'package:clock_rhythm/contexts/preferences/domain/rhythm_settings_draft.dart';
import 'package:clock_rhythm/contexts/preferences/presentation/settings/rhythm_settings_form_input.dart';
import 'package:clock_rhythm/contexts/rhythm/public_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LB-064 current valid draft determines the next Rhythm Event', () {
    final RhythmSettingsDraft draft = _validDraft(
      focusMinutes: '1',
      restMinutes: '1',
      dailyStart: '23:00',
      dailyEnd: '23:55',
    );

    final RhythmSettingsPreview preview = const PreviewRhythmSettings().execute(
      draft: draft,
      observedAt: DateTime(2026, 6, 2, 23),
    );

    expect(preview.nextEvent.kind, RhythmEventKind.focusEnds);
    expect(preview.nextEvent.occursAt, DateTime(2026, 6, 2, 23, 1));
    expect(preview.isOutsideDailyRhythm, isFalse);
  });

  test('LB-065 outside-window draft still exposes the next Rhythm Event', () {
    final RhythmSettingsDraft draft = _validDraft(
      focusMinutes: '50',
      restMinutes: '10',
      dailyStart: '05:00',
      dailyEnd: '18:00',
    );
    final DateTime observedAt = DateTime(2026, 6, 2, 23);

    final RhythmSettingsPreview preview = const PreviewRhythmSettings().execute(
      draft: draft,
      observedAt: observedAt,
    );

    expect(
      draft.rhythmConfiguration.dailyRhythm.windowContaining(observedAt),
      isNull,
    );
    expect(preview.isOutsideDailyRhythm, isTrue);
    expect(preview.nextEvent.windowStartsAt, DateTime(2026, 6, 3, 5));
    expect(preview.nextEvent.occursAt, DateTime(2026, 6, 3, 5, 50));
  });

  test('LB-066 malformed draft input cannot form a Rhythm Schedule', () {
    const RhythmSettingsFormInput malformedTime = RhythmSettingsFormInput(
      focusMinutes: '50',
      restMinutes: '10',
      dailyStart: '2360',
      dailyEnd: '18:00',
      autoStartEnabled: false,
    );
    const RhythmSettingsFormInput excessiveFocus = RhythmSettingsFormInput(
      focusMinutes: '181',
      restMinutes: '10',
      dailyStart: '05:00',
      dailyEnd: '18:00',
      autoStartEnabled: false,
    );

    final RhythmSettingsFormResult malformedTimeResult = malformedTime
        .validate();
    final RhythmSettingsFormResult excessiveFocusResult = excessiveFocus
        .validate();

    expect(malformedTimeResult.draft, isNull);
    expect(
      malformedTimeResult.errors,
      contains(RhythmSettingsFieldError.start),
    );
    expect(excessiveFocusResult.draft, isNull);
    expect(
      excessiveFocusResult.errors,
      contains(RhythmSettingsFieldError.focus),
    );
  });

  test('preview rejects UTC instants at the local civil-time boundary', () {
    final RhythmSettingsDraft draft = _validDraft(
      focusMinutes: '50',
      restMinutes: '10',
      dailyStart: '05:00',
      dailyEnd: '18:00',
    );

    expect(
      () => const PreviewRhythmSettings().execute(
        draft: draft,
        observedAt: DateTime.utc(2026, 6, 2, 5),
      ),
      throwsArgumentError,
    );
  });
}

RhythmSettingsDraft _validDraft({
  required String focusMinutes,
  required String restMinutes,
  required String dailyStart,
  required String dailyEnd,
}) {
  final RhythmSettingsFormResult result = RhythmSettingsFormInput(
    focusMinutes: focusMinutes,
    restMinutes: restMinutes,
    dailyStart: dailyStart,
    dailyEnd: dailyEnd,
    autoStartEnabled: false,
  ).validate();
  expect(result.errors, isEmpty);
  expect(result.draft, isNotNull);
  return result.draft!;
}
