import 'package:characters/characters.dart';

final class TodoTitle {
  const TodoTitle._({required this.text, required this.graphemeLength});

  static const int maximumGraphemeLength = 160;
  static const int counterThreshold = 120;
  static final RegExp _lineBreakPattern = RegExp(
    '[\n\r\u000B\u000C\u0085\u2028\u2029]',
  );

  final String text;
  final int graphemeLength;

  factory TodoTitle.parse(String text) {
    final String normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw ArgumentError('Todo Title must not be empty');
    }
    if (_lineBreakPattern.hasMatch(normalizedText)) {
      throw ArgumentError('Todo Title must contain one line');
    }

    final int graphemeLength = normalizedText.characters
        .take(maximumGraphemeLength + 1)
        .length;
    if (graphemeLength > maximumGraphemeLength) {
      throw ArgumentError(
        'Todo Title must contain at most $maximumGraphemeLength graphemes',
      );
    }
    return TodoTitle._(text: normalizedText, graphemeLength: graphemeLength);
  }

  bool get shouldShowCounter => graphemeLength >= counterThreshold;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is TodoTitle && text == other.text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => text;
}
