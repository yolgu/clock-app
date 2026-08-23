import '../../domain/local_calendar_date.dart';

final class CalendarCell {
  const CalendarCell._({required this.date, required this.day});

  const CalendarCell.blank() : this._(date: null, day: null);

  final LocalCalendarDate? date;
  final int? day;

  bool get isCurrentMonth => date != null;
}

abstract final class CalendarCells {
  static const int fixedCellCount = 42;

  static List<CalendarCell> forMonth(LocalCalendarDate visibleMonth) {
    if (visibleMonth.day != 1) {
      throw ArgumentError.value(
        visibleMonth,
        'visibleMonth',
        'must identify the first day of a month',
      );
    }
    final int leadingBlankCount =
        DateTime(visibleMonth.year, visibleMonth.month).weekday % 7;
    final int dayCount = _daysInMonth(
      year: visibleMonth.year,
      month: visibleMonth.month,
    );
    return List<CalendarCell>.unmodifiable(
      List<CalendarCell>.generate(fixedCellCount, (int index) {
        final int day = index - leadingBlankCount + 1;
        if (day < 1 || day > dayCount) {
          return const CalendarCell.blank();
        }
        final String dayText = day.toString().padLeft(2, '0');
        return CalendarCell._(
          date: LocalCalendarDate.parse('${visibleMonth.monthKey}-$dayText'),
          day: day,
        );
      }, growable: false),
    );
  }

  static int _daysInMonth({required int year, required int month}) {
    return switch (month) {
      2 => _isLeapYear(year) ? 29 : 28,
      4 || 6 || 9 || 11 => 30,
      _ => 31,
    };
  }

  static bool _isLeapYear(int year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
  }
}
