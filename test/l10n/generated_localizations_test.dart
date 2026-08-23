import 'dart:ui';

import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loads representative Korean and English product copy without fallback',
    () {
      final AppLocalizations korean = lookupAppLocalizations(
        const Locale('ko'),
      );
      final AppLocalizations english = lookupAppLocalizations(
        const Locale('en'),
      );

      expect(korean.navigationData, '데이터');
      expect(english.navigationData, 'Data');
      expect(korean.rhythmStatusIdle, '대기');
      expect(english.rhythmStatusIdle, 'Idle');
    },
  );

  test('formats plural Todo counts in both locales', () {
    final AppLocalizations korean = lookupAppLocalizations(const Locale('ko'));
    final AppLocalizations english = lookupAppLocalizations(const Locale('en'));

    expect(korean.todoCount(0), 'Todo 없음');
    expect(korean.todoCount(3), 'Todo 3개');
    expect(english.todoCount(0), 'No Todos');
    expect(english.todoCount(1), '1 Todo');
    expect(english.todoCount(3), '3 Todos');
  });

  test('generated messages replace every declared named placeholder', () {
    final AppLocalizations korean = lookupAppLocalizations(const Locale('ko'));
    final AppLocalizations english = lookupAppLocalizations(const Locale('en'));

    expect(korean.backupSummaryTheme('Neon Dusk'), '테마: Neon Dusk');
    expect(english.backupSummaryTheme('Neon Dusk'), 'Theme: Neon Dusk');
    expect(korean.todoValidationTitleCounter(12, 160), '12/160');
    expect(english.todoValidationTitleCounter(12, 160), '12/160');
  });

  test('generates the accepted compatibility theme names for both locales', () {
    final AppLocalizations korean = lookupAppLocalizations(const Locale('ko'));
    final AppLocalizations english = lookupAppLocalizations(const Locale('en'));

    expect(korean.themeDraculaName, 'Dracula');
    expect(korean.themeNeonDuskName, 'Neon Dusk');
    expect(english.themeDraculaName, 'Dracula');
    expect(english.themeNeonDuskName, 'Neon Dusk');
  });

  test(
    'translates the top-level Theme destination and page in both locales',
    () {
      final AppLocalizations korean = lookupAppLocalizations(
        const Locale('ko'),
      );
      final AppLocalizations english = lookupAppLocalizations(
        const Locale('en'),
      );

      expect((korean.navigationTheme, korean.themeTitle), ('테마', '테마'));
      expect((english.navigationTheme, english.themeTitle), ('Theme', 'Theme'));
    },
  );

  test('preserves focus-window wording from the original product', () {
    final AppLocalizations korean = lookupAppLocalizations(const Locale('ko'));
    final AppLocalizations english = lookupAppLocalizations(const Locale('en'));

    expect(korean.rhythmSettingsDailyStart, '집중 시간대 시작');
    expect(korean.rhythmSettingsOutsideDailyRhythm, '현재는 집중 시간대 밖입니다.');
    expect(english.rhythmSettingsDailyStart, 'Focus window start');
    expect(
      english.rhythmSettingsOutsideDailyRhythm,
      'The current time is outside the focus window.',
    );
  });
}
