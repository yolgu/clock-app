import 'package:clock_rhythm/contexts/todo/presentation/todo_dependencies.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('emits a local-date audit when the app resumes', () async {
    final SystemTodoDateClock clock = SystemTodoDateClock();
    final List<DateTime> changes = <DateTime>[];
    final subscription = clock.localDateChanges.listen(changes.add);
    try {
      clock.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(changes, hasLength(1));
      expect(changes.single.isUtc, isFalse);
    } finally {
      await subscription.cancel();
      clock.dispose();
    }
  });
}
