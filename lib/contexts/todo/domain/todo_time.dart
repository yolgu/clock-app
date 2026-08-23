final class TodoTime {
  const TodoTime._({
    required this.hour,
    required this.minute,
    required this.text,
  });

  static final RegExp _textPattern = RegExp(
    r'^(?<hour>[01]\d|2[0-3]):(?<minute>[0-5]\d)$',
  );

  final int hour;
  final int minute;
  final String text;

  factory TodoTime.parse(String text) {
    final RegExpMatch? match = _textPattern.firstMatch(text);
    if (match == null) {
      throw ArgumentError.value(
        text,
        'text',
        'Todo Time must use the exact 24-hour HH:mm format',
      );
    }
    return TodoTime._(
      hour: int.parse(match.namedGroup('hour')!),
      minute: int.parse(match.namedGroup('minute')!),
      text: text,
    );
  }

  static TodoTime? optional(String? text) {
    return text == null ? null : TodoTime.parse(text);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is TodoTime && text == other.text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => text;
}
