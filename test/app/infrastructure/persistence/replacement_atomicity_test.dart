import 'package:clock_rhythm/app/infrastructure/device_state/device_sound_locator_store.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/drift_backup_replacement_adapter.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/repositories/drift_settings_repository.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/repositories/drift_todo_repository.dart';
import 'package:clock_rhythm/contexts/preferences/public.dart'
    show AutoStartPort, AutoStartReconciliation;
import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/todo/public_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';
import 'support/memory_device_sound_locator_store.dart';

void main() {
  late TestDatabase testDatabase;
  late DriftSettingsRepository settingsRepository;
  late DriftTodoRepository todoRepository;
  late DriftBackupReplacementAdapter replacement;
  late FakeAutoStartPort autoStart;
  late MemoryDeviceSoundLocatorStore deviceSoundLocatorStore;

  setUp(() {
    testDatabase = TestDatabase.open();
    deviceSoundLocatorStore = MemoryDeviceSoundLocatorStore();
    settingsRepository = DriftSettingsRepository(
      testDatabase.database,
      deviceSoundLocatorStore: deviceSoundLocatorStore,
    );
    todoRepository = DriftTodoRepository(testDatabase.database);
    autoStart = FakeAutoStartPort();
    replacement = DriftBackupReplacementAdapter(
      database: testDatabase.database,
      autoStart: autoStart,
      deviceSoundLocatorStore: deviceSoundLocatorStore,
    );
  });

  tearDown(() async {
    await testDatabase.close();
  });

  test(
    'fault between Preferences and Todos rolls the whole replacement back',
    () async {
      final UserPreferences originalPreferences = UserPreferences.defaults();
      final Todo originalTodo = _todo('old', 'Original');
      await settingsRepository.save(originalPreferences);
      await todoRepository.saveAll(<Todo>[originalTodo]);

      await expectLater(
        replacement.replaceAllForTesting(
          preferences: originalPreferences.changeTheme(ThemePreference.nord),
          todos: <Todo>[_todo('new', 'Replacement')],
          afterPreferencesWritten: () async {
            throw StateError('injected replacement fault');
          },
        ),
        throwsStateError,
      );

      expect(await settingsRepository.load(), originalPreferences);
      expect(
        (await todoRepository.getAll()).map((Todo todo) => todo.snapshot()),
        <TodoSnapshot>[originalTodo.snapshot()],
      );
    },
  );

  test('successful replacement commits both datasets together', () async {
    final UserPreferences imported = UserPreferences.defaults()
        .changeLanguage(LanguagePreference.english)
        .changeAutoStart(true);
    final List<Todo> importedTodos = <Todo>[
      _todo('a', 'Alpha'),
      _todo('b', 'Beta'),
    ];

    await replacement.replaceAll(preferences: imported, todos: importedTodos);

    expect(await settingsRepository.load(), imported);
    expect(
      (await todoRepository.getAll()).map((Todo todo) => todo.snapshot()),
      importedTodos.map((Todo todo) => todo.snapshot()),
    );
  });

  test(
    'autostart failure keeps imported data and returns repair state',
    () async {
      autoStart.fail = true;
      final UserPreferences imported = UserPreferences.defaults()
          .changeAutoStart(true);

      final result = await replacement.replaceAll(
        preferences: imported,
        todos: <Todo>[_todo('imported', 'Imported')],
      );

      expect(result.autoStartRepairRequired, isTrue);
      expect(await settingsRepository.load(), imported);
      expect((await todoRepository.getAll()).single.id.text, 'imported');
    },
  );

  test('device locator failure rolls both imported datasets back', () async {
    final UserPreferences originalPreferences = UserPreferences.defaults()
        .changeTheme(ThemePreference.nord);
    final Todo originalTodo = _todo('old', 'Original');
    await settingsRepository.save(originalPreferences);
    await todoRepository.saveAll(<Todo>[originalTodo]);
    deviceSoundLocatorStore.saveFailure = StateError(
      'device locator unavailable',
    );

    await expectLater(
      replacement.replaceAll(
        preferences: originalPreferences.changeLanguage(
          LanguagePreference.english,
        ),
        todos: <Todo>[_todo('new', 'Replacement')],
      ),
      throwsStateError,
    );
    deviceSoundLocatorStore.saveFailure = null;

    expect(await settingsRepository.load(), originalPreferences);
    expect(
      (await todoRepository.getAll()).map((Todo todo) => todo.snapshot()),
      <TodoSnapshot>[originalTodo.snapshot()],
    );
  });

  test(
    'a locator failure after its write restores every previous data source',
    () async {
      final UserPreferences originalPreferences = UserPreferences.defaults()
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'original.mp3',
              privateSource: 'sound-v1/original.mp3',
            ),
          );
      final UserPreferences importedPreferences = UserPreferences.defaults()
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'imported.mp3',
              privateSource: 'sound-v2/imported.mp3',
            ),
          );
      final Todo originalTodo = _todo('old', 'Original');
      await settingsRepository.save(originalPreferences);
      await todoRepository.saveAll(<Todo>[originalTodo]);
      deviceSoundLocatorStore.saveFailureAfterNextWrite = StateError(
        'device state failed after write',
      );

      await expectLater(
        replacement.replaceAll(
          preferences: importedPreferences,
          todos: <Todo>[_todo('new', 'Replacement')],
        ),
        throwsStateError,
      );

      expect(await settingsRepository.load(), originalPreferences);
      expect(
        (await todoRepository.getAll()).map((Todo todo) => todo.snapshot()),
        <TodoSnapshot>[originalTodo.snapshot()],
      );
      expect(
        deviceSoundLocatorStore.state,
        DeviceSoundLocatorState.fromPreferences(originalPreferences),
      );
    },
  );

  test(
    'replacement accepts the installation limit in one transaction',
    () async {
      final List<Todo> maximumTodos = List<Todo>.generate(
        Todo.maximumInstallationCount,
        (int index) => Todo.restore(
          TodoRestoreSnapshot(
            id: 'limit-$index',
            title: 'Todo',
            date: '2026-08-23',
            time: null,
            completed: false,
            displayOrder: index,
            createdAt: '2026-08-23T00:00:00.000Z',
            updatedAt: '2026-08-23T00:00:00.000Z',
          ),
        ),
        growable: false,
      );

      await replacement.replaceAll(
        preferences: UserPreferences.defaults(),
        todos: maximumTodos,
      );

      final int count = await testDatabase.database
          .customSelect('SELECT COUNT(*) AS row_count FROM todo_records')
          .map((row) => row.read<int>('row_count'))
          .getSingle();
      expect(count, Todo.maximumInstallationCount);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

final class FakeAutoStartPort implements AutoStartPort {
  bool fail = false;

  @override
  Future<AutoStartReconciliation> reconcile({
    required bool desiredEnabled,
  }) async {
    if (fail) {
      throw StateError('injected autostart failure');
    }
    return AutoStartReconciliation(
      desiredEnabled: desiredEnabled,
      actualEnabled: desiredEnabled,
    );
  }
}

Todo _todo(String id, String title) {
  return Todo.restore(
    TodoRestoreSnapshot(
      id: id,
      title: title,
      date: '2026-08-23',
      time: null,
      completed: false,
      displayOrder: 0,
      createdAt: '2026-08-23T00:00:00.000Z',
      updatedAt: '2026-08-23T00:00:00.000Z',
    ),
  );
}
