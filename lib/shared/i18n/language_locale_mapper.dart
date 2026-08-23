import 'dart:ui';

abstract final class LanguageLocaleMapper {
  static const String koreanPreferenceId = 'kor';
  static const String englishPreferenceId = 'en';

  static const Locale koreanLocale = Locale('ko');
  static const Locale englishLocale = Locale('en');

  static const List<Locale> supportedLocales = <Locale>[
    englishLocale,
    koreanLocale,
  ];

  static Locale localeForPreferenceId(String preferenceId) {
    final Locale? locale = tryLocaleForPreferenceId(preferenceId);
    if (locale == null) {
      throw ArgumentError.value(
        preferenceId,
        'preferenceId',
        'must be a supported durable language preference ID',
      );
    }
    return locale;
  }

  static Locale? tryLocaleForPreferenceId(String preferenceId) {
    return switch (preferenceId) {
      koreanPreferenceId => koreanLocale,
      englishPreferenceId => englishLocale,
      _ => null,
    };
  }

  static String? preferenceIdForSupportedLocale(Locale locale) {
    return switch (locale.languageCode) {
      'ko' => koreanPreferenceId,
      'en' => englishPreferenceId,
      _ => null,
    };
  }
}
