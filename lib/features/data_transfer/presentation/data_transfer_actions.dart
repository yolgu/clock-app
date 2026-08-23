import '../application/confirm_backup_import.dart';
import '../application/export_portable_backup.dart';
import '../application/ports.dart';
import '../application/prepare_backup_import.dart';

abstract interface class DataTransferActions {
  Future<bool> exportBackup();

  Future<PreparedBackupImport?> prepareImport();

  Future<ConfirmBackupImportResult> confirmImport(
    PreparedBackupImport prepared,
  );

  Future<void> refreshAfterImport();
}

final class ApplicationDataTransferActions implements DataTransferActions {
  factory ApplicationDataTransferActions({
    required ExportPortableBackup exportBackup,
    required PrepareBackupImport prepareImport,
    required ConfirmBackupImport confirmImport,
    required DataImportRefreshPort refresh,
  }) {
    return ApplicationDataTransferActions._(
      exportBackup,
      prepareImport,
      confirmImport,
      refresh,
    );
  }

  const ApplicationDataTransferActions._(
    this._exportBackup,
    this._prepareImport,
    this._confirmImport,
    this._refresh,
  );

  final ExportPortableBackup _exportBackup;
  final PrepareBackupImport _prepareImport;
  final ConfirmBackupImport _confirmImport;
  final DataImportRefreshPort _refresh;

  @override
  Future<bool> exportBackup() {
    return _exportBackup.execute();
  }

  @override
  Future<PreparedBackupImport?> prepareImport() {
    return _prepareImport.execute();
  }

  @override
  Future<ConfirmBackupImportResult> confirmImport(
    PreparedBackupImport prepared,
  ) {
    return _confirmImport.execute(prepared);
  }

  @override
  Future<void> refreshAfterImport() {
    return _refresh.refreshAfterImport();
  }
}
