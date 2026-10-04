import '../domain/completion_group.dart';

final class CreateTodoCommand {
  const CreateTodoCommand({required this.title, required this.date, this.time});

  final String title;
  final String date;
  final String? time;
}

final class RenameTodoCommand {
  const RenameTodoCommand({required this.id, required this.title});

  final String id;
  final String title;
}

final class UpdateTodoCommand {
  const UpdateTodoCommand({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
  });

  final String id;
  final String title;
  final String date;
  final String? time;
}

final class RescheduleTodoCommand {
  const RescheduleTodoCommand({
    required this.id,
    required this.date,
    required this.time,
  });

  final String id;
  final String date;
  final String? time;
}

final class ReorderTodosCommand {
  ReorderTodosCommand({
    required this.date,
    required this.group,
    required Iterable<String> orderedIds,
  }) : orderedIds = List<String>.unmodifiable(orderedIds);

  final String date;
  final CompletionGroup group;
  final List<String> orderedIds;
}
