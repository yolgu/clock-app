import 'package:clock_rhythm/contexts/todo/domain/local_calendar_date.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_id.dart';
import 'package:clock_rhythm/contexts/todo/domain/todo_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalCalendarDate', () {
    test('accepts actual Gregorian dates without creating an instant', () {
      final LocalCalendarDate leapDay = LocalCalendarDate.parse('2028-02-29');

      expect(leapDay.year, 2028);
      expect(leapDay.month, 2);
      expect(leapDay.day, 29);
      expect(leapDay.text, '2028-02-29');
      expect(leapDay.monthKey, '2028-02');
    });

    test('applies Gregorian century leap-year rules', () {
      expect(() => LocalCalendarDate.parse('1900-02-29'), throwsArgumentError);
      expect(LocalCalendarDate.parse('2000-02-29').day, 29);
    });

    test('rejects normalized and malformed calendar dates', () {
      const List<String> invalidDates = <String>[
        '0000-01-01',
        '2026-2-01',
        '2026-02-29',
        '2026-04-31',
        '2026-13-01',
        '2026-01-01T00:00:00Z',
      ];

      for (final String invalidDate in invalidDates) {
        expect(
          () => LocalCalendarDate.parse(invalidDate),
          throwsArgumentError,
          reason: '$invalidDate must not be normalized or time-zone shifted',
        );
      }
    });

    test('compares dates by their calendar components', () {
      final LocalCalendarDate earlier = LocalCalendarDate.parse('2026-12-31');
      final LocalCalendarDate later = LocalCalendarDate.parse('2027-01-01');

      expect(earlier.compareTo(later), lessThan(0));
      expect(LocalCalendarDate.parse('2026-12-31'), earlier);
    });
  });

  group('TodoTime', () {
    test('accepts the exact optional HH:mm boundaries', () {
      expect(TodoTime.optional(null), isNull);
      expect(TodoTime.parse('00:00').text, '00:00');
      expect(TodoTime.parse('23:59').hour, 23);
      expect(TodoTime.parse('23:59').minute, 59);
    });

    test('rejects present values outside exact HH:mm', () {
      const List<String> invalidTimes = <String>[
        '',
        '7:30',
        '24:00',
        '12:60',
        '12:00Z',
      ];

      for (final String invalidTime in invalidTimes) {
        expect(
          () => TodoTime.optional(invalidTime),
          throwsArgumentError,
          reason: '"$invalidTime" is present and must be valid',
        );
      }
    });
  });

  group('TodoId', () {
    test('accepts a nonempty identifier up to 128 Unicode scalars', () {
      final TodoId id = TodoId.parse('가' * TodoId.maximumLength);

      expect(id.text.runes.length, TodoId.maximumLength);
    });

    test('rejects blank and overlong identifiers', () {
      expect(() => TodoId.parse('  '), throwsArgumentError);
      expect(
        () => TodoId.parse('a' * (TodoId.maximumLength + 1)),
        throwsArgumentError,
      );
    });
  });
}
