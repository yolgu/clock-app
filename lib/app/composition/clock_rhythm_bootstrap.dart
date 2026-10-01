import 'dart:async';

import 'package:flutter/material.dart';

import '../../contexts/preferences/public_model.dart' show ThemePreference;
import '../../contexts/preferences/public_presentation.dart'
    show ClockRhythmTheme, ThemeCatalog;
import '../../features/data_transfer/public.dart' show PreparedBackupImport;
import '../../shared/i18n/public.dart'
    show AppLocalizations, LanguageLocaleMapper;
import '../../shared/ui/public.dart' show ClockRhythmSpace;
import '../infrastructure/persistence/database_failure.dart';
import '../infrastructure/persistence/database_recovery_file_manager.dart';
import '../infrastructure/persistence/database_startup.dart';
import '../presentation/recovery/database_recovery_contract.dart';
import '../presentation/recovery/database_recovery_page.dart';
import 'clock_rhythm_runtime.dart';

typedef ClockRhythmRuntimeFactory =
    Future<ClockRhythmRuntime> Function(DatabaseReady databaseReady);
typedef RecoveryImportPreparation = Future<PreparedBackupImport?> Function();
typedef RecoveryImportConfirmation =
    Future<DatabaseReady> Function(
      DatabaseRecoveryRequired recovery,
      PreparedBackupImport prepared,
    );

final class ClockRhythmBootstrap extends StatefulWidget {
  const ClockRhythmBootstrap({
    required this.databaseStartup,
    required this.runtimeFactory,
    required this.recoveryFileManager,
    required this.prepareBackupImport,
    required this.confirmBackupImport,
    this.disposePlatform,
    super.key,
  });

  final DatabaseStartup databaseStartup;
  final ClockRhythmRuntimeFactory runtimeFactory;
  final DatabaseRecoveryFileManager recoveryFileManager;
  final RecoveryImportPreparation prepareBackupImport;
  final RecoveryImportConfirmation confirmBackupImport;
  final Future<void> Function()? disposePlatform;

  @override
  State<ClockRhythmBootstrap> createState() => _ClockRhythmBootstrapState();
}

final class _ClockRhythmBootstrapState extends State<ClockRhythmBootstrap> {
  ClockRhythmRuntime? _runtime;
  DatabaseRecoveryRequired? _recovery;
  Object? _runtimeFailure;
  bool _isLoading = true;
  int _operationRevision = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_openDatabase());
  }

  @override
  Widget build(BuildContext context) {
    final ClockRhythmRuntime? runtime = _runtime;
    if (runtime != null) {
      return runtime.buildApp();
    }
    final DatabaseRecoveryRequired? recovery = _recovery;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: LanguageLocaleMapper.koreanLocale,
      supportedLocales: LanguageLocaleMapper.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ClockRhythmTheme.build(
        ThemeCatalog.resolve(ThemePreference.current),
      ),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _runtimeFailure != null
          ? _RuntimeStartupFailurePage(onRetry: _openDatabase)
          : recovery == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : DatabaseRecoveryPage(
              reason: _recoveryReason(recovery.failure.kind),
              actions: _BootstrapRecoveryActions(
                retryOpen: _retryOpen,
                resetAfterRecoveryCopy: _resetAfterRecoveryCopy,
              ),
              onRecovered: () {},
              prepareImport: widget.prepareBackupImport,
              confirmImport: _confirmBackupImport,
            ),
    );
  }

  @override
  void dispose() {
    _operationRevision += 1;
    final ClockRhythmRuntime? runtime = _runtime;
    _runtime = null;
    unawaited(_disposeResources(runtime));
    super.dispose();
  }

  Future<void> _disposeResources(ClockRhythmRuntime? runtime) async {
    try {
      await runtime?.dispose();
    } finally {
      await widget.disposePlatform?.call();
    }
  }

  Future<void> _openDatabase() async {
    final int revision = ++_operationRevision;
    _showLoading();
    final DatabaseStartupState startup = await widget.databaseStartup.open();
    await _acceptStartup(startup, revision: revision);
  }

  Future<bool> _retryOpen() async {
    await _openDatabase();
    return _runtime != null;
  }

  Future<bool> _resetAfterRecoveryCopy() async {
    final DatabaseRecoveryRequired? recovery = _recovery;
    final String? databasePath = recovery?.databasePath;
    if (recovery == null || databasePath == null) {
      return false;
    }
    final int revision = ++_operationRevision;
    _showLoading();
    try {
      await widget.recoveryFileManager.preserveForReset(databasePath);
    } on Object {
      _restoreRecovery(recovery, revision: revision);
      return false;
    }
    final DatabaseStartupState startup = await widget.databaseStartup.open();
    await _acceptStartup(startup, revision: revision);
    return _runtime != null;
  }

  Future<void> _confirmBackupImport(PreparedBackupImport prepared) async {
    final DatabaseRecoveryRequired? recovery = _recovery;
    if (recovery == null) {
      return;
    }
    final int revision = ++_operationRevision;
    final DatabaseReady ready;
    try {
      ready = await widget.confirmBackupImport(recovery, prepared);
    } on Object {
      rethrow;
    }
    await _activateRuntime(ready, revision: revision);
  }

  Future<void> _acceptStartup(
    DatabaseStartupState startup, {
    required int revision,
  }) async {
    switch (startup) {
      case final DatabaseReady ready:
        await _activateRuntime(ready, revision: revision);
      case final DatabaseRecoveryRequired recovery:
        _restoreRecovery(recovery, revision: revision);
    }
  }

  Future<void> _activateRuntime(
    DatabaseReady ready, {
    required int revision,
  }) async {
    final ClockRhythmRuntime runtime;
    try {
      runtime = await widget.runtimeFactory(ready);
    } on Object catch (error) {
      try {
        await ready.database.close();
      } on Object {
        // The actionable startup failure is more useful than a close failure.
      }
      if (!mounted || revision != _operationRevision) {
        return;
      }
      setState(() {
        _runtime = null;
        _recovery = null;
        _runtimeFailure = error;
        _isLoading = false;
      });
      return;
    }
    if (!mounted || revision != _operationRevision) {
      await runtime.dispose();
      return;
    }
    setState(() {
      _runtime = runtime;
      _recovery = null;
      _runtimeFailure = null;
      _isLoading = false;
    });
  }

  void _showLoading() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _runtimeFailure = null;
    });
  }

  void _restoreRecovery(
    DatabaseRecoveryRequired recovery, {
    required int revision,
  }) {
    if (!mounted || revision != _operationRevision) {
      return;
    }
    setState(() {
      _recovery = recovery;
      _runtimeFailure = null;
      _isLoading = false;
    });
  }

  DatabaseRecoveryReason _recoveryReason(DatabaseFailureKind kind) {
    return switch (kind) {
      DatabaseFailureKind.location => DatabaseRecoveryReason.location,
      DatabaseFailureKind.unsupportedVersion =>
        DatabaseRecoveryReason.unsupportedVersion,
      DatabaseFailureKind.openOrIntegrity =>
        DatabaseRecoveryReason.openOrIntegrity,
      DatabaseFailureKind.migrationOrData =>
        DatabaseRecoveryReason.migrationOrData,
    };
  }
}

final class _RuntimeStartupFailurePage extends StatelessWidget {
  const _RuntimeStartupFailurePage({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(ClockRhythmSpace.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(copy.failureUnknown, textAlign: TextAlign.center),
              const SizedBox(height: ClockRhythmSpace.space16),
              FilledButton(onPressed: onRetry, child: Text(copy.actionRetry)),
            ],
          ),
        ),
      ),
    );
  }
}

final class _BootstrapRecoveryActions implements DatabaseRecoveryActions {
  const _BootstrapRecoveryActions({
    required this._retryOpen,
    required this._resetAfterRecoveryCopy,
  });

  final Future<bool> Function() _retryOpen;
  final Future<bool> Function() _resetAfterRecoveryCopy;

  @override
  Future<bool> retryOpen() => _retryOpen();

  @override
  Future<bool> resetAfterRecoveryCopy() => _resetAfterRecoveryCopy();
}
