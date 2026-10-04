import 'package:flutter/material.dart';
import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../../../shared/ui/public.dart'
    show ClockRhythmSpace, StableContentSlot;
import '../domain/todo_title.dart';
import 'todo_providers.dart';

final class TodoStatusMessage extends StatelessWidget {
  const TodoStatusMessage({
    required this.message,
    required this.messageSerial,
    this.validationError,
    super.key,
  });

  final TodoUiMessage? message;
  final int messageSerial;
  final String? validationError;

  @override
  Widget build(BuildContext context) {
    final TodoUiMessage? current = message;
    final AppLocalizations localizations = AppLocalizations.of(context);
    final String? text =
        validationError ??
        switch (current) {
          TodoUiMessage.added => localizations.messageTodoAdded,
          TodoUiMessage.updated => localizations.messageTodoUpdated,
          TodoUiMessage.completed => localizations.messageTodoCompleted,
          TodoUiMessage.reopened => localizations.messageTodoReopened,
          TodoUiMessage.deleted => localizations.messageTodoDeleted,
          TodoUiMessage.limitReached => localizations.failureTodoLimitReached,
          TodoUiMessage.actionFailed => localizations.failureTodoAction,
          null => null,
        };
    final bool isError =
        current == TodoUiMessage.limitReached ||
        current == TodoUiMessage.actionFailed ||
        validationError != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClockRhythmSpace.space8),
      child: StableContentSlot(
        labels: <String>[
          localizations.messageTodoAdded,
          localizations.messageTodoUpdated,
          localizations.messageTodoCompleted,
          localizations.messageTodoReopened,
          localizations.messageTodoDeleted,
          localizations.failureTodoLimitReached,
          localizations.failureTodoAction,
          localizations.todoValidationTitleRequired,
          localizations.todoValidationTitleTooLong(
            TodoTitle.maximumGraphemeLength,
          ),
        ],
        child: text == null
            ? const SizedBox.shrink()
            : Semantics(
                key: ValueKey<int>(messageSerial),
                container: true,
                liveRegion: true,
                child: Text(
                  text,
                  style: TextStyle(
                    color: isError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
      ),
    );
  }
}

final class TodoLoadFailure extends StatelessWidget {
  const TodoLoadFailure({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ClockRhythmSpace.space16),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: ClockRhythmSpace.space12,
          runSpacing: ClockRhythmSpace.space8,
          children: <Widget>[
            Text(
              localizations.failureTodoAction,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(localizations.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}
