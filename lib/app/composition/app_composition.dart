import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../contexts/preferences/public.dart';
import '../../contexts/rhythm/public.dart'
    show LegacyCoexistenceWarning, NoLegacyCoexistenceWarning;
import '../../features/data_transfer/infrastructure/json/backup_v1_codec.dart';
import '../../features/data_transfer/public.dart';
import '../config/app_flavor.dart';
import '../infrastructure/device_state/device_sound_locator_store.dart';
import '../infrastructure/device_state/shared_preferences_draft_store.dart';
import '../infrastructure/device_state/shared_preferences_legacy_coexistence_warning.dart';
import '../infrastructure/file_picker_backup_file_adapter.dart';
import '../infrastructure/persistence/database_connection.dart';
import '../infrastructure/persistence/database_recovery_file_manager.dart';
import '../infrastructure/persistence/database_startup.dart';
import 'android_platform_services_factory.dart';
import 'clock_rhythm_bootstrap.dart';
import 'clock_rhythm_runtime.dart';
import 'database_recovery_backup_importer.dart';
import 'macos_platform_services_factory.dart';
import 'windows_platform_services_factory.dart';

final class AppComposition {
  AppComposition._({
    required this.configuration,
    required this._platform,
    required this._databaseStartup,
    required this._deviceSoundLocatorStore,
    required this._draftStore,
    required this._legacyCoexistenceWarning,
    required this._backupFile,
    required this._backupCodec,
    required this._recoveryFileManager,
  });

  factory AppComposition.forCurrentPlatform() {
    final AppFlavorConfiguration configuration =
        AppFlavorConfiguration.fromEnvironment();
    final DeviceSoundLocatorStore deviceSoundLocatorStore =
        SharedPreferencesDeviceSoundLocatorStore.namespaced(
          storageNamespace: configuration.windowsIdentity,
        );
    final DraftStore draftStore = SharedPreferencesDraftStore(
      storageNamespace: configuration.windowsIdentity,
    );
    final LegacyCoexistenceWarning legacyCoexistenceWarning =
        configuration.isBeta
        ? SharedPreferencesLegacyCoexistenceWarning(
            storageNamespace: configuration.windowsIdentity,
          )
        : const NoLegacyCoexistenceWarning();
    final BackupFilePort backupFile = FilePickerBackupFileAdapter();
    const PortableBackupCodec backupCodec = BackupV1Codec();
    final AppPlatformBootstrap platform;
    if (Platform.isWindows) {
      platform = WindowsPlatformServicesFactory(configuration: configuration);
    } else if (Platform.isAndroid) {
      platform = AndroidPlatformServicesFactory();
    } else if (Platform.isMacOS) {
      platform = MacOSPlatformServicesFactory();
    } else {
      throw UnsupportedError(
        'Clock Rhythm supports Windows, Android and macOS.',
      );
    }
    final DatabaseStartup databaseStartup = DatabaseStartup(
      connectionFactory: PrivateDatabaseConnectionFactory(
        databaseName: configuration.databaseName,
      ),
      deviceSoundLocatorStore: deviceSoundLocatorStore,
    );
    return AppComposition._(
      configuration: configuration,
      platform: platform,
      databaseStartup: databaseStartup,
      deviceSoundLocatorStore: deviceSoundLocatorStore,
      draftStore: draftStore,
      legacyCoexistenceWarning: legacyCoexistenceWarning,
      backupFile: backupFile,
      backupCodec: backupCodec,
      recoveryFileManager: DatabaseRecoveryFileManager(),
    );
  }

  final AppFlavorConfiguration configuration;
  final AppPlatformBootstrap _platform;
  final DatabaseStartup _databaseStartup;
  final DeviceSoundLocatorStore _deviceSoundLocatorStore;
  final DraftStore _draftStore;
  final LegacyCoexistenceWarning _legacyCoexistenceWarning;
  final BackupFilePort _backupFile;
  final PortableBackupCodec _backupCodec;
  final DatabaseRecoveryFileManager _recoveryFileManager;

  Future<void> initialize() {
    return _platform.initializeBeforeRunApp();
  }

  Widget buildApp() {
    final DatabaseRecoveryBackupImporter recoveryImporter =
        DatabaseRecoveryBackupImporter(
          databaseStartup: _databaseStartup,
          fileManager: _recoveryFileManager,
          backupFile: _backupFile,
          codec: _backupCodec,
          autoStart: _platform.recoveryAutoStart,
          deviceSoundLocatorStore: _deviceSoundLocatorStore,
          draftStore: _draftStore,
          repairState: _platform.preferencesRepairState,
        );
    return ClockRhythmBootstrap(
      databaseStartup: _databaseStartup,
      runtimeFactory: (DatabaseReady ready) {
        return ClockRhythmRuntime.createWithPlatformFactory(
          databaseReady: ready,
          presentationProfile: _platform.presentationProfile,
          platformServicesFactory: _platform.create,
          deviceSoundLocatorStore: _deviceSoundLocatorStore,
          draftStore: _draftStore,
          backupFile: _backupFile,
          backupCodec: _backupCodec,
          legacyCoexistenceWarning: _legacyCoexistenceWarning,
        );
      },
      recoveryFileManager: _recoveryFileManager,
      prepareBackupImport: recoveryImporter.prepare,
      confirmBackupImport: recoveryImporter.confirm,
      disposePlatform: _platform.dispose,
    );
  }
}
