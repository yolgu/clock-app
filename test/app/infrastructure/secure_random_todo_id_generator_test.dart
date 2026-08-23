import 'dart:math';

import 'package:clock_rhythm/app/infrastructure/secure_random_todo_id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'creates bounded collision-resistant identifiers without wall-clock IO',
    () {
      final SecureRandomTodoIdGenerator generator = SecureRandomTodoIdGenerator(
        random: Random(20260823),
        now: () => DateTime.utc(2026, 8, 23),
      );

      final Set<String> identifiers = <String>{
        for (int index = 0; index < 512; index += 1) generator.nextId(),
      };

      expect(identifiers, hasLength(512));
      expect(
        identifiers,
        everyElement(matches(RegExp(r'^[0-9a-z]+-[0-9a-f]{32}$'))),
      );
      expect(
        identifiers.every((String identifier) => identifier.length <= 128),
        isTrue,
      );
    },
  );
}
