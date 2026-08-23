final class ClockTime {
  const ClockTime._(this.totalMinutes);

  static final RegExp _textPattern = RegExp(
    r'^(?<hour>[01]\d|2[0-3]):(?<minute>[0-5]\d)$',
  );

  final int totalMinutes;

  factory ClockTime.parse(String text) {
    final RegExpMatch? match = _textPattern.firstMatch(text);
    if (match == null) {
      throw ArgumentError.value(
        text,
        'text',
        'must use the exact 24-hour HH:mm format',
      );
    }

    return ClockTime.fromComponents(
      hour: int.parse(match.namedGroup('hour')!),
      minute: int.parse(match.namedGroup('minute')!),
    );
  }

  factory ClockTime.fromComponents({required int hour, required int minute}) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be between 0 and 23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'must be between 0 and 59');
    }
    return ClockTime._(hour * Duration.minutesPerHour + minute);
  }

  int get hour => totalMinutes ~/ Duration.minutesPerHour;

  int get minute => totalMinutes % Duration.minutesPerHour;

  String get text {
    final String hourText = hour.toString().padLeft(2, '0');
    final String minuteText = minute.toString().padLeft(2, '0');
    return '$hourText:$minuteText';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ClockTime && totalMinutes == other.totalMinutes;
  }

  @override
  int get hashCode => totalMinutes.hashCode;

  @override
  String toString() => text;
}
