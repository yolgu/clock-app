import 'todo_id.dart';

sealed class TodoFailure implements Exception {
  const TodoFailure();
}

final class TodoLimitReachedFailure extends TodoFailure {
  const TodoLimitReachedFailure({
    required this.actualCount,
    required this.maximumCount,
  });

  final int actualCount;
  final int maximumCount;

  @override
  String toString() {
    return 'TodoLimitReachedFailure('
        'actualCount: $actualCount, maximumCount: $maximumCount)';
  }
}

final class TodoNotFoundFailure extends TodoFailure {
  const TodoNotFoundFailure(this.id);

  final TodoId id;

  @override
  String toString() => 'TodoNotFoundFailure(id: $id)';
}

final class TodoIdConflictFailure extends TodoFailure {
  const TodoIdConflictFailure(this.id);

  final TodoId id;

  @override
  String toString() => 'TodoIdConflictFailure(id: $id)';
}

enum TodoReorderFailureReason { duplicateIdentifier, notFullGroupPermutation }

final class InvalidTodoReorderFailure extends TodoFailure {
  const InvalidTodoReorderFailure(this.reason);

  final TodoReorderFailureReason reason;

  @override
  String toString() => 'InvalidTodoReorderFailure(reason: $reason)';
}
