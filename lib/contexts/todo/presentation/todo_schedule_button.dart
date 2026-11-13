import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../../../shared/ui/public.dart' show LineGlyph, LineIcon;
import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import 'todo_inline_edit_session.dart';
import 'todo_providers.dart';
import 'todo_schedule_dialog.dart';

/// A Todo row's command for moving the Todo to another date or time.
final class TodoScheduleButton extends ConsumerStatefulWidget {
  const TodoScheduleButton({
    required this.todo,
    required this.enabled,
    required this.session,
    this.onRowRemoved,
    super.key,
  });

  final TodoSnapshot todo;
  final bool enabled;
  final TodoInlineEditSession session;

  /// Called when rescheduling took the Todo's row off the screen, so focus
  /// can move somewhere that still exists.
  final VoidCallback? onRowRemoved;

  @override
  ConsumerState<TodoScheduleButton> createState() => _TodoScheduleButtonState();
}

final class _TodoScheduleButtonState extends ConsumerState<TodoScheduleButton> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Todo schedule');
  bool _opening = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _reschedule() async {
    if (_opening) {
      return;
    }
    _opening = true;
    if (!await widget.session.commit(AppLocalizations.of(context)) ||
        !mounted ||
        !TickerMode.valuesOf(context).enabled) {
      _opening = false;
      return;
    }
    final TodoDataController controller = ref.read(
      todoDataControllerProvider.notifier,
    );
    final VoidCallback? onRowRemoved = widget.onRowRemoved;
    final TodoSnapshot todo = ref
        .read(todoDataControllerProvider)
        .requireValue
        .todosForDate(LocalCalendarDate.parse(widget.todo.date))
        .firstWhere((TodoSnapshot candidate) => candidate.id == widget.todo.id);
    final TodoSchedule current = (
      date: LocalCalendarDate.parse(todo.date),
      time: todo.time,
    );
    final TodoSchedule? chosen = await showTodoScheduleDialog(
      context: context,
      initial: current,
    );
    if (chosen != null && chosen != current) {
      await controller.rescheduleTodo(
        todo: todo,
        date: chosen.date,
        time: chosen.time,
      );
      // The list shows the outcome on its next frame; only then is it known
      // whether this row is still there to take the focus back.
      await WidgetsBinding.instance.endOfFrame;
    }
    _opening = false;
    if (mounted && TickerMode.valuesOf(context).enabled) {
      _focusNode.requestFocus();
    } else if (!mounted) {
      onRowRemoved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    return IconButton(
      key: ValueKey<String>('todo-schedule-${widget.todo.id}'),
      focusNode: _focusNode,
      onPressed: widget.enabled ? () => unawaited(_reschedule()) : null,
      tooltip: <String>[copy.todoScheduleEdit, widget.todo.title].join(', '),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: const LineIcon(LineGlyph.calendar, size: 20),
    );
  }
}
