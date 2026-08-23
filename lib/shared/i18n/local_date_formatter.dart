import 'dart:ui';

import 'package:intl/intl.dart';

import 'language_locale_mapper.dart';

final class LocalDateFormatter {
  factory LocalDateFormatter(Locale locale) {
    if (LanguageLocaleMapper.preferenceIdForSupportedLocale(locale) == null) {
      throw ArgumentError.value(
        locale,
        'locale',
        'must be a supported Clock Rhythm locale',
      );
    }
    return LocalDateFormatter._(locale.languageCode);
  }

  const LocalDateFormatter._(this._localeName);

  final String _localeName;

  String formatFullDate(DateTime date) {
    _requireLocalDate(date);
    return DateFormat.yMMMMEEEEd(_localeName).format(date);
  }

  String formatMonth(DateTime date) {
    _requireLocalDate(date);
    return DateFormat.yMMMM(_localeName).format(date);
  }

  String formatWeekdayAbbreviation(DateTime date) {
    _requireLocalDate(date);
    return DateFormat.E(_localeName).format(date);
  }

  String formatWeekday(DateTime date) {
    _requireLocalDate(date);
    return DateFormat.EEEE(_localeName).format(date);
  }

  String formatCompactDate(DateTime date) {
    _requireLocalDate(date);
    return DateFormat.yMMMd(_localeName).format(date);
  }

  void _requireLocalDate(DateTime date) {
    if (date.isUtc) {
      throw ArgumentError.value(
        date,
        'date',
        'must represent a Local Calendar Date',
      );
    }
  }
}
