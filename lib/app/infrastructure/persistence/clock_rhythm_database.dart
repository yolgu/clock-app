import 'package:drift/drift.dart';

import 'migrations/migration_plan.dart';

part 'clock_rhythm_database.g.dart';

typedef DatabaseMigrationCheckpoint = Future<void> Function();

@DataClassName('PreferenceRecord')
class PreferenceRecords extends Table {
  IntColumn get singletonId => integer().withDefault(const Constant<int>(1))();
  IntColumn get focusMinutes => integer()();
  IntColumn get restMinutes => integer()();
  TextColumn get dailyStart => text()();
  TextColumn get dailyEnd => text()();
  BoolColumn get autoStartEnabled => boolean()();
  TextColumn get soundMode => text()();
  TextColumn get customFileName => text().nullable()();
  RealColumn get soundVolume => real()();
  TextColumn get mutedFromMode => text().nullable()();
  TextColumn get mutedFromFileName => text().nullable()();
  TextColumn get language => text()();
  TextColumn get theme => text()();
  BoolColumn get initialSetupCompleted => boolean()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{singletonId};
}

@DataClassName('TodoRecord')
class TodoRecords extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get localDate => text()();
  TextColumn get displayTime => text().nullable()();
  BoolColumn get completed => boolean()();
  IntColumn get displayOrder => integer()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get storageOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(tables: <Type>[PreferenceRecords, TodoRecords])
final class ClockRhythmDatabase extends _$ClockRhythmDatabase {
  ClockRhythmDatabase(super.executor) : migrationCheckpoint = null;

  ClockRhythmDatabase.forTesting(super.executor, {this.migrationCheckpoint});

  final DatabaseMigrationCheckpoint? migrationCheckpoint;

  @override
  int get schemaVersion => DatabaseSchema.currentVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator migrator) async {
        await transaction(() async {
          await migrator.createAll();
          await migrationCheckpoint?.call();
        });
      },
      onUpgrade: (Migrator migrator, int from, int to) async {
        await transaction(() async {
          if (from < DatabaseSchema.initialVersion ||
              to != DatabaseSchema.currentVersion) {
            throw StateError(
              'No committed database migration exists from $from to $to.',
            );
          }
          await migrationCheckpoint?.call();
        });
      },
    );
  }
}
