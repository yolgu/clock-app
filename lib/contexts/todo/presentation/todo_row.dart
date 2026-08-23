import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../../../shared/ui/public.dart' show FocusRing, MinimumTapTarget;
import '../domain/todo.dart';
import 'todo_editor.dart';

final class TodoRow extends StatelessWidget {
  const TodoRow({
    required this.todo,
    required this.reorderIndex,
    required this.groupPosition,
    required this.groupLength,
    required this.isEditing,
    required this.enabled,
    required this.onToggle,
    required this.onDelete,
    required this.onStartEditing,
    required this.onFinishEditing,
    required this.onMoveUp,
    required this.onMoveDown,
    super.key,
  });

  final TodoSnapshot todo;
  final int reorderIndex;
  final int groupPosition;
  final int groupLength;
  final bool isEditing;
  final bool enabled;
  final Future<bool> Function() onToggle;
  final Future<bool> Function() onDelete;
  final VoidCallback onStartEditing;
  final VoidCallback onFinishEditing;
  final Future<bool> Function() onMoveUp;
  final Future<bool> Function() onMoveDown;

  bool get _canMoveUp => enabled && groupPosition > 0;

  bool get _canMoveDown => enabled && groupPosition < groupLength - 1;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      key: ValueKey<String>('todo-row-${todo.id}'),
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: isEditing
            ? _buildEditingRow(context)
            : LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double scaledBody = MediaQuery.textScalerOf(
                    context,
                  ).scale(16);
                  final bool useStackedActions =
                      constraints.maxWidth < 520 || scaledBody > 24;
                  return _buildDisplayRow(context, useStackedActions);
                },
              ),
      ),
    );
  }

  Widget _buildEditingRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildLeadingContent(context),
        TodoEditor.edit(todo: todo, onFinished: onFinishEditing),
      ],
    );
  }

  Widget _buildDisplayRow(BuildContext context, bool useStackedActions) {
    final Widget actions = _buildActions(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _buildReorderHandle(context),
            _buildCompletionControl(context),
            const SizedBox(width: 4),
            Expanded(child: _buildTodoCopy(context)),
            if (!useStackedActions) ...<Widget>[
              const SizedBox(width: 8),
              actions,
            ],
          ],
        ),
        if (useStackedActions) ...<Widget>[
          const SizedBox(height: 4),
          Align(alignment: AlignmentDirectional.centerEnd, child: actions),
        ],
      ],
    );
  }

  Widget _buildLeadingContent(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildReorderHandle(context),
        _buildCompletionControl(context),
        const SizedBox(width: 4),
        Expanded(child: _buildTodoCopy(context)),
      ],
    );
  }

  Widget _buildReorderHandle(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return ReorderableDragStartListener(
      index: reorderIndex,
      enabled: enabled && !isEditing,
      child: _TodoReorderHandle(
        label: localizations.todoActionReorder(todo.title),
        canMoveUp: _canMoveUp && !isEditing,
        canMoveDown: _canMoveDown && !isEditing,
        onMoveUp: onMoveUp,
        onMoveDown: onMoveDown,
      ),
    );
  }

  Widget _buildCompletionControl(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final String label = todo.completed
        ? localizations.todoActionReopen(todo.title)
        : localizations.todoActionComplete(todo.title);
    return Semantics(
      label: label,
      checked: todo.completed,
      enabled: enabled,
      onTap: enabled
          ? () {
              unawaited(onToggle());
            }
          : null,
      excludeSemantics: true,
      child: Checkbox(
        value: todo.completed,
        onChanged: enabled
            ? (bool? value) {
                unawaited(onToggle());
              }
            : null,
      ),
    );
  }

  Widget _buildTodoCopy(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          todo.title,
          key: ValueKey<String>('todo-title-${todo.id}'),
          overflow: TextOverflow.visible,
          style: textTheme.bodyLarge?.copyWith(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            fontWeight: todo.completed ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        if (todo.time case final String time)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              time,
              key: ValueKey<String>('todo-time-${todo.id}'),
              style: textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final String editLabel = <String>[
      localizations.todoActionEdit,
      todo.title,
    ].join(', ');
    final String deleteLabel = <String>[
      localizations.todoActionDelete,
      todo.title,
    ].join(', ');
    return Wrap(
      spacing: 4,
      children: <Widget>[
        Semantics(
          label: editLabel,
          button: true,
          enabled: enabled,
          onTap: enabled ? onStartEditing : null,
          excludeSemantics: true,
          child: IconButton(
            key: ValueKey<String>('todo-edit-${todo.id}'),
            onPressed: enabled ? onStartEditing : null,
            tooltip: localizations.todoActionEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
        Semantics(
          label: deleteLabel,
          button: true,
          enabled: enabled,
          onTap: enabled
              ? () {
                  unawaited(onDelete());
                }
              : null,
          excludeSemantics: true,
          child: IconButton(
            key: ValueKey<String>('todo-delete-${todo.id}'),
            onPressed: enabled
                ? () {
                    unawaited(onDelete());
                  }
                : null,
            tooltip: localizations.todoActionDelete,
            color: Theme.of(context).colorScheme.error,
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ],
    );
  }
}

final class _TodoReorderHandle extends StatefulWidget {
  const _TodoReorderHandle({
    required this.label,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final String label;
  final bool canMoveUp;
  final bool canMoveDown;
  final Future<bool> Function() onMoveUp;
  final Future<bool> Function() onMoveDown;

  @override
  State<_TodoReorderHandle> createState() => _TodoReorderHandleState();
}

final class _TodoReorderHandleState extends State<_TodoReorderHandle> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'todo reorder handle');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      enabled: widget.canMoveUp || widget.canMoveDown,
      excludeSemantics: true,
      child: FocusRing(
        focusNode: _focusNode,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
              widget.canMoveUp) {
            unawaited(widget.onMoveUp());
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
              widget.canMoveDown) {
            unawaited(widget.onMoveDown());
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focusNode.requestFocus,
            child: const MinimumTapTarget(child: Icon(Icons.drag_handle)),
          ),
        ),
      ),
    );
  }
}
