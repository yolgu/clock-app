import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../../../shared/ui/public.dart'
    show ClockRhythmRadius, ClockRhythmSpace;
import '../domain/completion_group.dart';
import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import 'todo_providers.dart';
import 'todo_row.dart';
import 'todo_view_model.dart';

final class TodoListPanel extends ConsumerStatefulWidget {
  TodoListPanel({required Iterable<TodoSnapshot> todos, super.key})
    : todos = List<TodoSnapshot>.unmodifiable(todos);

  final List<TodoSnapshot> todos;

  @override
  ConsumerState<TodoListPanel> createState() => _TodoListPanelState();
}

final class _TodoListPanelState extends ConsumerState<TodoListPanel> {
  String? _editingTodoId;

  @override
  void didUpdateWidget(covariant TodoListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? editingTodoId = _editingTodoId;
    if (editingTodoId != null &&
        !widget.todos.any((TodoSnapshot todo) => todo.id == editingTodoId)) {
      _editingTodoId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    if (widget.todos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: ClockRhythmSpace.space20),
        child: Text(
          localizations.todoListEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final AsyncValue<TodoViewState> asyncState = ref.watch(
      todoViewModelProvider,
    );
    final bool enabled = !(asyncState.value?.isMutating ?? true);
    final List<TodoSnapshot> incomplete = widget.todos
        .where((TodoSnapshot todo) => !todo.completed)
        .toList(growable: false);
    final List<TodoSnapshot> completed = widget.todos
        .where((TodoSnapshot todo) => todo.completed)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (incomplete.isNotEmpty)
          _TodoGroupList(
            group: CompletionGroup.incomplete,
            todos: incomplete,
            enabled: enabled,
            editingTodoId: _editingTodoId,
            onStartEditing: _startEditing,
            onFinishEditing: _finishEditing,
          ),
        if (incomplete.isNotEmpty && completed.isNotEmpty)
          const SizedBox(height: ClockRhythmSpace.space16),
        if (completed.isNotEmpty)
          _TodoGroupList(
            group: CompletionGroup.completed,
            todos: completed,
            enabled: enabled,
            editingTodoId: _editingTodoId,
            onStartEditing: _startEditing,
            onFinishEditing: _finishEditing,
          ),
      ],
    );
  }

  void _startEditing(String id) {
    setState(() {
      _editingTodoId = id;
    });
  }

  void _finishEditing() {
    setState(() {
      _editingTodoId = null;
    });
  }
}

final class _TodoGroupList extends ConsumerWidget {
  const _TodoGroupList({
    required this.group,
    required this.todos,
    required this.enabled,
    required this.editingTodoId,
    required this.onStartEditing,
    required this.onFinishEditing,
  });

  final CompletionGroup group;
  final List<TodoSnapshot> todos;
  final bool enabled;
  final String? editingTodoId;
  final void Function(String id) onStartEditing;
  final VoidCallback onFinishEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String heading = switch (group) {
      CompletionGroup.incomplete => localizations.todoGroupIncomplete,
      CompletionGroup.completed => localizations.todoGroupCompleted,
    };
    final String count = switch (group) {
      CompletionGroup.incomplete => localizations.todoCount(todos.length),
      CompletionGroup.completed => localizations.todoCompletedCount(
        todos.length,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: ClockRhythmSpace.space8),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: ClockRhythmSpace.space8,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  heading,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(count, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ReorderableListView.builder(
          key: ValueKey<String>('todo-group-${group.name}'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: todos.length,
          onReorderItem: enabled
              ? (int oldIndex, int newIndex) {
                  _reorder(ref, oldIndex, newIndex);
                }
              : (int oldIndex, int newIndex) {},
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
                return Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  elevation: 8,
                  shadowColor: Colors.black,
                  borderRadius: BorderRadius.circular(
                    ClockRhythmRadius.control,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                );
              },
          itemBuilder: (BuildContext context, int index) {
            final TodoSnapshot todo = todos[index];
            final TodoViewModel viewModel = ref.read(
              todoViewModelProvider.notifier,
            );
            return DecoratedBox(
              key: ValueKey<String>(todo.id),
              decoration: BoxDecoration(
                border: index == todos.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      ),
              ),
              child: TodoRow(
                todo: todo,
                reorderIndex: index,
                groupPosition: index,
                groupLength: todos.length,
                isEditing: editingTodoId == todo.id,
                enabled: enabled,
                onToggle: () => viewModel.toggleTodo(todo),
                onDelete: () => viewModel.deleteTodo(todo),
                onStartEditing: () => onStartEditing(todo.id),
                onFinishEditing: onFinishEditing,
                onMoveUp: () => viewModel.moveTodoUp(todo),
                onMoveDown: () => viewModel.moveTodoDown(todo),
              ),
            );
          },
        ),
      ],
    );
  }

  void _reorder(WidgetRef ref, int oldIndex, int newIndex) {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= todos.length ||
        newIndex >= todos.length) {
      return;
    }
    final List<String> orderedIds = todos
        .map((TodoSnapshot todo) => todo.id)
        .toList(growable: true);
    final String movedId = orderedIds.removeAt(oldIndex);
    orderedIds.insert(newIndex, movedId);
    final LocalCalendarDate date = LocalCalendarDate.parse(todos.first.date);
    unawaited(
      ref
          .read(todoViewModelProvider.notifier)
          .reorderTodoGroup(date: date, group: group, orderedIds: orderedIds),
    );
  }
}
