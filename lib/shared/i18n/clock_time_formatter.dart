typedef ClockTimeParts = ({int hour, int minute});

final class ClockTimeFormatter {
  const ClockTimeFormatter();

  static final RegExp _exactTextPattern = RegExp(
    r'^(?<hour>[01]\d|2[0-3]):(?<minute>[0-5]\d)$',
  );

  String formatComponents({required int hour, required int minute}) {
    _validateComponents(hour: hour, minute: minute);
    final String hourText = hour.toString().padLeft(2, '0');
    final String minuteText = minute.toString().padLeft(2, '0');
    return '$hourText:$minuteText';
  }

  String formatLocalDateTime(DateTime dateTime) {
    if (dateTime.isUtc) {
      throw ArgumentError.value(
        dateTime,
        'dateTime',
        'must use local wall-clock time',
      );
    }
    return formatComponents(hour: dateTime.hour, minute: dateTime.minute);
  }

  ClockTimeParts parse(String text) {
    final RegExpMatch? match = _exactTextPattern.firstMatch(text);
    if (match == null) {
      throw FormatException('Clock time must use the exact HH:mm format', text);
    }
    return (
      hour: int.parse(match.namedGroup('hour')!),
      minute: int.parse(match.namedGroup('minute')!),
    );
  }

  void _validateComponents({required int hour, required int minute}) {
    if (hour < 0 || hour > 23) {
      throw RangeError.range(hour, 0, 23, 'hour');
    }
    if (minute < 0 || minute > 59) {
      throw RangeError.range(minute, 0, 59, 'minute');
    }
  }
}
