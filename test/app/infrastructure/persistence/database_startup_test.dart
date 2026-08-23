import 'dart:io';

import 'package:clock_rhythm/app/infrastructure/persistence/clock_rhythm_database.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/database_connection.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/database_failure.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/database_startup.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/repositories/drift_settings_repository.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/repositories/drift_todo_repository.dart';
import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/todo/public_model.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_device_sound_locator_store.dart';

void main() {
  test('opens a healthy database as Ready', () async {
    final DatabaseStartup startup = DatabaseStartup(
      connectionFactory: FixedDatabaseConnectionFactory(
        path: ':memory:',
        executor: NativeDatabase.memory(),
      ),
    );

    final DatabaseStartupState state = await startup.open();

    expect(state, isA<DatabaseReady>());
    await (state as DatabaseReady).database.close();
  });

  test(
    'corruption returns recovery state and preserves the original file',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'clock-rhythm-corrupt-db-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final File databaseFile = File(
        '${directory.path}${Platform.pathSeparator}clock_rhythm.sqlite',
      );
      final List<int> originalBytes = List<int>.generate(
        512,
        (int index) => (index * 37) % 256,
      );
      await databaseFile.writeAsBytes(originalBytes, flush: true);
      final DatabaseStartup startup = DatabaseStartup(
        connectionFactory: FixedDatabaseConnectionFactory(
          path: databaseFile.path,
          executor: NativeDatabase(databaseFile),
        ),
      );

      final DatabaseStartupState state = await startup.open();

      expect(state, isA<DatabaseRecoveryRequired>());
      final DatabaseRecoveryRequired recovery =
          state as DatabaseRecoveryRequired;
      expect(recovery.databasePath, databaseFile.path);
      expect(recovery.failure.kind, DatabaseFailureKind.openOrIntegrity);
      expect(await databaseFile.readAsBytes(), originalBytes);
    },
  );

  test(
    'cold create and reopen preserve schema version and durable data',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'clock-rhythm-reopen-db-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final File databaseFile = File(
        '${directory.path}${Platform.pathSeparator}clock_rhythm.sqlite',
      );
      final UserPreferences expected = UserPreferences.defaults().changeTheme(
        ThemePreference.nord,
      );

      final DatabaseStartupState firstState = await DatabaseStartup(
        connectionFactory: FixedDatabaseConnectionFactory(
          path: databaseFile.path,
          executor: NativeDatabase(databaseFile),
        ),
      ).open();
      final DatabaseReady firstReady = firstState as DatabaseReady;
      final MemoryDeviceSoundLocatorStore deviceSoundLocatorStore =
          MemoryDeviceSoundLocatorStore();
      await DriftSettingsRepository(
        firstReady.database,
        deviceSoundLocatorStore: deviceSoundLocatorStore,
      ).save(expected);
      await firstReady.database.close();

      final DatabaseStartupState reopenedState = await DatabaseStartup(
        connectionFactory: FixedDatabaseConnectionFactory(
          path: databaseFile.path,
          executor: NativeDatabase(databaseFile),
        ),
      ).open();
      final DatabaseReady reopened = reopenedState as DatabaseReady;
      addTearDown(reopened.database.close);
      final int schemaVersion = await reopened.database
          .customSelect('PRAGMA user_version')
          .map((row) => row.read<int>('user_version'))
          .getSingle();

      expect(schemaVersion, 1);
      expect(
        await DriftSettingsRepository(
          reopened.database,
          deviceSoundLocatorStore: deviceSoundLocatorStore,
        ).load(),
        expected,
      );
    },
  );

  test(
    'future schema enters recovery without opening the migration connection',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'clock-rhythm-future-db-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final File databaseFile = await _createHealthyDatabase(directory);
      await _setUserVersion(databaseFile, 2);
      final List<int> originalBytes = await databaseFile.readAsBytes();
      final TrackingDatabaseConnectionFactory connectionFactory =
          TrackingDatabaseConnectionFactory(
            path: databaseFile.path,
            executor: NativeDatabase(databaseFile),
          );

      final DatabaseStartupState state = await DatabaseStartup(
        connectionFactory: connectionFactory,
      ).open();

      expect(state, isA<DatabaseRecoveryRequired>());
      final DatabaseRecoveryRequired recovery =
          state as DatabaseRecoveryRequired;
      expect(recovery.failure.kind, DatabaseFailureKind.unsupportedVersion);
      expect(connectionFactory.openCalls, 0);
      expect(await _readUserVersion(databaseFile), 2);
      expect(await databaseFile.readAsBytes(), originalBytes);
    },
  );

  test('invalid current-v1 Preferences row enters recovery', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'clock-rhythm-invalid-preferences-db-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final File databaseFile = await _createHealthyDatabase(directory);
    await _executeWithoutMigrations(
      databaseFile,
      (ClockRhythmDatabase database) => database.customStatement(
        'UPDATE preference_records SET language = ?',
        <Object?>['unsupported'],
      ),
    );

    final DatabaseStartupState state = await DatabaseStartup(
      connectionFactory: FixedDatabaseConnectionFactory(
        path: databaseFile.path,
        executor: NativeDatabase(databaseFile),
      ),
    ).open();

    expect(state, isA<DatabaseRecoveryRequired>());
    expect(
      (state as DatabaseRecoveryRequired).failure.kind,
      DatabaseFailureKind.migrationOrData,
    );
  });

  test('invalid current-v1 Todo row enters recovery', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'clock-rhythm-invalid-todo-db-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final File databaseFile = await _createHealthyDatabase(
      directory,
      todo: Todo.restore(
        const TodoRestoreSnapshot(
          id: 'invalid-on-startup',
          title: 'Todo',
          date: '2026-08-23',
          time: null,
          completed: false,
          displayOrder: 0,
          createdAt: '2026-08-23T00:00:00.000Z',
          updatedAt: '2026-08-23T00:00:00.000Z',
        ),
      ),
    );
    await _executeWithoutMigrations(
      databaseFile,
      (ClockRhythmDatabase database) => database.customStatement(
        'UPDATE todo_records SET local_date = ?',
        <Object?>['2026-02-30'],
      ),
    );

    final DatabaseStartupState state = await DatabaseStartup(
      connectionFactory: FixedDatabaseConnectionFactory(
        path: databaseFile.path,
        executor: NativeDatabase(databaseFile),
      ),
    ).open();

    expect(state, isA<DatabaseRecoveryRequired>());
    expect(
      (state as DatabaseRecoveryRequired).failure.kind,
      DatabaseFailureKind.migrationOrData,
    );
  });

  test('failed migration preserves the v0 database and its data', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'clock-rhythm-failed-migration-db-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final UserPreferences expected = UserPreferences.defaults().changeTheme(
      ThemePreference.nord,
    );
    final File databaseFile = await _createHealthyDatabase(
      directory,
      preferences: expected,
    );
    await _setUserVersion(databaseFile, 0);

    final DatabaseStartupState state = await DatabaseStartup(
      connectionFactory: FixedDatabaseConnectionFactory(
        path: databaseFile.path,
        executor: NativeDatabase(databaseFile),
      ),
      databaseFactory: (QueryExecutor executor) =>
          ClockRhythmDatabase.forTesting(
            executor,
            migrationCheckpoint: () async {
              throw StateError('injected migration failure');
            },
          ),
    ).open();

    expect(state, isA<DatabaseRecoveryRequired>());
    expect(await _readUserVersion(databaseFile), 0);
    final String theme = await _querySingleStringWithoutMigrations(
      databaseFile,
      'SELECT theme FROM preference_records WHERE singleton_id = 1',
      'theme',
    );
    expect(theme, expected.theme.id);
  });
}

Future<File> _createHealthyDatabase(
  Directory directory, {
  UserPreferences? preferences,
  Todo? todo,
}) async {
  final File databaseFile = File(
    '${directory.path}${Platform.pathSeparator}clock_rhythm.sqlite',
  );
  final ClockRhythmDatabase database = ClockRhythmDatabase.forTesting(
    NativeDatabase(databaseFile),
  );
  await DriftSettingsRepository(
    database,
    deviceSoundLocatorStore: MemoryDeviceSoundLocatorStore(),
  ).save(preferences ?? UserPreferences.defaults());
  if (todo != null) {
    await DriftTodoRepository(database).saveAll(<Todo>[todo]);
  }
  await database.close();
  return databaseFile;
}

Future<void> _setUserVersion(File databaseFile, int version) {
  return _executeWithoutMigrations(
    databaseFile,
    (ClockRhythmDatabase database) =>
        database.customStatement('PRAGMA user_version = $version'),
  );
}

Future<int> _readUserVersion(File databaseFile) async {
  final String value = await _querySingleStringWithoutMigrations(
    databaseFile,
    'PRAGMA user_version',
    'user_version',
  );
  return int.parse(value);
}

Future<String> _querySingleStringWithoutMigrations(
  File databaseFile,
  String statement,
  String column,
) async {
  String? result;
  await _executeWithoutMigrations(databaseFile, (
    ClockRhythmDatabase database,
  ) async {
    final QueryRow row = await database.customSelect(statement).getSingle();
    result = row.data[column].toString();
  });
  return result!;
}

Future<void> _executeWithoutMigrations(
  File databaseFile,
  Future<void> Function(ClockRhythmDatabase database) action,
) async {
  final ClockRhythmDatabase database = ClockRhythmDatabase.forTesting(
    NativeDatabase(databaseFile, enableMigrations: false),
  );
  try {
    await action(database);
  } finally {
    await database.close();
  }
}

final class TrackingDatabaseConnectionFactory
    implements DatabaseConnectionFactory {
  TrackingDatabaseConnectionFactory({
    required this.path,
    required this.executor,
  });

  final String path;
  final QueryExecutor executor;
  int openCalls = 0;

  @override
  Future<String> resolveDatabasePath() async => path;

  @override
  Future<QueryExecutor> open(String databasePath) async {
    openCalls += 1;
    return executor;
  }
}
