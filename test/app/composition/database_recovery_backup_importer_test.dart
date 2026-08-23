import 'dart:io';

import 'package:clock_rhythm/app/composition/database_recovery_backup_importer.dart';
import 'package:clock_rhythm/app/infrastructure/device_state/device_sound_locator_store.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/database_connection.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/database_failure.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/database_recovery_file_manager.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/database_startup.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/repositories/drift_settings_repository.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/repositories/drift_todo_repository.dart';
import 'package:clock_rhythm/app/infrastructure/platform/platform_preferences_repair_registry.dart';
import 'package:clock_rhythm/contexts/preferences/public.dart';
import 'package:clock_rhythm/contexts/todo/public_model.dart';
import 'package:clock_rhythm/features/data_transfer/infrastructure/json/backup_v1_codec.dart';
import 'package:clock_rhythm/features/data_transfer/public.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'imports a validated backup after preserving the failed database',
    () async {
      final _RecoveryFixture fixture = await _RecoveryFixture.create();
      addTearDown(fixture.dispose);

      final PreparedBackupImport? prepared = await fixture.importer.prepare();

      expect(prepared, isNotNull);
      expect(prepared!.preview.todoCount, 1);
      expect(
        await File(fixture.databasePath).readAsString(),
        'broken database',
      );
      expect(fixture.draft.value, isNull);
      expect(fixture.autoStart.calls, 0);
      expect(
        Directory(fixture.temporary.path).listSync().whereType<Directory>(),
        isEmpty,
      );

      final DatabaseReady ready = await fixture.importer.confirm(
        fixture.recovery,
        prepared,
      );

      final DriftSettingsRepository settings = DriftSettingsRepository(
        ready.database,
        deviceSoundLocatorStore: fixture.deviceState,
      );
      expect((await settings.load()).language, LanguagePreference.english);
      expect(
        (await DriftTodoRepository(ready.database).getAll()).single.id.text,
        'imported',
      );
      expect(fixture.draft.value, isNotNull);
      expect(fixture.autoStart.desired, isTrue);
      expect(
        Directory(
          fixture.temporary.path,
        ).listSync().whereType<Directory>().where(
          (Directory directory) => directory.path.contains('.recovery-'),
        ),
        isNotEmpty,
      );
      await ready.database.close();
    },
  );

  test(
    'a post-replacement draft failure restores every prior source',
    () async {
      final _RecoveryFixture fixture = await _RecoveryFixture.create();
      addTearDown(fixture.dispose);
      fixture.draft.failAfterNextSave = StateError('draft failed after write');
      final PreparedBackupImport prepared = (await fixture.importer.prepare())!;

      await expectLater(
        fixture.importer.confirm(fixture.recovery, prepared),
        throwsStateError,
      );

      expect(
        await File(fixture.databasePath).readAsString(),
        'broken database',
      );
      expect(fixture.draft.value, isNull);
      expect(fixture.deviceState.state, DeviceSoundLocatorState.empty);
      expect(fixture.autoStart.calls, 0);
      expect(
        Directory(
          fixture.temporary.path,
        ).listSync().whereType<Directory>().where(
          (Directory directory) => directory.path.contains('.failed-reset-'),
        ),
        isNotEmpty,
      );
    },
  );
}

final class _RecoveryFixture {
  _RecoveryFixture._({
    required this.temporary,
    required this.databasePath,
    required this.deviceState,
    required this.draft,
    required this.autoStart,
    required this.repairState,
    required this.importer,
  });

  final Directory temporary;
  final String databasePath;
  final _MemoryDeviceSoundLocatorStore deviceState;
  final _MemoryDraftStore draft;
  final _RecordingAutoStart autoStart;
  final PlatformPreferencesRepairRegistry repairState;
  final DatabaseRecoveryBackupImporter importer;

  DatabaseRecoveryRequired get recovery => DatabaseRecoveryRequired(
    failure: const DatabaseFailure(
      kind: DatabaseFailureKind.openOrIntegrity,
      causeType: 'CorruptFixture',
    ),
    databasePath: databasePath,
  );

  static Future<_RecoveryFixture> create() async {
    final Directory temporary = await Directory.systemTemp.createTemp(
      'clock-rhythm-recovery-import-',
    );
    final String databasePath =
        '${temporary.path}${Platform.pathSeparator}clock_rhythm.sqlite';
    await File(databasePath).writeAsString('broken database');
    final BackupV1Codec codec = const BackupV1Codec();
    final UserPreferences importedPreferences = UserPreferences.defaults()
        .changeLanguage(LanguagePreference.english)
        .changeAutoStart(true);
    final Todo importedTodo = Todo.restore(
      const TodoRestoreSnapshot(
        id: 'imported',
        title: 'Imported',
        date: '2026-08-23',
        time: null,
        completed: false,
        displayOrder: 0,
        createdAt: '2026-08-23T00:00:00.000Z',
        updatedAt: '2026-08-23T00:00:00.000Z',
      ),
    );
    final List<int> bytes = codec.encode(
      PortableBackupData(
        exportedAt: DateTime.utc(2026, 8, 23),
        preferences: importedPreferences,
        todos: <Todo>[importedTodo],
        customSoundWasSanitized: false,
      ),
    );
    final _MemoryDeviceSoundLocatorStore deviceState =
        _MemoryDeviceSoundLocatorStore();
    final _MemoryDraftStore draft = _MemoryDraftStore();
    final _RecordingAutoStart autoStart = _RecordingAutoStart();
    final PlatformPreferencesRepairRegistry repairState =
        PlatformPreferencesRepairRegistry();
    final DatabaseStartup startup = DatabaseStartup(
      connectionFactory: _FileDatabaseConnectionFactory(databasePath),
      deviceSoundLocatorStore: deviceState,
    );
    return _RecoveryFixture._(
      temporary: temporary,
      databasePath: databasePath,
      deviceState: deviceState,
      draft: draft,
      autoStart: autoStart,
      repairState: repairState,
      importer: DatabaseRecoveryBackupImporter(
        databaseStartup: startup,
        fileManager: DatabaseRecoveryFileManager(
          now: () => DateTime.utc(2026, 8, 23, 4),
        ),
        backupFile: _MemoryBackupFile(bytes),
        codec: codec,
        autoStart: autoStart,
        deviceSoundLocatorStore: deviceState,
        draftStore: draft,
        repairState: repairState,
      ),
    );
  }

  Future<void> dispose() async {
    await repairState.dispose();
    if (temporary.existsSync()) {
      await temporary.delete(recursive: true);
    }
  }
}

final class _FileDatabaseConnectionFactory
    implements DatabaseConnectionFactory {
  const _FileDatabaseConnectionFactory(this.path);

  final String path;

  @override
  Future<QueryExecutor> open(String databasePath) async {
    return NativeDatabase(File(databasePath));
  }

  @override
  Future<String> resolveDatabasePath() async => path;
}

final class _MemoryBackupFile implements BackupFilePort {
  const _MemoryBackupFile(this.bytes);

  final List<int> bytes;

  @override
  Future<BackupFileContent?> pickImport({required int maximumBytes}) async {
    return BackupFileContent(bytes);
  }

  @override
  Future<bool> saveExport({
    required String suggestedFileName,
    required List<int> bytes,
  }) async {
    return true;
  }
}

final class _MemoryDeviceSoundLocatorStore implements DeviceSoundLocatorStore {
  DeviceSoundLocatorState state = DeviceSoundLocatorState.empty;

  @override
  Future<DeviceSoundLocatorState> load() async => state;

  @override
  Future<void> save(DeviceSoundLocatorState state) async {
    this.state = state;
  }
}

final class _MemoryDraftStore implements DraftStore {
  RhythmSettingsDraft? value;
  Object? failAfterNextSave;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<RhythmSettingsDraft?> load() async => value;

  @override
  Future<void> save(RhythmSettingsDraft draft) async {
    value = draft;
    final Object? failure = failAfterNextSave;
    failAfterNextSave = null;
    if (failure != null) {
      throw failure;
    }
  }
}

final class _RecordingAutoStart implements AutoStartPort {
  int calls = 0;
  bool? desired;

  @override
  Future<AutoStartReconciliation> reconcile({
    required bool desiredEnabled,
  }) async {
    calls += 1;
    desired = desiredEnabled;
    return AutoStartReconciliation(
      desiredEnabled: desiredEnabled,
      actualEnabled: desiredEnabled,
    );
  }
}
