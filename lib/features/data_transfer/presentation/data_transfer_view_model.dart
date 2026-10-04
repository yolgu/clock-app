import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/backup_failure.dart';
import '../application/confirm_backup_import.dart';
import '../application/prepare_backup_import.dart';
import 'data_transfer_actions.dart';
import 'data_transfer_providers.dart';
import 'data_transfer_state.dart';

final class DataTransferViewModel extends Notifier<DataTransferState> {
  DataTransferActions get _actions => ref.read(dataTransferActionsProvider);

  @override
  DataTransferState build() => const DataTransferState();

  Future<void> exportBackup() async {
    if (state.isBusy) {
      return;
    }
    state = const DataTransferState(phase: DataTransferPhase.exporting);
    try {
      final bool saved = await _actions.exportBackup();
      state = saved
          ? const DataTransferState(success: DataTransferSuccess.exported)
          : const DataTransferState();
    } on BackupFailure catch (failure) {
      _fail(failure);
    } on Object catch (error, stackTrace) {
      _fail(
        BackupFailure(
          key: BackupFailureKey.export,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> prepareImport() async {
    if (state.isBusy) {
      return;
    }
    state = const DataTransferState(phase: DataTransferPhase.preparing);
    try {
      final PreparedBackupImport? prepared = await _actions.prepareImport();
      state = prepared == null
          ? const DataTransferState()
          : DataTransferState(
              phase: DataTransferPhase.prepared,
              prepared: prepared,
            );
    } on BackupFailure catch (failure) {
      _fail(failure);
    } on Object catch (error, stackTrace) {
      _fail(
        BackupFailure(
          key: BackupFailureKey.fileRead,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  void cancelPreparedImport() {
    if (state.phase == DataTransferPhase.prepared) {
      state = const DataTransferState();
    }
  }

  Future<void> confirmImport() async {
    final PreparedBackupImport? prepared = state.prepared;
    if (state.isBusy || prepared == null) {
      return;
    }
    state = DataTransferState(
      phase: DataTransferPhase.confirming,
      prepared: prepared,
    );
    try {
      final ConfirmBackupImportResult result = await _actions.confirmImport(
        prepared,
      );
      try {
        await _actions.refreshAfterImport();
      } on Object {
        state = DataTransferState(
          success: DataTransferSuccess.imported,
          autoStartRepairRequired: result.autoStartRepairRequired,
          refreshRequired: true,
        );
        return;
      }
      state = DataTransferState(
        success: DataTransferSuccess.imported,
        autoStartRepairRequired: result.autoStartRepairRequired,
      );
    } on BackupFailure catch (failure) {
      _fail(failure, prepared: prepared);
    } on Object catch (error, stackTrace) {
      _fail(
        BackupFailure(
          key: BackupFailureKey.replacement,
          cause: error,
          stackTrace: stackTrace,
        ),
        prepared: prepared,
      );
    }
  }

  Future<void> retryRefresh() async {
    if (state.isBusy ||
        state.success != DataTransferSuccess.imported ||
        !state.refreshRequired) {
      return;
    }
    final bool repairRequired = state.autoStartRepairRequired;
    try {
      await _actions.refreshAfterImport();
      state = DataTransferState(
        success: DataTransferSuccess.imported,
        autoStartRepairRequired: repairRequired,
      );
    } on Object {
      state = DataTransferState(
        success: DataTransferSuccess.imported,
        autoStartRepairRequired: repairRequired,
        refreshRequired: true,
      );
    }
  }

  void clearFeedback() {
    if (!state.isBusy && state.prepared == null) {
      state = const DataTransferState();
    }
  }

  void _fail(BackupFailure failure, {PreparedBackupImport? prepared}) {
    state = DataTransferState(
      phase: prepared == null
          ? DataTransferPhase.idle
          : DataTransferPhase.prepared,
      prepared: prepared,
      failure: failure,
    );
  }
}
