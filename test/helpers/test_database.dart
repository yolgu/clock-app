import 'package:clock_rhythm/app/infrastructure/persistence/clock_rhythm_database.dart';
import 'package:drift/native.dart';

final class TestDatabase {
  TestDatabase._(this.database);

  final ClockRhythmDatabase database;

  factory TestDatabase.open() {
    return TestDatabase._(
      ClockRhythmDatabase.forTesting(NativeDatabase.memory()),
    );
  }

  Future<void> close() {
    return database.close();
  }
}
