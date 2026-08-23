import 'dart:ui';

import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps durable compatibility IDs to exact Flutter locales', () {
    expect(
      LanguageLocaleMapper.localeForPreferenceId('kor'),
      const Locale('ko'),
    );
    expect(
      LanguageLocaleMapper.localeForPreferenceId('en'),
      const Locale('en'),
    );
    expect(
      LanguageLocaleMapper.supportedLocales,
      AppLocalizations.supportedLocales,
    );
  });

  test('stays compatible with the Preferences domain language IDs', () {
    final Map<String, Locale> expectedLocales = <String, Locale>{
      'kor': const Locale('ko'),
      'en': const Locale('en'),
    };

    for (final LanguagePreference preference in LanguagePreference.values) {
      expect(
        LanguageLocaleMapper.localeForPreferenceId(preference.id),
        expectedLocales[preference.id],
      );
    }
  });

  test('does not reinterpret locale codes as durable preference IDs', () {
    expect(LanguageLocaleMapper.tryLocaleForPreferenceId('ko'), isNull);
    expect(LanguageLocaleMapper.tryLocaleForPreferenceId('fr'), isNull);
    expect(AppLocalizations.delegate.isSupported(const Locale('kor')), isFalse);
    expect(AppLocalizations.delegate.isSupported(const Locale('ko')), isTrue);
    expect(
      () => LanguageLocaleMapper.localeForPreferenceId('ko'),
      throwsArgumentError,
    );
  });

  test('returns no preference update for an unsupported system locale', () {
    expect(
      LanguageLocaleMapper.preferenceIdForSupportedLocale(
        const Locale('ko', 'KR'),
      ),
      'kor',
    );
    expect(
      LanguageLocaleMapper.preferenceIdForSupportedLocale(
        const Locale('en', 'US'),
      ),
      'en',
    );
    expect(
      LanguageLocaleMapper.preferenceIdForSupportedLocale(
        const Locale('fr', 'FR'),
      ),
      isNull,
    );
  });
}
