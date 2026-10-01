import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart'
    show
        ClockRhythmCard,
        ClockRhythmLayout,
        ClockRhythmRadius,
        ClockRhythmSpace;
import '../../../shared/ui/public.dart' show SemanticStatusAnnouncement;
import '../application/backup_failure.dart';
import '../application/prepare_backup_import.dart';
import 'backup_failure_copy.dart';
import 'backup_import_preview_dialog.dart';
import 'data_transfer_providers.dart';
import 'data_transfer_state.dart';
import 'data_transfer_view_model.dart';

final class DataManagementPanel extends ConsumerWidget {
  const DataManagementPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final DataTransferState state = ref.watch(dataTransferViewModelProvider);
    return ClockRhythmCard.unpadded(
      key: const ValueKey<String>('data-management-panel'),
      child: Padding(
        padding: EdgeInsets.all(
          ClockRhythmLayout.cardPaddingFor(MediaQuery.sizeOf(context).width),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const SizedBox.square(
                    dimension: 36,
                    child: Icon(
                      Icons.folder_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: ClockRhythmSpace.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(copy.backupTitle, style: theme.textTheme.titleLarge),
                      const SizedBox(height: ClockRhythmSpace.space4),
                      Text(
                        copy.backupDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClockRhythmSpace.space16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(ClockRhythmRadius.control),
              ),
              child: Padding(
                padding: const EdgeInsets.all(ClockRhythmSpace.space12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: ClockRhythmSpace.space8),
                    Expanded(
                      child: Text(
                        copy.backupPlainTextWarning,
                        key: const ValueKey<String>('data-plain-text-warning'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ClockRhythmSpace.space16),
            Wrap(
              spacing: ClockRhythmSpace.space8,
              runSpacing: ClockRhythmSpace.space8,
              children: <Widget>[
                FilledButton.icon(
                  key: const ValueKey<String>('export-backup'),
                  onPressed: state.isBusy
                      ? null
                      : () => _confirmExport(context, ref),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(copy.backupExport),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('import-backup'),
                  onPressed: state.isBusy
                      ? null
                      : () => _prepareImport(context, ref),
                  icon: const Icon(Icons.file_open_rounded),
                  label: Text(copy.backupImport),
                ),
              ],
            ),
            if (state.isBusy) const LinearProgressIndicator(),
            if (state.success == DataTransferSuccess.exported)
              SemanticStatusAnnouncement(
                message: copy.messageBackupExported,
                child: Text(
                  copy.messageBackupExported,
                  key: const ValueKey<String>('backup-exported-feedback'),
                ),
              ),
            if (state.success == DataTransferSuccess.imported)
              SemanticStatusAnnouncement(
                message: copy.messageBackupImported,
                child: Text(
                  copy.messageBackupImported,
                  key: const ValueKey<String>('backup-imported-feedback'),
                ),
              ),
            if (state.failure case final BackupFailure failure)
              SemanticStatusAnnouncement(
                message: backupFailureMessage(copy, failure),
                child: Text(
                  backupFailureMessage(copy, failure),
                  key: const ValueKey<String>('backup-failure-feedback'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (state.autoStartRepairRequired)
              Text(
                copy.autoStartStatusNeedsAction,
                key: const ValueKey<String>('backup-autostart-repair'),
              ),
            if (state.refreshRequired)
              ListTile(
                key: const ValueKey<String>('backup-refresh-retry'),
                contentPadding: EdgeInsets.zero,
                title: Text(copy.failureUnknown),
                trailing: TextButton(
                  onPressed: () => ref
                      .read(dataTransferViewModelProvider.notifier)
                      .retryRefresh(),
                  child: Text(copy.actionRetry),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExport(BuildContext context, WidgetRef ref) async {
    final AppLocalizations copy = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          key: const ValueKey<String>('export-backup-warning-dialog'),
          title: Text(copy.backupExport),
          content: Text(copy.backupPlainTextWarning),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(copy.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(copy.backupExport),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await ref.read(dataTransferViewModelProvider.notifier).exportBackup();
    }
  }

  Future<void> _prepareImport(BuildContext context, WidgetRef ref) async {
    final DataTransferViewModel viewModel = ref.read(
      dataTransferViewModelProvider.notifier,
    );
    await viewModel.prepareImport();
    if (!context.mounted) {
      return;
    }
    final PreparedBackupImport? prepared = ref
        .read(dataTransferViewModelProvider)
        .prepared;
    if (prepared == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Consumer(
          builder: (BuildContext context, WidgetRef dialogRef, Widget? child) {
            final DataTransferState state = dialogRef.watch(
              dataTransferViewModelProvider,
            );
            return BackupImportPreviewDialog(
              preview: prepared.preview,
              confirming: state.phase == DataTransferPhase.confirming,
              failure: state.failure,
              onCancel: () {
                dialogRef
                    .read(dataTransferViewModelProvider.notifier)
                    .cancelPreparedImport();
                Navigator.of(dialogContext).pop();
              },
              onConfirm: () async {
                await dialogRef
                    .read(dataTransferViewModelProvider.notifier)
                    .confirmImport();
                if (!dialogContext.mounted) {
                  return;
                }
                final DataTransferState next = dialogRef.read(
                  dataTransferViewModelProvider,
                );
                if (next.success == DataTransferSuccess.imported) {
                  Navigator.of(dialogContext).pop();
                }
              },
            );
          },
        );
      },
    );
  }
}
