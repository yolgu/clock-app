import 'dart:math';

import '../../contexts/todo/public.dart' show TodoIdGenerator;

final class SecureRandomTodoIdGenerator implements TodoIdGenerator {
  SecureRandomTodoIdGenerator({Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final Random _random;
  final DateTime Function() _now;

  @override
  String nextId() {
    final String instant = _now().toUtc().microsecondsSinceEpoch.toRadixString(
      36,
    );
    final StringBuffer entropy = StringBuffer();
    for (int index = 0; index < 16; index += 1) {
      entropy.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return '$instant-$entropy';
  }
}
