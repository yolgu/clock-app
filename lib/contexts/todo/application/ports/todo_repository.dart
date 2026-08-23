import '../../domain/todo.dart';

typedef TodoMutation<T extends Object?> =
    TodoMutationResult<T> Function(List<Todo> currentTodos);

final class TodoMutationResult<T extends Object?> {
  TodoMutationResult({required List<Todo> todos, required this.value})
    : todos = List<Todo>.unmodifiable(todos);

  final List<Todo> todos;
  final T value;
}

abstract interface class TodoRepository {
  Future<List<Todo>> getAll();

  Future<void> saveAll(List<Todo> todos);

  Future<T> mutate<T extends Object?>(TodoMutation<T> mutation);
}
