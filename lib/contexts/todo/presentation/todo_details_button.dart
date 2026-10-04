import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../../../shared/ui/public.dart' show ClockRhythmSpace;
import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import 'todo_editor.dart';
import 'todo_inline_edit_session.dart';
import 'todo_providers.dart';
import 'todo_status_message.dart';

final class TodoDetailsButton extends ConsumerStatefulWidget {
  const TodoDetailsButton({
    required this.todo,
    required this.enabled,
    required this.session,
    this.onRowRemoved,
    super.key,
  });

  final TodoSnapshot todo;
  final bool enabled;
  final TodoInlineEditSession session;
  final VoidCallback? onRowRemoved;

  @override
  ConsumerState<TodoDetailsButton> createState() => _TodoDetailsButtonState();
}

final class _TodoDetailsButtonState extends ConsumerState<TodoDetailsButton> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Todo details');
  bool _opening = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _open() async {
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
    final TodoSnapshot todo = ref
        .read(todoDataControllerProvider)
        .requireValue
        .todosForDate(LocalCalendarDate.parse(widget.todo.date))
        .firstWhere((TodoSnapshot candidate) => candidate.id == widget.todo.id);
    final VoidCallback? onRowRemoved = widget.onRowRemoved;
    ModalRoute<void>? detailsRoute;
    if (Theme.of(context).platform == TargetPlatform.android) {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        enableDrag: false,
        builder: (BuildContext context) {
          detailsRoute = ModalRoute.of<void>(context);
          return _TodoDetailsSurface(todo: todo, isSheet: true);
        },
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          detailsRoute = ModalRoute.of<void>(context);
          return _TodoDetailsSurface(todo: todo, isSheet: false);
        },
      );
    }
    await detailsRoute?.completed;
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
      key: ValueKey<String>('todo-edit-${widget.todo.id}'),
      focusNode: _focusNode,
      onPressed: widget.enabled ? () => unawaited(_open()) : null,
      tooltip: <String>[copy.todoActionDetails, widget.todo.title].join(', '),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: const Icon(Icons.info_outline_rounded, size: 20),
    );
  }
}

final class _TodoDetailsSurface extends ConsumerWidget {
  const _TodoDetailsSurface({required this.todo, required this.isSheet});

  final TodoSnapshot todo;
  final bool isSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool saving =
        ref.watch(todoDataControllerProvider).value?.isMutating ?? false;
    final TodoDataState? state = ref.watch(todoDataControllerProvider).value;
    final Widget form = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          AppLocalizations.of(context).todoActionDetails,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: ClockRhythmSpace.space16),
        TodoEditor.edit(
          todo: todo,
          onFinished: () => Navigator.of(context).pop(),
        ),
        TodoStatusMessage(
          message: state?.message == TodoUiMessage.actionFailed
              ? state?.message
              : null,
          messageSerial: state?.messageSerial ?? 0,
        ),
      ],
    );
    return PopScope<void>(
      canPop: !saving,
      child: isSheet
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ClockRhythmSpace.space24),
                child: form,
              ),
            )
          : Dialog(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ClockRhythmSpace.space24),
                child: form,
              ),
            ),
    );
  }
}
