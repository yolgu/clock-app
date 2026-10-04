import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart'
    show AppLocalizations, ClockTimeFormatter, LocalDateFormatter;
import '../../../shared/ui/public.dart'
    show ClockRhythmSpace, StableContentSlot;
import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_time.dart';
import '../domain/todo_title.dart';
import 'todo_date_math.dart';
import 'todo_providers.dart';
import 'todo_title_feedback.dart';

enum _TodoEditorVariant { today, selectedDate, edit }

final class TodoEditor extends ConsumerStatefulWidget {
  const TodoEditor.today({required this.date, this.focusNode, super.key})
    : todo = null,
      onFinished = null,
      _variant = _TodoEditorVariant.today;

  const TodoEditor.forDate({required this.date, this.focusNode, super.key})
    : todo = null,
      onFinished = null,
      _variant = _TodoEditorVariant.selectedDate;

  TodoEditor.edit({
    required TodoSnapshot todo,
    required this.onFinished,
    this.focusNode,
    super.key,
  }) : todo = todo,
       date = LocalCalendarDate.parse(todo.date),
       _variant = _TodoEditorVariant.edit;

  final LocalCalendarDate date;
  final TodoSnapshot? todo;
  final VoidCallback? onFinished;
  final FocusNode? focusNode;
  final _TodoEditorVariant _variant;

  @override
  ConsumerState<TodoEditor> createState() => _TodoEditorState();
}

final class _TodoEditorState extends ConsumerState<TodoEditor> {
  late final TextEditingController _titleController;
  final FocusNode _ownedFocusNode = FocusNode(debugLabel: 'Todo title');
  FocusNode get _titleFocusNode => widget.focusNode ?? _ownedFocusNode;
  FocusNode? _submissionFocus;
  bool _focusMovedDuringSubmission = false;
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
    FocusManager.instance.removeListener(_trackSubmissionFocus);
    _ownedFocusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final AsyncValue<TodoDataState> asyncState = ref.watch(
      todoDataControllerProvider,
    );
    final bool commandInFlight = asyncState.value?.isMutating ?? false;
    final TodoTitleFeedback feedback = _titleFeedback(localizations);
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
        icon: Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
        label: Text(
          _isEditing
              ? localizations.todoActionSave
              : localizations.todoActionAdd,
        ),
      ),
      if (_isEditing)
        OutlinedButton.icon(
          key: const ValueKey<String>('todo-cancel'),
          onPressed: commandInFlight || _isSubmitting
              ? null
              : widget.onFinished,
          icon: const Icon(Icons.close),
          label: Text(localizations.todoActionCancel),
        ),
    ];
    final Widget field = TextField(
      key: ValueKey<String>(
        _isEditing ? 'todo-edit-title' : 'todo-create-title',
      ),
      controller: _titleController,
      focusNode: _titleFocusNode,
      autofocus: _isEditing,
      enabled: !commandInFlight || _isSubmitting,
      readOnly: _isSubmitting,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: titleLabel,
        hintText: localizations.todoTodayPlaceholder,
        errorText: _hasInteractedWithTitle ? feedback.error : null,
      ),
      onChanged: (String value) {
        setState(() {
          _hasInteractedWithTitle = true;
        });
      },
      onEditingComplete: () {},
      onSubmitted: (String value) {
        if (feedback.isValid && !commandInFlight && !_isComposing) {
          unawaited(_submit());
        }
      },
    );
    final Widget? counter = feedback.shouldShowCounter
        ? Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.only(top: ClockRhythmSpace.space4),
              child: Text(
                localizations.todoValidationTitleCounter(
                  feedback.graphemeCount,
                  TodoTitle.maximumGraphemeLength,
                ),
                key: const ValueKey<String>('todo-title-counter'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          )
        : null;

    return Focus(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (!_isEditing ||
            event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.escape) {
          return KeyEventResult.ignored;
        }
        if (!commandInFlight && !_isSubmitting) {
          widget.onFinished?.call();
        }
        return KeyEventResult.handled;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ClockRhythmSpace.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            field,
            ?counter,
            const SizedBox(height: ClockRhythmSpace.space8),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: ClockRhythmSpace.space8,
              runSpacing: ClockRhythmSpace.space8,
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
      ),
    );
  }

  Widget _buildTimeControl(AppLocalizations localizations, bool enabled) {
    final String? currentTime = _time;
    final String semanticLabel = <String>[
      localizations.todoListEditTime,
      currentTime ?? localizations.todoActionAddTime,
    ].join(', ');
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Visibility(
            visible: currentTime != null,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: IconButton(
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
          ),
          Flexible(
            child: Semantics(
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
                key: ValueKey<String>(
                  currentTime == null ? 'todo-add-time' : 'todo-edit-time',
                ),
                onPressed: enabled
                    ? () {
                        unawaited(_selectTime());
                      }
                    : null,
                icon: const Icon(Icons.schedule),
                label: StableContentSlot(
                  labels: <String>[
                    localizations.todoActionAddTime,
                    const ClockTimeFormatter().formatComponents(
                      hour: 23,
                      minute: 59,
                    ),
                  ],
                  alignment: Alignment.center,
                  child: Text(currentTime ?? localizations.todoActionAddTime),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TodoTitleFeedback _titleFeedback(AppLocalizations localizations) {
    return TodoTitleFeedback.evaluate(_titleController.text, localizations);
  }

  bool get _isComposing =>
      _titleController.value.composing.isValid &&
      !_titleController.value.composing.isCollapsed;

  Future<void> _submit() async {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final TodoTitleFeedback feedback = _titleFeedback(localizations);
    setState(() {
      _hasInteractedWithTitle = true;
    });
    if (!feedback.isValid || _isSubmitting || _isComposing) {
      return;
    }
    TodoTime.optional(_time);
    setState(() {
      _isSubmitting = true;
    });
    final LocalCalendarDate submittedDate = widget.date;
    _submissionFocus = FocusManager.instance.primaryFocus;
    _focusMovedDuringSubmission = false;
    FocusManager.instance.addListener(_trackSubmissionFocus);
    final TodoDataController viewModel = ref.read(
      todoDataControllerProvider.notifier,
    );
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
      FocusManager.instance.removeListener(_trackSubmissionFocus);
      widget.onFinished?.call();
    } else if (succeeded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.removeListener(_trackSubmissionFocus);
        if (mounted &&
            widget.date == submittedDate &&
            TickerMode.valuesOf(context).enabled &&
            !_focusMovedDuringSubmission) {
          _titleFocusNode.requestFocus();
        }
      });
    } else {
      FocusManager.instance.removeListener(_trackSubmissionFocus);
    }
  }

  void _trackSubmissionFocus() {
    final FocusNode? focused = FocusManager.instance.primaryFocus;
    if (focused != null &&
        focused is! FocusScopeNode &&
        focused != _submissionFocus &&
        focused != _titleFocusNode) {
      _focusMovedDuringSubmission = true;
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
