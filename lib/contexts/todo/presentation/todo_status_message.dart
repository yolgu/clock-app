import 'package:flutter/material.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../../../shared/ui/public.dart' show ClockRhythmSpace;
import 'todo_view_model.dart';

final class TodoStatusMessage extends StatelessWidget {
  const TodoStatusMessage({
    required this.message,
    required this.messageSerial,
    super.key,
  });

  final TodoUiMessage? message;
  final int messageSerial;

  @override
  Widget build(BuildContext context) {
    final TodoUiMessage? current = message;
    if (current == null) {
      return const SizedBox.shrink();
    }
    final AppLocalizations localizations = AppLocalizations.of(context);
    final String text = switch (current) {
      TodoUiMessage.added => localizations.messageTodoAdded,
      TodoUiMessage.updated => localizations.messageTodoUpdated,
      TodoUiMessage.completed => localizations.messageTodoCompleted,
      TodoUiMessage.reopened => localizations.messageTodoReopened,
      TodoUiMessage.deleted => localizations.messageTodoDeleted,
      TodoUiMessage.limitReached => localizations.failureTodoLimitReached,
      TodoUiMessage.actionFailed => localizations.failureTodoAction,
    };
    final bool isError =
        current == TodoUiMessage.limitReached ||
        current == TodoUiMessage.actionFailed;
    return Semantics(
      key: ValueKey<int>(messageSerial),
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ClockRhythmSpace.space8),
        child: Text(
          text,
          style: TextStyle(
            color: isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.secondary,
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
