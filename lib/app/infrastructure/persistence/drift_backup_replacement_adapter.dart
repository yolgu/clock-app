import 'package:drift/drift.dart';

import '../../../contexts/preferences/public.dart'
    show AutoStartPort, AutoStartReconciliation;
import '../../../contexts/preferences/public_model.dart' show UserPreferences;
import '../../../contexts/todo/public_model.dart' show Todo;
import '../../../features/data_transfer/public.dart'
    show BackupReplacementPort, BackupReplacementResult;
import '../device_state/device_sound_locator_mutation.dart';
import '../device_state/device_sound_locator_store.dart';
import 'clock_rhythm_database.dart';
import 'mappers/preference_record_mapper.dart';
import 'mappers/todo_record_mapper.dart';

typedef ReplacementCheckpoint = Future<void> Function();

final class DriftBackupReplacementAdapter implements BackupReplacementPort {
  factory DriftBackupReplacementAdapter({
    required ClockRhythmDatabase database,
    required AutoStartPort autoStart,
    required DeviceSoundLocatorStore deviceSoundLocatorStore,
    DeviceSoundLocatorMutationCoordinator? deviceSoundLocatorMutation,
  }) {
    return DriftBackupReplacementAdapter._(
      database,
      autoStart,
      deviceSoundLocatorStore,
      deviceSoundLocatorMutation ??
          DeviceSoundLocatorMutationCoordinator(deviceSoundLocatorStore),
    );
  }

  const DriftBackupReplacementAdapter._(
    this._database,
    this._autoStart,
    this._deviceSoundLocatorStore,
    this._deviceSoundLocatorMutation,
  );

  final ClockRhythmDatabase _database;
  final AutoStartPort _autoStart;
  final DeviceSoundLocatorStore _deviceSoundLocatorStore;
  final DeviceSoundLocatorMutationCoordinator _deviceSoundLocatorMutation;

  @override
  Future<BackupReplacementResult> replaceAll({
    required UserPreferences preferences,
    required List<Todo> todos,
  }) {
    return _replaceAll(preferences: preferences, todos: todos);
  }

  Future<BackupReplacementResult> replaceAllForTesting({
    required UserPreferences preferences,
    required List<Todo> todos,
    required ReplacementCheckpoint afterPreferencesWritten,
  }) {
    return _replaceAll(
      preferences: preferences,
      todos: todos,
      afterPreferencesWritten: afterPreferencesWritten,
    );
  }

  Future<BackupReplacementResult> _replaceAll({
    required UserPreferences preferences,
    required List<Todo> todos,
    ReplacementCheckpoint? afterPreferencesWritten,
  }) async {
    final PreferenceRecordsCompanion preferenceRow =
        PreferenceRecordMapper.toCompanion(preferences);
    final List<TodoRecordsCompanion> todoRows = <TodoRecordsCompanion>[
      for (int index = 0; index < todos.length; index += 1)
        TodoRecordMapper.toCompanion(todos[index], index),
    ];
    final DeviceSoundLocatorState deviceSoundLocators =
        DeviceSoundLocatorState.fromPreferences(preferences);
    await _deviceSoundLocatorMutation.run<void>(() {
      return _database.transaction(() async {
        await _database.delete(_database.preferenceRecords).go();
        await _database.into(_database.preferenceRecords).insert(preferenceRow);
        await afterPreferencesWritten?.call();
        await _database.delete(_database.todoRecords).go();
        if (todoRows.isNotEmpty) {
          await _database.batch((Batch batch) {
            batch.insertAll(_database.todoRecords, todoRows);
          });
        }
        await _deviceSoundLocatorStore.save(deviceSoundLocators);
      });
    });
    try {
      final AutoStartReconciliation reconciliation = await _autoStart.reconcile(
        desiredEnabled: preferences.autoStartEnabled,
      );
      return BackupReplacementResult(
        autoStartRepairRequired: reconciliation.repairRequired,
      );
    } on Object {
      return const BackupReplacementResult(autoStartRepairRequired: true);
    }
  }
}
