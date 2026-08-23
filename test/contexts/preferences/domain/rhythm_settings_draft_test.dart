import 'package:clock_rhythm/contexts/preferences/domain/rhythm_settings_draft.dart';
import 'package:clock_rhythm/contexts/preferences/domain/user_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editing the draft never mutates durable preferences', () {
    final UserPreferences durable = UserPreferences.defaults();
    final RhythmSettingsDraft draft = RhythmSettingsDraft.fromPreferences(
      durable,
    ).changeFocusMinutes(25).changeAutoStart(true);

    expect(draft.isDirtyComparedWith(durable), isTrue);
    expect(draft.rhythmConfiguration.focusDuration.minutes, 25);
    expect(draft.autoStartEnabled, isTrue);
    expect(durable.rhythmConfiguration.focusDuration.minutes, 50);
    expect(durable.autoStartEnabled, isFalse);
  });

  test('serializes and restores a device-local draft exactly', () {
    final RhythmSettingsDraft draft = RhythmSettingsDraft.fromPreferences(
      UserPreferences.defaults(),
    ).changeRestMinutes(15).changeDailyRhythm(start: '22:00', end: '02:00');

    final RhythmSettingsDraft restored = RhythmSettingsDraft.restore(
      draft.snapshot(),
    );

    expect(restored, draft);
    expect(restored.snapshot().dailyStart, '22:00');
    expect(restored.snapshot().dailyEnd, '02:00');
  });

  test('rejects a draft whose first Focus interval cannot fit', () {
    expect(
      () => RhythmSettingsDraft.fromPreferences(
        UserPreferences.defaults(),
      ).changeDailyRhythm(start: '05:00', end: '05:20'),
      throwsArgumentError,
    );
  });
}
