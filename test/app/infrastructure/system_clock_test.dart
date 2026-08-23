import 'package:clock_rhythm/app/infrastructure/system_clock.dart';
import 'package:clock_rhythm/contexts/rhythm/public.dart' as rhythm;
import 'package:clock_rhythm/contexts/todo/public.dart' as todo;
import 'package:clock_rhythm/features/data_transfer/public.dart'
    show BackupClock;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adapts one wall-clock source to every application clock port', () {
    final DateTime fixed = DateTime.utc(2026, 8, 23, 2, 45);
    final SystemClock clock = SystemClock(now: () => fixed);
    final rhythm.Clock rhythmClock = clock;
    final todo.Clock todoClock = clock;
    final BackupClock backupClock = clock;

    expect(rhythmClock.now(), fixed);
    expect(todoClock.now(), fixed);
    expect(backupClock.now(), fixed);
  });
}
