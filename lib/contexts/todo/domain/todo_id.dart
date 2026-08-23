final class TodoId implements Comparable<TodoId> {
  const TodoId._(this.text);

  static const int maximumLength = 128;

  final String text;

  factory TodoId.parse(String text) {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'Todo ID must not be empty');
    }
    if (text.runes.length > maximumLength) {
      throw ArgumentError.value(
        text,
        'text',
        'Todo ID must contain at most $maximumLength characters',
      );
    }
    return TodoId._(text);
  }

  @override
  int compareTo(TodoId other) => text.compareTo(other.text);

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is TodoId && text == other.text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => text;
}
