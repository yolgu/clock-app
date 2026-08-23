import 'package:clock_rhythm/contexts/todo/domain/todo_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trims a meaningful single-line title', () {
    final TodoTitle title = TodoTitle.parse('  오늘 과제  ');

    expect(title.text, '오늘 과제');
    expect(title.graphemeLength, 5);
  });

  test('counts extended emoji and combining sequences as one grapheme', () {
    const List<String> graphemes = <String>[
      '👨‍👩‍👧‍👦',
      '👍🏽',
      '🇰🇷',
      'e\u0301',
      'क्‍ष',
    ];

    for (final String grapheme in graphemes) {
      expect(
        TodoTitle.parse(grapheme).graphemeLength,
        1,
        reason: '$grapheme must be one user-perceived character',
      );
    }
  });

  test('does not join Indic linkers to consonants from another script', () {
    expect(TodoTitle.parse('क्a').graphemeLength, 2);
    expect(TodoTitle.parse('a\u094D\u0924').graphemeLength, 2);
  });

  test('accepts exactly 160 user-perceived characters', () {
    final String text = List<String>.filled(
      TodoTitle.maximumGraphemeLength,
      '👨‍👩‍👧‍👦',
    ).join();

    final TodoTitle title = TodoTitle.parse(text);

    expect(title.graphemeLength, TodoTitle.maximumGraphemeLength);
  });

  test('rejects the 161st user-perceived character', () {
    final String text = List<String>.filled(
      TodoTitle.maximumGraphemeLength + 1,
      '👍🏽',
    ).join();

    expect(() => TodoTitle.parse(text), throwsArgumentError);
  });

  test('rejects an empty or multiline normalized title', () {
    expect(() => TodoTitle.parse('   '), throwsArgumentError);
    expect(() => TodoTitle.parse('first\nsecond'), throwsArgumentError);
    expect(() => TodoTitle.parse('first\u2028second'), throwsArgumentError);
  });

  test('does not include a rejected Todo title in its failure text', () {
    const String privateTitle = 'private title\nsecond line';

    expect(
      () => TodoTitle.parse(privateTitle),
      throwsA(
        isA<ArgumentError>().having(
          (ArgumentError error) => error.toString(),
          'message',
          isNot(contains('private title')),
        ),
      ),
    );
  });

  test('publishes the counter threshold and measured grapheme length', () {
    final TodoTitle belowThreshold = TodoTitle.parse('가' * 119);
    final TodoTitle atThreshold = TodoTitle.parse('가' * 120);

    expect(TodoTitle.counterThreshold, 120);
    expect(belowThreshold.shouldShowCounter, isFalse);
    expect(atThreshold.shouldShowCounter, isTrue);
    expect(atThreshold.graphemeLength, 120);
  });

  test('compares normalized titles by value', () {
    expect(TodoTitle.parse('  과제'), TodoTitle.parse('과제  '));
    expect(TodoTitle.parse('과제').hashCode, TodoTitle.parse('과제').hashCode);
  });
}
