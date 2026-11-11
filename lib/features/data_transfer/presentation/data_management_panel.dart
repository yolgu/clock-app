import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart'
    show
        ClockRhythmCard,
        ClockRhythmLayout,
        ClockRhythmRadius,
        ClockRhythmSpace,
        LineGlyph,
        LineIcon;
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
    final double padding = ClockRhythmLayout.cardPaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    return Column(
      key: const ValueKey<String>('data-management-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClockRhythmCard.unpadded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        copy.backupTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      copy.backupDescription,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _BackupAction(
                padding: padding,
                icon: LineGlyph.upload,
                title: copy.backupExport,
                description: copy.backupExportDescription,
                command: FilledButton(
                  key: const ValueKey<String>('export-backup'),
                  onPressed: state.isBusy
                      ? null
                      : () => _confirmExport(context, ref),
                  child: Text(copy.backupExport),
                ),
              ),
              _BackupAction(
                padding: padding,
                icon: LineGlyph.download,
                title: copy.backupImport,
                description: copy.backupImportDescription,
                command: OutlinedButton(
                  key: const ValueKey<String>('import-backup'),
                  onPressed: state.isBusy
                      ? null
                      : () => _prepareImport(context, ref),
                  child: Text(copy.actionImportPortableBackup),
                ),
              ),
              SizedBox(
                height: ClockRhythmSpace.space4,
                child: state.isBusy ? const LinearProgressIndicator() : null,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (state.success == DataTransferSuccess.exported)
                      SemanticStatusAnnouncement(
                        message: copy.messageBackupExported,
                        child: Text(
                          copy.messageBackupExported,
                          key: const ValueKey<String>(
                            'backup-exported-feedback',
                          ),
                        ),
                      ),
                    if (state.success == DataTransferSuccess.imported)
                      SemanticStatusAnnouncement(
                        message: copy.messageBackupImported,
                        child: Text(
                          copy.messageBackupImported,
                          key: const ValueKey<String>(
                            'backup-imported-feedback',
                          ),
                        ),
                      ),
                    if (state.failure case final BackupFailure failure)
                      SemanticStatusAnnouncement(
                        message: backupFailureMessage(copy, failure),
                        child: Text(
                          backupFailureMessage(copy, failure),
                          key: const ValueKey<String>(
                            'backup-failure-feedback',
                          ),
                          style: TextStyle(color: theme.colorScheme.error),
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
                    const SizedBox(height: ClockRhythmSpace.space12),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClockRhythmSpace.space12),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(ClockRhythmRadius.control + 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClockRhythmSpace.space16,
              vertical: ClockRhythmSpace.space12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LineIcon(
                  LineGlyph.info,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: ClockRhythmSpace.space8),
                Expanded(
                  child: Text(
                    copy.backupPlainTextWarning,
                    key: const ValueKey<String>('data-plain-text-warning'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClockRhythmSpace.space20),
        const _BackupScope(),
      ],
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

/// One backup command as a row: what it does on the left, the button on the
/// right, separated from its neighbours by a hairline.
final class _BackupAction extends StatelessWidget {
  const _BackupAction({
    required this.padding,
    required this.icon,
    required this.title,
    required this.description,
    required this.command,
  });

  final double padding;
  final LineGlyph icon;
  final String title;
  final String description;
  final Widget command;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget copy = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface,
              0.5,
            ),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(ClockRhythmRadius.control),
          ),
          child: SizedBox.square(
            dimension: 36,
            child: LineIcon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: ClockRhythmSpace.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: ClockRhythmSpace.space16,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < _sideBySideMinimumWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  copy,
                  const SizedBox(height: ClockRhythmSpace.space12),
                  command,
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: copy),
                const SizedBox(width: ClockRhythmSpace.space16),
                command,
              ],
            );
          },
        ),
      ),
    );
  }

  static const double _sideBySideMinimumWidth = 520;
}

/// What a Portable Backup carries and what it leaves on the device.
final class _BackupScope extends StatelessWidget {
  const _BackupScope();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final List<Widget> included = <Widget>[
      _ScopeItem(included: true, text: copy.backupScopeIncludedPreferences),
      _ScopeItem(included: true, text: copy.backupScopeIncludedTodos),
    ];
    final List<Widget> excluded = <Widget>[
      _ScopeItem(included: false, text: copy.backupScopeExcludedRhythm),
      _ScopeItem(included: false, text: copy.backupScopeExcludedDrafts),
      _ScopeItem(included: false, text: copy.backupScopeExcludedFiles),
    ];
    return Column(
      key: const ValueKey<String>('backup-scope'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            copy.backupScopeTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: ClockRhythmSpace.space12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[...included, ...excluded],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Column(children: included)),
                const SizedBox(width: ClockRhythmSpace.space20),
                Expanded(child: Column(children: excluded)),
              ],
            );
          },
        ),
      ],
    );
  }
}

final class _ScopeItem extends StatelessWidget {
  const _ScopeItem({required this.included, required this.text});

  final bool included;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: ClockRhythmSpace.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LineIcon(
            included ? LineGlyph.check : LineGlyph.minus,
            size: 16,
            color: included
                ? theme.colorScheme.secondary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: ClockRhythmSpace.space8),
          Expanded(
            child: Text(
              text,
              style: included
                  ? theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    )
                  : theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
