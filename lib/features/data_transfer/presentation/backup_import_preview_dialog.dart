import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart' show ClockRhythmSpace;
import '../application/backup_failure.dart';
import '../application/backup_preview.dart';
import 'backup_failure_copy.dart';

final class BackupImportPreviewDialog extends StatelessWidget {
  const BackupImportPreviewDialog({
    required this.preview,
    required this.confirming,
    required this.onCancel,
    required this.onConfirm,
    this.failure,
    super.key,
  });

  final BackupPreview preview;
  final bool confirming;
  final BackupFailure? failure;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): confirming
            ? () {}
            : onCancel,
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          key: const ValueKey<String>('backup-import-preview-dialog'),
          title: Text(copy.backupPreviewTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(copy.backupImportConfirmDescription),
                const SizedBox(height: ClockRhythmSpace.space12),
                Text(copy.backupSummaryTodos(preview.todoCount)),
                Text(
                  copy.backupSummaryCompletedTodos(preview.completedTodoCount),
                ),
                Text(
                  preview.earliestTodoDate == null
                      ? copy.backupSummaryNoDateRange
                      : copy.backupSummaryDateRange(
                          preview.earliestTodoDate!,
                          preview.latestTodoDate!,
                        ),
                ),
                Text(
                  copy.backupSummaryTerms(
                    preview.focusMinutes,
                    preview.restMinutes,
                  ),
                ),
                Text(
                  copy.backupSummaryWindow(
                    preview.dailyStart,
                    preview.dailyEnd,
                  ),
                ),
                Text(copy.backupSummaryLanguage(preview.languageId)),
                Text(copy.backupSummaryTheme(preview.themeId)),
                Text(
                  preview.autoStartEnabled
                      ? copy.backupSummaryAutoStartEnabled
                      : copy.backupSummaryAutoStartDisabled,
                ),
                Text(
                  copy.backupSummaryExportedAt(
                    preview.exportedAt.toIso8601String(),
                  ),
                ),
                if (preview.customSoundWasSanitized)
                  Text(
                    copy.backupSummaryCustomSoundSanitized,
                    key: const ValueKey<String>('custom-sound-sanitized'),
                  ),
                const SizedBox(height: ClockRhythmSpace.space12),
                Text(
                  copy.backupPlainTextWarning,
                  key: const ValueKey<String>('backup-plain-text-warning'),
                ),
                Text(
                  copy.backupRhythmStopWarning,
                  key: const ValueKey<String>('backup-rhythm-stop-warning'),
                ),
                if (failure case final BackupFailure currentFailure)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: ClockRhythmSpace.space12,
                    ),
                    child: Text(
                      backupFailureMessage(copy, currentFailure),
                      key: const ValueKey<String>('backup-confirm-failure'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              key: const ValueKey<String>('cancel-backup-import'),
              onPressed: confirming ? null : onCancel,
              child: Text(copy.backupCancel),
            ),
            FilledButton(
              key: const ValueKey<String>('confirm-backup-import'),
              onPressed: confirming ? null : onConfirm,
              child: confirming
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(copy.backupConfirmImport),
            ),
          ],
        ),
      ),
    );
  }
}
