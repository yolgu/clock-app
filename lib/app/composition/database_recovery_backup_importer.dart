import '../../contexts/preferences/public.dart';
import '../../features/data_transfer/public.dart';
import '../infrastructure/device_state/device_sound_locator_mutation.dart';
import '../infrastructure/device_state/device_sound_locator_store.dart';
import '../infrastructure/persistence/database_recovery_file_manager.dart';
import '../infrastructure/persistence/database_startup.dart';
import '../infrastructure/persistence/drift_backup_replacement_adapter.dart';

final class DatabaseRecoveryImportRollbackFailure implements Exception {
  const DatabaseRecoveryImportRollbackFailure({
    required this.importFailureType,
    required this.rollbackFailureType,
  });

  final String importFailureType;
  final String rollbackFailureType;

  @override
  String toString() {
    return 'DatabaseRecoveryImportRollbackFailure('
        'import: $importFailureType, rollback: $rollbackFailureType)';
  }
}

final class DatabaseRecoveryBackupImporter {
  const DatabaseRecoveryBackupImporter({
    required this._databaseStartup,
    required this._fileManager,
    required this._backupFile,
    required this._codec,
    required this._autoStart,
    required this._deviceSoundLocatorStore,
    required this._draftStore,
    required this._repairState,
  });

  final DatabaseStartup _databaseStartup;
  final DatabaseRecoveryFileManager _fileManager;
  final BackupFilePort _backupFile;
  final PortableBackupCodec _codec;
  final AutoStartPort _autoStart;
  final DeviceSoundLocatorStore _deviceSoundLocatorStore;
  final DraftStore _draftStore;
  final PreferencesRepairStatePort _repairState;

  Future<PreparedBackupImport?> prepare() async {
    final BackupFileContent? content = await _backupFile.pickImport(
      maximumBytes: _codec.maximumFileBytes,
    );
    if (content == null) {
      return null;
    }
    final PortableBackupData imported = _codec.decode(content.bytes);
    final RhythmSettingsDraft? currentDraft = await _draftStore.load();
    return PreparedBackupImport.fromValidatedData(
      data: imported,
      currentAutoStartEnabled:
          currentDraft?.autoStartEnabled ??
          UserPreferences.defaults().autoStartEnabled,
    );
  }

  Future<DatabaseReady> confirm(
    DatabaseRecoveryRequired recovery,
    PreparedBackupImport prepared,
  ) async {
    final String? databasePath = recovery.databasePath;
    if (databasePath == null) {
      throw const BackupFailure(key: BackupFailureKey.replacement);
    }
    final RhythmSettingsDraft? previousDraft = await _draftStore.load();
    final DeviceSoundLocatorState previousDeviceSound =
        await _deviceSoundLocatorStore.load();
    final DatabaseRecoveryArchive? archive = await _fileManager
        .preserveForReset(databasePath);
    DatabaseReady? ready;
    try {
      final DatabaseStartupState startup = await _databaseStartup.open();
      if (startup is! DatabaseReady) {
        throw const BackupFailure(key: BackupFailureKey.replacement);
      }
      ready = startup;
      final DeviceSoundLocatorMutationCoordinator locatorMutation =
          DeviceSoundLocatorMutationCoordinator(_deviceSoundLocatorStore);
      await DriftBackupReplacementAdapter(
        database: ready.database,
        autoStart: const _DeferredAutoStartPort(),
        deviceSoundLocatorStore: _deviceSoundLocatorStore,
        deviceSoundLocatorMutation: locatorMutation,
      ).replaceAll(
        preferences: prepared.payload.preferences,
        todos: prepared.payload.todos,
      );
      await _draftStore.save(
        RhythmSettingsDraft.fromPreferences(prepared.payload.preferences),
      );
      try {
        final AutoStartReconciliation reconciliation = await _autoStart
            .reconcile(
              desiredEnabled: prepared.payload.preferences.autoStartEnabled,
            );
        _repairState.recordCommandResult(
          attempted: const <PreferencesRepairNeed>{
            PreferencesRepairNeed.autoStart,
          },
          reported: reconciliation.repairRequired
              ? const <PreferencesRepairNeed>{PreferencesRepairNeed.autoStart}
              : const <PreferencesRepairNeed>{},
        );
      } on Object {
        _repairState.report(PreferencesRepairNeed.autoStart);
      }
      return ready;
    } on Object catch (importError, importStackTrace) {
      try {
        await ready?.database.close();
        if (archive != null) {
          await _fileManager.restoreAfterFailedReset(archive);
        }
        await _deviceSoundLocatorStore.save(previousDeviceSound);
        if (previousDraft == null) {
          await _draftStore.clear();
        } else {
          await _draftStore.save(previousDraft);
        }
      } on Object catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          DatabaseRecoveryImportRollbackFailure(
            importFailureType: importError.runtimeType.toString(),
            rollbackFailureType: rollbackError.runtimeType.toString(),
          ),
          rollbackStackTrace,
        );
      }
      Error.throwWithStackTrace(importError, importStackTrace);
    }
  }
}

final class _DeferredAutoStartPort implements AutoStartPort {
  const _DeferredAutoStartPort();

  @override
  Future<AutoStartReconciliation> reconcile({
    required bool desiredEnabled,
  }) async {
    return AutoStartReconciliation(
      desiredEnabled: desiredEnabled,
      actualEnabled: desiredEnabled,
    );
  }
}
