import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../../../shared/ui/public.dart'
    show ClockRhythmRadius, ClockRhythmSpace;
import '../domain/completion_group.dart';
import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import 'todo_inline_edit_session.dart';
import 'todo_providers.dart';
import 'todo_row.dart';
import 'todo_status_message.dart';
import 'todo_view_model.dart';

final class TodoListPanel extends ConsumerStatefulWidget {
  TodoListPanel({
    required Iterable<TodoSnapshot> todos,
    this.onEditedRowRemoved,
    super.key,
  }) : todos = List<TodoSnapshot>.unmodifiable(todos);

  final List<TodoSnapshot> todos;
  final VoidCallback? onEditedRowRemoved;

  @override
  ConsumerState<TodoListPanel> createState() => _TodoListPanelState();
}

final class _TodoListPanelState extends ConsumerState<TodoListPanel> {
  late final TodoInlineEditSession _editSession = TodoInlineEditSession(
    rename: (String id, String title) => ref
        .read(todoViewModelProvider.notifier)
        .renameTodo(id: id, title: title),
  );

  @override
  void didUpdateWidget(covariant TodoListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? editingTodoId = _editSession.todoId;
    if (editingTodoId != null &&
        !widget.todos.any((TodoSnapshot todo) => todo.id == editingTodoId)) {
      _editSession.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = ListenableBuilder(
      listenable: _editSession,
      builder: (BuildContext context, Widget? child) => _buildList(context),
    );
    if (Router.maybeOf(context)?.backButtonDispatcher == null) {
      return content;
    }
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!TickerMode.valuesOf(context).enabled ||
            _editSession.todoId == null ||
            ModalRoute.of(context)?.isCurrent == false) {
          return false;
        }
        _editSession.cancel();
        return true;
      },
      child: content,
    );
  }

  Widget _buildList(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final AsyncValue<TodoViewState> asyncState = ref.watch(
      todoViewModelProvider,
    );
    final bool enabled =
        !(asyncState.value?.isMutating ?? true) || _editSession.isSaving;
    final List<TodoSnapshot> incomplete = widget.todos
        .where((TodoSnapshot todo) => !todo.completed)
        .toList(growable: false);
    final List<TodoSnapshot> completed = widget.todos
        .where((TodoSnapshot todo) => todo.completed)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TodoStatusMessage(
          message: asyncState.value?.message,
          messageSerial: asyncState.value?.messageSerial ?? 0,
          validationError: _editSession.error,
        ),
        if (widget.todos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ClockRhythmSpace.space20,
            ),
            child: Text(
              localizations.todoListEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (incomplete.isNotEmpty)
          _TodoGroupList(
            group: CompletionGroup.incomplete,
            todos: incomplete,
            enabled: enabled,
            editSession: _editSession,
            onEditedRowRemoved: widget.onEditedRowRemoved,
          ),
        if (incomplete.isNotEmpty && completed.isNotEmpty)
          const SizedBox(height: ClockRhythmSpace.space16),
        if (completed.isNotEmpty)
          _TodoGroupList(
            group: CompletionGroup.completed,
            todos: completed,
            enabled: enabled,
            editSession: _editSession,
            onEditedRowRemoved: widget.onEditedRowRemoved,
          ),
      ],
    );
  }

  @override
  void dispose() {
    _editSession.dispose();
    super.dispose();
  }
}

final class _TodoGroupList extends ConsumerWidget {
  const _TodoGroupList({
    required this.group,
    required this.todos,
    required this.enabled,
    required this.editSession,
    this.onEditedRowRemoved,
  });

  final CompletionGroup group;
  final List<TodoSnapshot> todos;
  final bool enabled;
  final TodoInlineEditSession editSession;
  final VoidCallback? onEditedRowRemoved;

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
                editSession: editSession,
                enabled: enabled,
                onToggle: () =>
                    _afterTitleSaved(context, () => viewModel.toggleTodo(todo)),
                onDelete: () =>
                    _afterTitleSaved(context, () => viewModel.deleteTodo(todo)),
                onRowRemoved: onEditedRowRemoved,
                onMoveUp: () =>
                    _afterTitleSaved(context, () => viewModel.moveTodoUp(todo)),
                onMoveDown: () => _afterTitleSaved(
                  context,
                  () => viewModel.moveTodoDown(todo),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<bool> _afterTitleSaved(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    if (!await editSession.commit(AppLocalizations.of(context))) {
      return false;
    }
    return action();
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
