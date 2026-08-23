import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/data_transfer/public.dart'
    show BackupFailure, BackupFailureKey, PreparedBackupImport;
import '../../../features/data_transfer/public_presentation.dart'
    show BackupImportPreviewDialog;
import '../../../shared/i18n/public.dart';
import 'database_recovery_contract.dart';
import 'database_reset_confirmation.dart';

final class DatabaseRecoveryPage extends StatefulWidget {
  const DatabaseRecoveryPage({
    required this.reason,
    required this.actions,
    required this.onRecovered,
    required this.prepareImport,
    required this.confirmImport,
    super.key,
  });

  final DatabaseRecoveryReason reason;
  final DatabaseRecoveryActions actions;
  final VoidCallback onRecovered;
  final Future<PreparedBackupImport?> Function() prepareImport;
  final Future<void> Function(PreparedBackupImport prepared) confirmImport;

  @override
  State<DatabaseRecoveryPage> createState() => _DatabaseRecoveryPageState();
}

final class _DatabaseRecoveryPageState extends State<DatabaseRecoveryPage> {
  bool _busy = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(Icons.storage, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    copy.databaseRecoveryTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    copy.databaseRecoveryDescription,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _reasonMessage(copy),
                    key: const ValueKey<String>('database-recovery-reason'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey<String>('retry-database-open'),
                    onPressed: _busy ? null : _retry,
                    child: Text(copy.databaseRecoveryRetry),
                  ),
                  OutlinedButton(
                    key: const ValueKey<String>('recovery-import-backup'),
                    onPressed: _busy ? null : () => unawaited(_import()),
                    child: Text(copy.databaseRecoveryImport),
                  ),
                  TextButton(
                    key: const ValueKey<String>('reset-database'),
                    onPressed: _busy ? null : _confirmReset,
                    child: Text(copy.databaseRecoveryReset),
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  if (_failed)
                    Text(
                      copy.failureDatabaseRecoveryCopy,
                      key: const ValueKey<String>('database-recovery-failure'),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _reasonMessage(AppLocalizations copy) {
    return switch (widget.reason) {
      DatabaseRecoveryReason.location => copy.failureDatabaseOpen,
      DatabaseRecoveryReason.unsupportedVersion =>
        copy.failureDatabaseMigration,
      DatabaseRecoveryReason.openOrIntegrity => copy.failureDatabaseCorrupted,
      DatabaseRecoveryReason.migrationOrData => copy.failureDatabaseMigration,
    };
  }

  Future<void> _retry() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final bool recovered;
    try {
      recovered = await widget.actions.retryOpen();
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _failed = !recovered;
    });
    if (recovered) {
      widget.onRecovered();
    }
  }

  Future<void> _confirmReset() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return DatabaseResetConfirmation(
          onConfirmed: () async {
            Navigator.of(dialogContext).pop();
            await _reset();
          },
        );
      },
    );
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final PreparedBackupImport? prepared;
    try {
      prepared = await widget.prepareImport();
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _busy = false;
      });
    }
    if (prepared != null && mounted) {
      await _showImportPreview(prepared);
    }
  }

  Future<void> _showImportPreview(PreparedBackupImport prepared) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool confirming = false;
        BackupFailure? failure;
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setDialogState,
              ) {
                return BackupImportPreviewDialog(
                  preview: prepared.preview,
                  confirming: confirming,
                  failure: failure,
                  onCancel: () => Navigator.of(dialogContext).pop(),
                  onConfirm: () {
                    unawaited(
                      _confirmPreparedImport(
                        dialogContext: dialogContext,
                        prepared: prepared,
                        setDialogState: setDialogState,
                        setConfirming: (bool value) => confirming = value,
                        setFailure: (BackupFailure? value) => failure = value,
                      ),
                    );
                  },
                );
              },
        );
      },
    );
  }

  Future<void> _confirmPreparedImport({
    required BuildContext dialogContext,
    required PreparedBackupImport prepared,
    required void Function(void Function()) setDialogState,
    required void Function(bool value) setConfirming,
    required void Function(BackupFailure? failure) setFailure,
  }) async {
    setDialogState(() {
      setConfirming(true);
      setFailure(null);
    });
    try {
      await widget.confirmImport(prepared);
    } on BackupFailure catch (failure) {
      if (dialogContext.mounted) {
        setDialogState(() {
          setConfirming(false);
          setFailure(failure);
        });
      }
      return;
    } on Object {
      if (dialogContext.mounted) {
        setDialogState(() {
          setConfirming(false);
          setFailure(const BackupFailure(key: BackupFailureKey.replacement));
        });
      }
      return;
    }
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }

  Future<void> _reset() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final bool recovered;
    try {
      recovered = await widget.actions.resetAfterRecoveryCopy();
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _failed = !recovered;
    });
    if (recovered) {
      widget.onRecovered();
    }
  }
}
