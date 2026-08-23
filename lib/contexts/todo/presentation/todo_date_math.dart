import '../domain/local_calendar_date.dart';

abstract final class TodoDateMath {
  static LocalCalendarDate fromLocalDateTime(DateTime value) {
    if (value.isUtc) {
      throw ArgumentError.value(
        value,
        'value',
        'must identify a local wall-clock date',
      );
    }
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return LocalCalendarDate.parse('$year-$month-$day');
  }

  static LocalCalendarDate firstOfMonth(LocalCalendarDate value) {
    return LocalCalendarDate.parse('${value.monthKey}-01');
  }

  static LocalCalendarDate? addMonths(
    LocalCalendarDate visibleMonth,
    int offset,
  ) {
    final int zeroBasedMonth = visibleMonth.year * 12 + visibleMonth.month - 1;
    final int target = zeroBasedMonth + offset;
    final int year = target ~/ 12;
    final int month = target % 12 + 1;
    if (year < 1 || year > 9999) {
      return null;
    }
    final String yearText = year.toString().padLeft(4, '0');
    final String monthText = month.toString().padLeft(2, '0');
    return LocalCalendarDate.parse('$yearText-$monthText-01');
  }

  static DateTime toLocalDateTime(LocalCalendarDate value) {
    return DateTime(value.year, value.month, value.day);
  }
}
