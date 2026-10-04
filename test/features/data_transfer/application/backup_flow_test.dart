import 'dart:convert';
import 'dart:io';

import 'package:clock_rhythm/contexts/preferences/public.dart';
import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:clock_rhythm/features/data_transfer/application/backup_failure.dart';
import 'package:clock_rhythm/features/data_transfer/application/confirm_backup_import.dart';
import 'package:clock_rhythm/features/data_transfer/application/export_portable_backup.dart';
import 'package:clock_rhythm/features/data_transfer/application/ports.dart';
import 'package:clock_rhythm/features/data_transfer/application/prepare_backup_import.dart';
import 'package:clock_rhythm/features/data_transfer/infrastructure/json/backup_v1_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prepare validates everything and builds a redacted preview', () async {
    final BackupHarness harness = BackupHarness(
      importBytes: File(
        'test/fixtures/backups/neutralino-v1-full.json',
      ).readAsBytesSync(),
    );

    final PreparedBackupImport prepared = (await harness.prepare.execute())!;

    expect(harness.file.maximumRequestedBytes, BackupV1Codec.maximumBytes);
    expect(prepared.preview.todoCount, 2);
    expect(prepared.preview.completedTodoCount, 1);
    expect(prepared.preview.earliestTodoDate, '2026-06-02');
    expect(prepared.preview.latestTodoDate, '2026-06-03');
    expect(prepared.preview.languageId, 'en');
    expect(prepared.preview.themeId, 'nord');
    expect(prepared.preview.autoStartWillChange, isTrue);
    expect(prepared.preview.customSoundWasSanitized, isTrue);
    expect(prepared.preview.toString(), isNot(contains('Portable task')));
    expect(harness.calls, <String>['file.pick', 'preferences.load']);
  });

  test('cancel does not touch durable or Rhythm state', () async {
    final BackupHarness harness = BackupHarness(importBytes: null);

    expect(await harness.prepare.execute(), isNull);

    expect(harness.calls, <String>['file.pick']);
  });

  test(
    'LB-149 prepare rejects invalid JSON and unsupported versions before state changes',
    () async {
      final BackupHarness invalidJson = BackupHarness(
        importBytes: utf8.encode('{'),
      );

      await expectLater(
        invalidJson.prepare.execute(),
        throwsA(
          isA<BackupFailure>().having(
            (BackupFailure failure) => failure.key,
            'key',
            BackupFailureKey.invalidJson,
          ),
        ),
      );
      expect(invalidJson.calls, <String>['file.pick']);
      expect(invalidJson.rhythm.stopped, isFalse);
      expect(invalidJson.replacement.replaceCalls, 0);

      final BackupHarness unsupportedVersion = BackupHarness(
        importBytes: File(
          'test/fixtures/backups/invalid-unknown-version.json',
        ).readAsBytesSync(),
      );

      await expectLater(
        unsupportedVersion.prepare.execute(),
        throwsA(
          isA<BackupFailure>().having(
            (BackupFailure failure) => failure.key,
            'key',
            BackupFailureKey.unsupportedSchemaVersion,
          ),
        ),
      );
      expect(unsupportedVersion.calls, <String>['file.pick']);
      expect(unsupportedVersion.rhythm.stopped, isFalse);
      expect(unsupportedVersion.replacement.replaceCalls, 0);
    },
  );

  test(
    'LB-151 confirming an empty Todo backup fully clears the prior collection',
    () async {
      final BackupHarness harness = BackupHarness(
        importBytes: File(
          'test/fixtures/backups/neutralino-v1-minimal.json',
        ).readAsBytesSync(),
      );
      harness.replacement.currentTodos = <Todo>[
        _todo(id: 'existing', title: 'Existing Todo'),
      ];
      final PreparedBackupImport prepared = (await harness.prepare.execute())!;
      harness.calls.clear();

      await harness.confirm.execute(prepared);

      expect(harness.replacement.currentTodos, isEmpty);
      expect(harness.replacement.replaceCalls, 1);
      expect(harness.calls, <String>['rhythm.stop', 'replacement.replace']);
    },
  );

  test(
    'LB-152 missing Preferences or Todos rejects before replacing local data',
    () async {
      for (final String missingField in <String>['preferences', 'todos']) {
        final Todo existing = _todo(
          id: 'existing-$missingField',
          title: 'Existing Todo',
        );
        final BackupHarness harness = BackupHarness(
          importBytes: _backupMissing(missingField),
        );
        harness.replacement.currentTodos = <Todo>[existing];

        await expectLater(
          harness.prepare.execute(),
          throwsA(
            isA<BackupFailure>().having(
              (BackupFailure failure) => failure.key,
              'key',
              BackupFailureKey.missingRequiredData,
            ),
          ),
        );

        expect(harness.replacement.currentTodos, <Todo>[existing]);
        expect(harness.replacement.replaceCalls, 0);
        expect(harness.rhythm.stopped, isFalse);
        expect(harness.calls, <String>['file.pick']);
      }
    },
  );

  test('confirm stops Rhythm before atomic replacement', () async {
    final BackupHarness harness = BackupHarness(
      importBytes: File(
        'test/fixtures/backups/neutralino-v1-minimal.json',
      ).readAsBytesSync(),
    );
    final PreparedBackupImport prepared = (await harness.prepare.execute())!;
    harness.calls.clear();

    final ConfirmBackupImportResult result = await harness.confirm.execute(
      prepared,
    );

    expect(result.autoStartRepairRequired, isFalse);
    expect(harness.calls, <String>['rhythm.stop', 'replacement.replace']);
  });

  test('replacement failure is typed and Rhythm remains stopped', () async {
    final BackupHarness harness = BackupHarness(
      importBytes: File(
        'test/fixtures/backups/neutralino-v1-minimal.json',
      ).readAsBytesSync(),
    );
    final PreparedBackupImport prepared = (await harness.prepare.execute())!;
    harness.calls.clear();
    harness.replacement.fail = true;

    await expectLater(
      harness.confirm.execute(prepared),
      throwsA(
        isA<BackupFailure>()
            .having(
              (BackupFailure failure) => failure.key,
              'key',
              BackupFailureKey.replacement,
            )
            .having(
              (BackupFailure failure) => failure.cause,
              'cause',
              isA<StateError>(),
            )
            .having(
              (BackupFailure failure) => failure.stackTrace,
              'stackTrace',
              isNotNull,
            ),
      ),
    );

    expect(harness.rhythm.stopped, isTrue);
    expect(harness.calls, <String>['rhythm.stop', 'replacement.replace']);
  });

  test('post-commit autostart repair state is preserved', () async {
    final BackupHarness harness = BackupHarness(
      importBytes: File(
        'test/fixtures/backups/neutralino-v1-minimal.json',
      ).readAsBytesSync(),
    );
    final PreparedBackupImport prepared = (await harness.prepare.execute())!;
    harness.replacement.repairRequired = true;

    final ConfirmBackupImportResult result = await harness.confirm.execute(
      prepared,
    );

    expect(result.autoStartRepairRequired, isTrue);
  });

  test('export writes canonical JSON with a UTC suggested filename', () async {
    final BackupHarness harness = BackupHarness(importBytes: null);
    harness.todoRepository.todos = <Todo>[_todo()];
    final ExportPortableBackup export = ExportPortableBackup(
      preferences: harness.preferences,
      exportTodos: TodoQueryService(repository: harness.todoRepository),
      backupFile: harness.file,
      codec: const BackupV1Codec(),
      clock: const FixedBackupClock(),
    );

    expect(await export.execute(), isTrue);

    expect(harness.file.savedName, 'clock-rhythm-20260823T010203Z.json');
    expect(harness.file.savedBytes, isNotEmpty);
    expect(
      const BackupV1Codec()
          .decode(harness.file.savedBytes!)
          .todos
          .single
          .id
          .text,
      'exported',
    );
  });

  test(
    'LB-156 exported Preferences and Todos round-trip as a full replacement',
    () async {
      final BackupHarness source = BackupHarness(importBytes: null);
      final UserPreferences sourcePreferences = UserPreferences.defaults()
          .changeLanguage(LanguagePreference.english)
          .changeTheme(ThemePreference.nord);
      final List<Todo> sourceTodos = <Todo>[
        _todo(
          id: 'todo-time',
          title: 'Timed Todo',
          time: '14:30',
          displayOrder: 0,
        ),
        _todo(
          id: 'todo-done',
          title: 'Completed Todo',
          displayOrder: 1,
          completed: true,
        ),
      ];
      source.settingsRepository.current = sourcePreferences;
      source.todoRepository.todos = sourceTodos;
      final ExportPortableBackup export = ExportPortableBackup(
        preferences: source.preferences,
        exportTodos: TodoQueryService(repository: source.todoRepository),
        backupFile: source.file,
        codec: const BackupV1Codec(),
        clock: const FixedBackupClock(),
      );
      expect(await export.execute(), isTrue);

      final BackupHarness target = BackupHarness(
        importBytes: source.file.savedBytes,
      );
      target.replacement.currentTodos = <Todo>[
        _todo(id: 'replaced', title: 'Replaced Todo'),
      ];
      final PreparedBackupImport prepared = (await target.prepare.execute())!;
      await target.confirm.execute(prepared);

      expect(target.replacement.currentPreferences, sourcePreferences);
      expect(
        target.replacement.currentTodos.map((Todo todo) => todo.snapshot()),
        sourceTodos.map((Todo todo) => todo.snapshot()),
      );
      expect(
        target.replacement.currentTodos.any(
          (Todo todo) => todo.id.text == 'replaced',
        ),
        isFalse,
      );
    },
  );
}

final class BackupHarness {
  BackupHarness({required List<int>? importBytes}) {
    settingsRepository = MemorySettingsRepository(calls);
    preferences = PreferencesService(
      settingsRepository: settingsRepository,
      preferencesChanged: const NoOpPreferencesChanged(),
    );
    todoRepository = MemoryTodoRepository();
    file = FakeBackupFilePort(calls, importBytes);
    rhythm = FakeRhythmSafetyPort(calls);
    replacement = FakeBackupReplacementPort(calls);
    prepare = PrepareBackupImport(
      backupFile: file,
      codec: const BackupV1Codec(),
      preferences: preferences,
    );
    confirm = ConfirmBackupImport(
      rhythmSafety: rhythm,
      replacement: replacement,
    );
  }

  final List<String> calls = <String>[];
  late final MemorySettingsRepository settingsRepository;
  late final PreferencesService preferences;
  late final MemoryTodoRepository todoRepository;
  late final FakeBackupFilePort file;
  late final FakeRhythmSafetyPort rhythm;
  late final FakeBackupReplacementPort replacement;
  late final PrepareBackupImport prepare;
  late final ConfirmBackupImport confirm;
}

final class MemorySettingsRepository implements SettingsRepository {
  MemorySettingsRepository(this.calls);

  final List<String> calls;
  UserPreferences current = UserPreferences.defaults();

  @override
  Future<UserPreferences> load() async {
    calls.add('preferences.load');
    return current;
  }

  @override
  Future<void> save(UserPreferences preferences) async {
    current = preferences;
  }
}

final class MemoryTodoRepository implements TodoRepository {
  List<Todo> todos = <Todo>[];

  @override
  Future<List<Todo>> getAll() async => List<Todo>.of(todos);

  @override
  Future<T> mutate<T extends Object?>(TodoMutation<T> mutation) async {
    final TodoMutationResult<T> result = mutation(List<Todo>.of(todos));
    todos = List<Todo>.of(result.todos);
    return result.value;
  }

  @override
  Future<void> saveAll(List<Todo> todos) async {
    this.todos = List<Todo>.of(todos);
  }
}

final class FakeBackupFilePort implements BackupFilePort {
  FakeBackupFilePort(this.calls, this.importBytes);

  final List<String> calls;
  final List<int>? importBytes;
  int? maximumRequestedBytes;
  String? savedName;
  List<int>? savedBytes;

  @override
  Future<BackupFileContent?> pickImport({required int maximumBytes}) async {
    calls.add('file.pick');
    maximumRequestedBytes = maximumBytes;
    final List<int>? bytes = importBytes;
    return bytes == null ? null : BackupFileContent(bytes);
  }

  @override
  Future<bool> saveExport({
    required String suggestedFileName,
    required List<int> bytes,
  }) async {
    savedName = suggestedFileName;
    savedBytes = List<int>.of(bytes);
    return true;
  }
}

final class FakeRhythmSafetyPort implements RhythmSafetyPort {
  FakeRhythmSafetyPort(this.calls);

  final List<String> calls;
  bool stopped = false;

  @override
  Future<void> stopForImport() async {
    calls.add('rhythm.stop');
    stopped = true;
  }
}

final class FakeBackupReplacementPort implements BackupReplacementPort {
  FakeBackupReplacementPort(this.calls);

  final List<String> calls;
  bool fail = false;
  bool repairRequired = false;
  int replaceCalls = 0;
  UserPreferences? currentPreferences;
  List<Todo> currentTodos = <Todo>[];

  @override
  Future<BackupReplacementResult> replaceAll({
    required UserPreferences preferences,
    required List<Todo> todos,
  }) async {
    calls.add('replacement.replace');
    replaceCalls += 1;
    if (fail) {
      throw StateError('injected DB failure');
    }
    currentPreferences = preferences;
    currentTodos = List<Todo>.of(todos, growable: false);
    return BackupReplacementResult(autoStartRepairRequired: repairRequired);
  }
}

final class FixedBackupClock implements BackupClock {
  const FixedBackupClock();

  @override
  DateTime now() => DateTime.utc(2026, 8, 23, 1, 2, 3);
}

List<int> _backupMissing(String field) {
  final Object? decoded = jsonDecode(
    File('test/fixtures/backups/neutralino-v1-minimal.json').readAsStringSync(),
  );
  if (decoded is! Map<Object?, Object?>) {
    throw const FormatException('Minimal backup fixture must be an object.');
  }
  final Map<String, Object?> envelope = Map<String, Object?>.from(decoded)
    ..remove(field);
  return utf8.encode(jsonEncode(envelope));
}

Todo _todo({
  String id = 'exported',
  String title = 'Exported Todo',
  String? time,
  int displayOrder = 0,
  bool completed = false,
}) {
  return Todo.restore(
    TodoRestoreSnapshot(
      id: id,
      title: title,
      date: '2026-08-23',
      time: time,
      completed: completed,
      displayOrder: displayOrder,
      createdAt: '2026-08-23T00:00:00.000Z',
      updatedAt: completed
          ? '2026-08-23T00:10:00.000Z'
          : '2026-08-23T00:00:00.000Z',
    ),
  );
}

final class NoOpPreferencesChanged implements PreferencesChangedPort {
  const NoOpPreferencesChanged();
  @override
  Future<void> publish(PreferencesChangedEvent event) async {}
}
