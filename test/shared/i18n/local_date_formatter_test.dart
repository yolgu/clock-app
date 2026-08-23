import 'dart:ui';

import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ko');
  });

  test('formats the same local calendar date for Korean and English', () {
    final DateTime date = DateTime(2026, 6, 2);
    final LocalDateFormatter korean = LocalDateFormatter(const Locale('ko'));
    final LocalDateFormatter english = LocalDateFormatter(const Locale('en'));

    expect(korean.formatFullDate(date), '2026년 6월 2일 화요일');
    expect(english.formatFullDate(date), 'Tuesday, June 2, 2026');
  });

  test('formats locale-aware month and weekday labels', () {
    final DateTime date = DateTime(2026, 6, 2);
    final LocalDateFormatter korean = LocalDateFormatter(const Locale('ko'));
    final LocalDateFormatter english = LocalDateFormatter(const Locale('en'));

    expect(korean.formatMonth(date), '2026년 6월');
    expect(english.formatMonth(date), 'June 2026');
    expect(korean.formatWeekdayAbbreviation(date), '화');
    expect(english.formatWeekdayAbbreviation(date), 'Tue');
    expect(korean.formatWeekday(date), '화요일');
    expect(english.formatWeekday(date), 'Tuesday');
  });

  test('rejects UTC instants at the Local Calendar Date boundary', () {
    final LocalDateFormatter formatter = LocalDateFormatter(const Locale('en'));

    expect(
      () => formatter.formatFullDate(DateTime.utc(2026, 6, 2)),
      throwsArgumentError,
    );
  });

  test('rejects unsupported locales instead of falling back to English', () {
    expect(() => LocalDateFormatter(const Locale('fr')), throwsArgumentError);
  });
}
