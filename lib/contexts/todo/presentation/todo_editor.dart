import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart'
    show AppLocalizations, ClockTimeFormatter, LocalDateFormatter;
import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_time.dart';
import '../domain/todo_title.dart';
import 'todo_date_math.dart';
import 'todo_providers.dart';
import 'todo_view_model.dart';

enum _TodoEditorVariant { today, selectedDate, edit }

final class TodoEditor extends ConsumerStatefulWidget {
  const TodoEditor.today({required this.date, super.key})
    : todo = null,
      onFinished = null,
      _variant = _TodoEditorVariant.today;

  const TodoEditor.forDate({required this.date, super.key})
    : todo = null,
      onFinished = null,
      _variant = _TodoEditorVariant.selectedDate;

  TodoEditor.edit({
    required TodoSnapshot todo,
    required this.onFinished,
    super.key,
  }) : todo = todo,
       date = LocalCalendarDate.parse(todo.date),
       _variant = _TodoEditorVariant.edit;

  final LocalCalendarDate date;
  final TodoSnapshot? todo;
  final VoidCallback? onFinished;
  final _TodoEditorVariant _variant;

  @override
  ConsumerState<TodoEditor> createState() => _TodoEditorState();
}

final class _TodoEditorState extends ConsumerState<TodoEditor> {
  late final TextEditingController _titleController;
  late LocalCalendarDate _date;
  String? _time;
  bool _hasInteractedWithTitle = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _date = widget.date;
    _time = widget.todo?.time;
  }

  @override
  void didUpdateWidget(covariant TodoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final TodoSnapshot? nextTodo = widget.todo;
    if (oldWidget.todo?.id != nextTodo?.id) {
      _titleController.text = nextTodo?.title ?? '';
      _time = nextTodo?.time;
      _hasInteractedWithTitle = false;
    }
    if (!_isEditing || oldWidget.todo?.id != nextTodo?.id) {
      _date = widget.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final AsyncValue<TodoViewState> asyncState = ref.watch(
      todoViewModelProvider,
    );
    final bool commandInFlight = asyncState.value?.isMutating ?? false;
    final _TitleFeedback feedback = _titleFeedback(localizations);
    final String titleLabel = switch (widget._variant) {
      _TodoEditorVariant.today => localizations.todoTodayInputLabel,
      _TodoEditorVariant.selectedDate => localizations.todoTodayPlaceholder,
      _TodoEditorVariant.edit => localizations.todoListEditTitle,
    };
    final List<Widget> controls = <Widget>[
      if (_isEditing)
        _buildDateControl(
          context,
          localizations,
          !commandInFlight && !_isSubmitting,
        ),
      _buildTimeControl(localizations, !commandInFlight && !_isSubmitting),
      FilledButton.icon(
        key: ValueKey<String>(_isEditing ? 'todo-save' : 'todo-add'),
        onPressed: feedback.isValid && !commandInFlight && !_isSubmitting
            ? () {
                unawaited(_submit());
              }
            : null,
        icon: Icon(_isEditing ? Icons.check : Icons.add),
        label: Text(
          _isEditing
              ? localizations.todoActionSave
              : localizations.todoActionAdd,
        ),
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      if (_isEditing)
        OutlinedButton.icon(
          key: const ValueKey<String>('todo-cancel'),
          onPressed: commandInFlight ? null : widget.onFinished,
          icon: const Icon(Icons.close),
          label: Text(localizations.todoActionCancel),
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
    ];

    return Focus(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (!_isEditing ||
            event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.escape) {
          return KeyEventResult.ignored;
        }
        widget.onFinished?.call();
        return KeyEventResult.handled;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: ValueKey<String>(
                _isEditing ? 'todo-edit-title' : 'todo-create-title',
              ),
              controller: _titleController,
              enabled: !commandInFlight && !_isSubmitting,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: titleLabel,
                hintText: localizations.todoTodayPlaceholder,
                errorText: _hasInteractedWithTitle ? feedback.error : null,
              ),
              onChanged: (String value) {
                setState(() {
                  _hasInteractedWithTitle = true;
                });
              },
              onSubmitted: (String value) {
                if (feedback.isValid && !commandInFlight) {
                  unawaited(_submit());
                }
              },
            ),
            if (feedback.shouldShowCounter)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    localizations.todoValidationTitleCounter(
                      feedback.graphemeCount,
                      TodoTitle.maximumGraphemeLength,
                    ),
                    key: const ValueKey<String>('todo-title-counter'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: controls,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateControl(
    BuildContext context,
    AppLocalizations localizations,
    bool enabled,
  ) {
    final LocalDateFormatter formatter = LocalDateFormatter(
      Localizations.localeOf(context),
    );
    final String formattedDate = formatter.formatCompactDate(
      TodoDateMath.toLocalDateTime(_date),
    );
    final String semanticLabel = <String>[
      localizations.todoListEditDate,
      formattedDate,
    ].join(', ');
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: enabled,
      onTap: enabled
          ? () {
              unawaited(_selectDate());
            }
          : null,
      excludeSemantics: true,
      child: OutlinedButton.icon(
        key: const ValueKey<String>('todo-edit-date'),
        onPressed: enabled
            ? () {
                unawaited(_selectDate());
              }
            : null,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(formattedDate),
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }

  Widget _buildTimeControl(AppLocalizations localizations, bool enabled) {
    final String? currentTime = _time;
    if (currentTime == null) {
      return OutlinedButton.icon(
        key: const ValueKey<String>('todo-add-time'),
        onPressed: enabled
            ? () {
                unawaited(_selectTime());
              }
            : null,
        icon: const Icon(Icons.schedule_outlined),
        label: Text(localizations.todoActionAddTime),
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      );
    }
    final String semanticLabel = <String>[
      localizations.todoListEditTime,
      currentTime,
    ].join(', ');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          label: semanticLabel,
          button: true,
          enabled: enabled,
          onTap: enabled
              ? () {
                  unawaited(_selectTime());
                }
              : null,
          excludeSemantics: true,
          child: OutlinedButton.icon(
            key: const ValueKey<String>('todo-edit-time'),
            onPressed: enabled
                ? () {
                    unawaited(_selectTime());
                  }
                : null,
            icon: const Icon(Icons.schedule),
            label: Text(currentTime),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ),
        IconButton(
          key: const ValueKey<String>('todo-clear-time'),
          onPressed: enabled
              ? () {
                  setState(() {
                    _time = null;
                  });
                }
              : null,
          tooltip: localizations.timePickerClear,
          icon: const Icon(Icons.clear),
        ),
      ],
    );
  }

  _TitleFeedback _titleFeedback(AppLocalizations localizations) {
    final String normalized = _titleController.text.trim();
    final int graphemeCount = normalized.characters.length;
    if (normalized.isEmpty) {
      return _TitleFeedback(
        error: localizations.todoValidationTitleRequired,
        graphemeCount: graphemeCount,
        isValid: false,
      );
    }
    if (graphemeCount > TodoTitle.maximumGraphemeLength) {
      return _TitleFeedback(
        error: localizations.todoValidationTitleTooLong(
          TodoTitle.maximumGraphemeLength,
        ),
        graphemeCount: graphemeCount,
        isValid: false,
      );
    }
    try {
      TodoTitle.parse(_titleController.text);
    } on ArgumentError {
      return _TitleFeedback(
        error: localizations.failureTodoAction,
        graphemeCount: graphemeCount,
        isValid: false,
      );
    }
    return _TitleFeedback(graphemeCount: graphemeCount, isValid: true);
  }

  Future<void> _submit() async {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final _TitleFeedback feedback = _titleFeedback(localizations);
    setState(() {
      _hasInteractedWithTitle = true;
    });
    if (!feedback.isValid || _isSubmitting) {
      return;
    }
    TodoTime.optional(_time);
    setState(() {
      _isSubmitting = true;
    });
    final TodoViewModel viewModel = ref.read(todoViewModelProvider.notifier);
    final TodoSnapshot? todo = widget.todo;
    final bool succeeded = todo == null
        ? await viewModel.createTodo(
            title: _titleController.text,
            date: _date,
            time: _time,
          )
        : await viewModel.updateTodo(
            todo: todo,
            title: _titleController.text,
            date: _date,
            time: _time,
          );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      if (succeeded && todo == null) {
        _titleController.clear();
        _time = null;
        _hasInteractedWithTitle = false;
      }
    });
    if (succeeded && todo != null) {
      widget.onFinished?.call();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: TodoDateMath.toLocalDateTime(_date),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      helpText: AppLocalizations.of(context).todoListEditDate,
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _date = TodoDateMath.fromLocalDateTime(selected);
    });
  }

  Future<void> _selectTime() async {
    final ClockTimeFormatter formatter = const ClockTimeFormatter();
    final String? currentTime = _time;
    final TimeOfDay initialTime;
    if (currentTime == null) {
      initialTime = TimeOfDay.now();
    } else {
      final ({int hour, int minute}) parts = formatter.parse(currentTime);
      initialTime = TimeOfDay(hour: parts.hour, minute: parts.minute);
    }
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: AppLocalizations.of(context).todoListEditTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _time = formatter.formatComponents(
        hour: selected.hour,
        minute: selected.minute,
      );
    });
  }
}

final class _TitleFeedback {
  const _TitleFeedback({
    required this.graphemeCount,
    required this.isValid,
    this.error,
  });

  final String? error;
  final int graphemeCount;
  final bool isValid;

  bool get shouldShowCounter => graphemeCount >= TodoTitle.counterThreshold;
}
