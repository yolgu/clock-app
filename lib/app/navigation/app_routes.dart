enum MainDestination {
  clock('/clock'),
  calendar('/calendar'),
  data('/data'),
  theme('/theme'),
  settings('/settings');

  const MainDestination(this.location);

  final String location;
}

final class AppCalendarDate {
  const AppCalendarDate._({
    required this.year,
    required this.month,
    required this.day,
  });

  static final RegExp _pattern = RegExp(
    r'^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})$',
  );

  final int year;
  final int month;
  final int day;

  factory AppCalendarDate.parse(String source) {
    final RegExpMatch? match = _pattern.firstMatch(source);
    if (match == null) {
      throw FormatException('Calendar date must use YYYY-MM-DD.', source);
    }
    final int year = int.parse(match.namedGroup('year')!);
    final int month = int.parse(match.namedGroup('month')!);
    final int day = int.parse(match.namedGroup('day')!);
    if (year == 0) {
      throw FormatException(
        'Calendar date year must be between 0001 and 9999.',
        source,
      );
    }
    final DateTime normalized = DateTime(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw FormatException(
        'Calendar date is not a real Gregorian date.',
        source,
      );
    }
    return AppCalendarDate._(year: year, month: month, day: day);
  }

  String get iso8601 {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppCalendarDate &&
            year == other.year &&
            month == other.month &&
            day == other.day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso8601;
}

final class AppRoute {
  const AppRoute._({required this.destination, this.calendarDate});

  final MainDestination destination;
  final AppCalendarDate? calendarDate;

  factory AppRoute.forDestination(MainDestination destination) {
    return AppRoute._(destination: destination);
  }

  factory AppRoute.calendar([AppCalendarDate? date]) {
    return AppRoute._(
      destination: MainDestination.calendar,
      calendarDate: date,
    );
  }

  String get location {
    final AppCalendarDate? selectedDate = calendarDate;
    if (destination != MainDestination.calendar || selectedDate == null) {
      return destination.location;
    }
    return Uri(
      path: destination.location,
      queryParameters: <String, String>{'date': selectedDate.iso8601},
    ).toString();
  }
}
