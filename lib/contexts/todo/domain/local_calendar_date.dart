final class LocalCalendarDate implements Comparable<LocalCalendarDate> {
  const LocalCalendarDate._({
    required this.year,
    required this.month,
    required this.day,
  });

  static final RegExp _textPattern = RegExp(
    r'^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})$',
  );

  final int year;
  final int month;
  final int day;

  factory LocalCalendarDate.parse(String text) {
    final RegExpMatch? match = _textPattern.firstMatch(text);
    if (match == null) {
      throw ArgumentError.value(
        text,
        'text',
        'Local Calendar Date must use the exact YYYY-MM-DD format',
      );
    }

    final int year = int.parse(match.namedGroup('year')!);
    final int month = int.parse(match.namedGroup('month')!);
    final int day = int.parse(match.namedGroup('day')!);
    if (year < 1 || month < 1 || month > 12) {
      throw ArgumentError.value(text, 'text', 'must be a Gregorian date');
    }

    final int maximumDay = _daysInMonth(year: year, month: month);
    if (day < 1 || day > maximumDay) {
      throw ArgumentError.value(text, 'text', 'must be a Gregorian date');
    }

    return LocalCalendarDate._(year: year, month: month, day: day);
  }

  String get text {
    final String yearText = year.toString().padLeft(4, '0');
    final String monthText = month.toString().padLeft(2, '0');
    final String dayText = day.toString().padLeft(2, '0');
    return '$yearText-$monthText-$dayText';
  }

  String get monthKey => text.substring(0, 7);

  @override
  int compareTo(LocalCalendarDate other) => text.compareTo(other.text);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LocalCalendarDate &&
            year == other.year &&
            month == other.month &&
            day == other.day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => text;

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
