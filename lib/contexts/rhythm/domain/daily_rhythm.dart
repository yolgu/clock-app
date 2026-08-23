import 'clock_time.dart';

final class DailyRhythm {
  factory DailyRhythm({required ClockTime start, required ClockTime end}) {
    if (start == end) {
      throw ArgumentError.value(
        start,
        'start',
        'Daily Rhythm start and end must differ',
      );
    }
    return DailyRhythm._(start: start, end: end);
  }

  const DailyRhythm._({required this.start, required this.end});

  final ClockTime start;
  final ClockTime end;

  factory DailyRhythm.defaults() {
    return DailyRhythm(
      start: ClockTime.parse('05:00'),
      end: ClockTime.parse('18:00'),
    );
  }

  bool get crossesMidnight => start.totalMinutes > end.totalMinutes;

  int get durationInMinutes {
    final int sameDayDifference = end.totalMinutes - start.totalMinutes;
    return sameDayDifference > 0
        ? sameDayDifference
        : Duration.minutesPerDay + sameDayDifference;
  }

  DailyRhythmWindow windowStartingOn(DateTime localDate) {
    _requireLocal(localDate, 'localDate');
    final DateTime startsAt = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      start.hour,
      start.minute,
    );
    final DateTime endsAt = DateTime(
      localDate.year,
      localDate.month,
      localDate.day + (crossesMidnight ? 1 : 0),
      end.hour,
      end.minute,
    );
    return DailyRhythmWindow._(startsAt: startsAt, endsAt: endsAt);
  }

  DailyRhythmWindow? windowContaining(DateTime moment) {
    _requireLocal(moment, 'moment');
    final DailyRhythmWindow sameDateWindow = windowStartingOn(moment);
    if (sameDateWindow.contains(moment)) {
      return sameDateWindow;
    }
    if (!crossesMidnight) {
      return null;
    }

    final DailyRhythmWindow previousDateWindow = windowStartingOn(
      DateTime(moment.year, moment.month, moment.day - 1),
    );
    return previousDateWindow.contains(moment) ? previousDateWindow : null;
  }

  DailyRhythmWindow windowAtOrAfter(DateTime moment) {
    _requireLocal(moment, 'moment');
    final DailyRhythmWindow? containingWindow = windowContaining(moment);
    if (containingWindow != null) {
      return containingWindow;
    }

    final DailyRhythmWindow sameDateWindow = windowStartingOn(moment);
    return moment.isBefore(sameDateWindow.startsAt)
        ? sameDateWindow
        : nextWindowAfter(sameDateWindow);
  }

  DailyRhythmWindow nextWindowAfter(DailyRhythmWindow window) {
    return windowStartingOn(
      DateTime(
        window.startsAt.year,
        window.startsAt.month,
        window.startsAt.day + 1,
      ),
    );
  }

  DateTime nextStartAfter(DateTime moment) {
    _requireLocal(moment, 'moment');
    final DateTime sameDateStart = windowStartingOn(moment).startsAt;
    if (moment.isBefore(sameDateStart)) {
      return sameDateStart;
    }
    return nextWindowAfter(windowStartingOn(moment)).startsAt;
  }

  DateTime nextStartAtOrAfter(DateTime moment) {
    _requireLocal(moment, 'moment');
    final DateTime sameDateStart = windowStartingOn(moment).startsAt;
    if (!moment.isAfter(sameDateStart)) {
      return sameDateStart;
    }
    return nextWindowAfter(windowStartingOn(moment)).startsAt;
  }

  static void _requireLocal(DateTime value, String name) {
    if (value.isUtc) {
      throw ArgumentError.value(value, name, 'must be a local DateTime');
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DailyRhythm && start == other.start && end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

final class DailyRhythmWindow {
  const DailyRhythmWindow._({required this.startsAt, required this.endsAt});

  final DateTime startsAt;
  final DateTime endsAt;

  bool contains(DateTime moment) {
    if (moment.isUtc) {
      throw ArgumentError.value(moment, 'moment', 'must be a local DateTime');
    }
    return !moment.isBefore(startsAt) && !moment.isAfter(endsAt);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DailyRhythmWindow &&
            startsAt == other.startsAt &&
            endsAt == other.endsAt;
  }

  @override
  int get hashCode => Object.hash(startsAt, endsAt);
}
