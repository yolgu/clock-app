import 'package:characters/characters.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../domain/todo_title.dart';

final class TodoTitleFeedback {
  const TodoTitleFeedback({required this.graphemeCount, this.error});

  factory TodoTitleFeedback.evaluate(String text, AppLocalizations copy) {
    try {
      final TodoTitle title = TodoTitle.parse(text);
      return TodoTitleFeedback(graphemeCount: title.graphemeLength);
    } on ArgumentError {
      final String normalized = text.trim();
      final int count = normalized.characters.length;
      return TodoTitleFeedback(
        graphemeCount: count,
        error: normalized.isEmpty
            ? copy.todoValidationTitleRequired
            : count > TodoTitle.maximumGraphemeLength
            ? copy.todoValidationTitleTooLong(TodoTitle.maximumGraphemeLength)
            : copy.failureTodoAction,
      );
    }
  }

  final int graphemeCount;
  final String? error;
  bool get isValid => error == null;
  bool get shouldShowCounter => graphemeCount >= TodoTitle.counterThreshold;
}
