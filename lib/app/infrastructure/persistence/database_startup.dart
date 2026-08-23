import 'package:drift/drift.dart';

import '../device_state/device_sound_locator_store.dart';
import 'clock_rhythm_database.dart';
import 'database_connection.dart';
import 'database_failure.dart';
import 'database_inspector.dart';
import 'migrations/migration_plan.dart';
import 'repositories/drift_settings_repository.dart';
import 'repositories/drift_todo_repository.dart';

typedef ClockRhythmDatabaseFactory =
    ClockRhythmDatabase Function(QueryExecutor executor);

sealed class DatabaseStartupState {
  const DatabaseStartupState();
}

final class DatabaseReady extends DatabaseStartupState {
  const DatabaseReady({required this.database, required this.databasePath});

  final ClockRhythmDatabase database;
  final String databasePath;
}

final class DatabaseRecoveryRequired extends DatabaseStartupState {
  const DatabaseRecoveryRequired({
    required this.failure,
    required this.databasePath,
  });

  final DatabaseFailure failure;
  final String? databasePath;
}

final class DatabaseStartup {
  const DatabaseStartup({
    required this.connectionFactory,
    this.databaseInspector = const NativeDatabaseInspector(),
    this.databaseFactory = ClockRhythmDatabase.new,
    this.deviceSoundLocatorStore =
        const SharedPreferencesDeviceSoundLocatorStore(),
  });

  final DatabaseConnectionFactory connectionFactory;
  final DatabaseInspector databaseInspector;
  final ClockRhythmDatabaseFactory databaseFactory;
  final DeviceSoundLocatorStore deviceSoundLocatorStore;

  Future<DatabaseStartupState> open() async {
    final String databasePath;
    try {
      databasePath = await connectionFactory.resolveDatabasePath();
    } on Object catch (error) {
      return DatabaseRecoveryRequired(
        failure: DatabaseFailure(
          kind: DatabaseFailureKind.location,
          causeType: error.runtimeType.toString(),
        ),
        databasePath: null,
      );
    }

    try {
      final DatabaseInspection? inspection = await databaseInspector
          .inspectExisting(databasePath);
      if (inspection != null) {
        if (inspection.userVersion > DatabaseSchema.currentVersion) {
          return DatabaseRecoveryRequired(
            failure: const DatabaseFailure(
              kind: DatabaseFailureKind.unsupportedVersion,
              causeType: 'UnsupportedDatabaseVersion',
            ),
            databasePath: databasePath,
          );
        }
        if (!inspection.isIntegrityValid) {
          throw const FormatException('SQLite integrity check failed.');
        }
      }
    } on Object catch (error) {
      return DatabaseRecoveryRequired(
        failure: DatabaseFailure(
          kind: DatabaseFailureKind.openOrIntegrity,
          causeType: error.runtimeType.toString(),
        ),
        databasePath: databasePath,
      );
    }

    ClockRhythmDatabase? database;
    try {
      final QueryExecutor executor = await connectionFactory.open(databasePath);
      database = databaseFactory(executor);
      final List<QueryRow> rows = await database
          .customSelect('PRAGMA integrity_check(1)')
          .get();
      final String? result = rows.singleOrNull?.data.values.singleOrNull
          ?.toString();
      if (result != 'ok') {
        throw const FormatException('SQLite integrity check failed.');
      }
      await DriftSettingsRepository(
        database,
        deviceSoundLocatorStore: deviceSoundLocatorStore,
      ).load();
      await DriftTodoRepository(database).getAll();
      return DatabaseReady(database: database, databasePath: databasePath);
    } on Object catch (error) {
      if (database != null) {
        try {
          await database.close();
        } on Object {
          // The recovery result must survive a secondary close failure.
        }
      }
      return DatabaseRecoveryRequired(
        failure: DatabaseFailure(
          kind: DatabaseFailureKind.migrationOrData,
          causeType: error.runtimeType.toString(),
        ),
        databasePath: databasePath,
      );
    }
  }
}
