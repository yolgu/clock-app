final class DurationMinutes {
  const DurationMinutes._(this.minutes);

  static const int minimum = 1;
  static const int maximumFocus = 180;
  static const int maximumRest = 60;

  final int minutes;

  factory DurationMinutes.focus(int minutes) {
    return DurationMinutes._validated(
      minutes: minutes,
      maximum: maximumFocus,
      role: 'Focus',
    );
  }

  factory DurationMinutes.rest(int minutes) {
    return DurationMinutes._validated(
      minutes: minutes,
      maximum: maximumRest,
      role: 'Rest',
    );
  }

  factory DurationMinutes._validated({
    required int minutes,
    required int maximum,
    required String role,
  }) {
    if (minutes < minimum || minutes > maximum) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        '$role duration must be between $minimum and $maximum minutes',
      );
    }
    return DurationMinutes._(minutes);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DurationMinutes && minutes == other.minutes;
  }

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => '$minutes min';
}
