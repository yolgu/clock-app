import 'package:clock_rhythm/app/infrastructure/device_state/device_sound_locator_store.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/repositories/drift_settings_repository.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/repositories/drift_todo_repository.dart';
import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/todo/public_model.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';
import 'support/memory_device_sound_locator_store.dart';

void main() {
  late TestDatabase testDatabase;
  late DriftSettingsRepository settingsRepository;
  late DriftTodoRepository todoRepository;
  late MemoryDeviceSoundLocatorStore deviceSoundLocatorStore;

  setUp(() {
    testDatabase = TestDatabase.open();
    deviceSoundLocatorStore = MemoryDeviceSoundLocatorStore();
    settingsRepository = DriftSettingsRepository(
      testDatabase.database,
      deviceSoundLocatorStore: deviceSoundLocatorStore,
    );
    todoRepository = DriftTodoRepository(testDatabase.database);
  });

  tearDown(() async {
    await testDatabase.close();
  });

  test('missing Preferences row restores the agreed defaults', () async {
    expect(await settingsRepository.load(), UserPreferences.defaults());
  });

  test(
    'Preferences singleton strictly round-trips every durable field',
    () async {
      final UserPreferences expected = UserPreferences.defaults()
          .changeLanguage(LanguagePreference.english)
          .changeTheme(ThemePreference.nord)
          .changeVolume(0.4)
          .toggleMute(UnmuteSoundBehavior.restorePreviousSelection)
          .changeAutoStart(true)
          .completeInitialSetup();

      await settingsRepository.save(expected);

      expect(await settingsRepository.load(), expected);
      final int rowCount = await testDatabase.database
          .customSelect('SELECT COUNT(*) AS row_count FROM preference_records')
          .map((row) => row.read<int>('row_count'))
          .getSingle();
      expect(rowCount, 1);
    },
  );

  test('durable Preferences schema excludes device sound locators', () async {
    final List<QueryRow> columns = await testDatabase.database
        .customSelect('PRAGMA table_info(preference_records)')
        .get();
    final Set<String> columnNames = columns
        .map((QueryRow row) => row.read<String>('name'))
        .toSet();

    expect(columnNames, isNot(contains('private_sound_source')));
    expect(columnNames, isNot(contains('muted_from_private_source')));
  });

  test(
    'custom sound semantics round-trip through the device locator store',
    () async {
      final UserPreferences expected = UserPreferences.defaults()
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'adopted.mp3',
              privateSource: 'sound-v2/adopted.mp3',
              volume: 0.35,
            ),
          );

      await settingsRepository.save(expected);

      expect(await settingsRepository.load(), expected);
      expect(
        deviceSoundLocatorStore.state.selectedCustom?.privateSource,
        'sound-v2/adopted.mp3',
      );
      final QueryRow durableRow = await testDatabase.database
          .customSelect('SELECT * FROM preference_records')
          .getSingle();
      expect(durableRow.data.values, isNot(contains('sound-v2/adopted.mp3')));
    },
  );

  test(
    'missing device locator sanitizes a custom selection to bundled sound',
    () async {
      final UserPreferences custom = UserPreferences.defaults()
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'adopted.mp3',
              privateSource: 'sound-v2/adopted.mp3',
              volume: 0.35,
            ),
          );
      await settingsRepository.save(custom);
      deviceSoundLocatorStore.state = DeviceSoundLocatorState.empty;

      final UserPreferences restored = await settingsRepository.load();

      expect(
        restored.notificationSound.mode,
        NotificationSoundMode.bundledDefault,
      );
      expect(restored.notificationSound.volume, 0.35);
    },
  );

  test('muted custom sound restores its previous device selection', () async {
    final UserPreferences expected = UserPreferences.defaults()
        .changeNotificationSound(
          NotificationSoundPreference.custom(
            fileName: 'previous.mp3',
            privateSource: 'sound-v4/previous.mp3',
          ),
        )
        .toggleMute(UnmuteSoundBehavior.restorePreviousSelection);

    await settingsRepository.save(expected);

    expect(await settingsRepository.load(), expected);
    expect(
      deviceSoundLocatorStore.state.mutedFromCustom?.privateSource,
      'sound-v4/previous.mp3',
    );
  });

  test('device locator write failure rolls the Preferences row back', () async {
    final UserPreferences original = UserPreferences.defaults().changeTheme(
      ThemePreference.nord,
    );
    await settingsRepository.save(original);
    deviceSoundLocatorStore.saveFailure = StateError(
      'device state unavailable',
    );

    await expectLater(
      settingsRepository.save(
        original.changeLanguage(LanguagePreference.english),
      ),
      throwsStateError,
    );
    deviceSoundLocatorStore.saveFailure = null;

    expect(await settingsRepository.load(), original);
  });

  test(
    'a locator failure after its write restores the previous locator and row',
    () async {
      final UserPreferences original = UserPreferences.defaults()
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'original.mp3',
              privateSource: 'sound-v1/original.mp3',
            ),
          );
      final UserPreferences replacement = original.changeNotificationSound(
        NotificationSoundPreference.custom(
          fileName: 'replacement.mp3',
          privateSource: 'sound-v2/replacement.mp3',
        ),
      );
      await settingsRepository.save(original);
      deviceSoundLocatorStore.saveFailureAfterNextWrite = StateError(
        'device state failed after write',
      );

      await expectLater(settingsRepository.save(replacement), throwsStateError);

      expect(await settingsRepository.load(), original);
      expect(
        deviceSoundLocatorStore.state,
        DeviceSoundLocatorState.fromPreferences(original),
      );
    },
  );

  test('present invalid Preferences data is rejected, not defaulted', () async {
    await settingsRepository.save(UserPreferences.defaults());
    await testDatabase.database.customStatement(
      'UPDATE preference_records SET language = ?',
      <Object?>['unsupported'],
    );

    await expectLater(settingsRepository.load(), throwsFormatException);
  });

  test('empty Todo storage returns an empty collection', () async {
    expect(await todoRepository.getAll(), isEmpty);
  });

  test('Todo repository strictly round-trips domain snapshots', () async {
    final List<Todo> expected = <Todo>[
      Todo.restore(
        const TodoRestoreSnapshot(
          id: 'todo-1',
          title: '첫 일정',
          date: '2026-08-23',
          time: '09:30',
          completed: false,
          displayOrder: 4,
          createdAt: '2026-08-22T00:00:00.000Z',
          updatedAt: '2026-08-22T01:00:00.000Z',
        ),
      ),
      Todo.restore(
        const TodoRestoreSnapshot(
          id: 'todo-2',
          title: 'Done',
          date: '2026-08-23',
          time: null,
          completed: true,
          displayOrder: 1,
          createdAt: '2026-08-21T00:00:00.000Z',
          updatedAt: '2026-08-22T02:00:00.000Z',
        ),
      ),
    ];

    await todoRepository.saveAll(expected);
    final List<Todo> restored = await todoRepository.getAll();

    expect(
      restored.map((Todo todo) => todo.snapshot()),
      expected.map((Todo todo) => todo.snapshot()),
    );
  });

  test('invalid Todo row fails the complete repository read', () async {
    await todoRepository.saveAll(<Todo>[
      Todo.restore(
        const TodoRestoreSnapshot(
          id: 'invalid-date',
          title: 'Private',
          date: '2026-08-23',
          time: null,
          completed: false,
          displayOrder: 0,
          createdAt: '2026-08-23T00:00:00.000Z',
          updatedAt: '2026-08-23T00:00:00.000Z',
        ),
      ),
    ]);
    await testDatabase.database.customStatement(
      'UPDATE todo_records SET local_date = ?',
      <Object?>['2026-02-30'],
    );

    await expectLater(todoRepository.getAll(), throwsArgumentError);
  });

  test('noncontiguous Todo storage order fails the complete read', () async {
    await todoRepository.saveAll(<Todo>[
      Todo.restore(
        const TodoRestoreSnapshot(
          id: 'invalid-storage-order',
          title: 'Private',
          date: '2026-08-23',
          time: null,
          completed: false,
          displayOrder: 0,
          createdAt: '2026-08-23T00:00:00.000Z',
          updatedAt: '2026-08-23T00:00:00.000Z',
        ),
      ),
    ]);
    await testDatabase.database.customStatement(
      'UPDATE todo_records SET storage_order = 4',
    );

    await expectLater(todoRepository.getAll(), throwsFormatException);
  });
}
