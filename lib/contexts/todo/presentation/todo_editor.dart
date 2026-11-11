import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart'
    show AppLocalizations, ClockTimeFormatter, LocalDateFormatter;
import '../../../shared/ui/public.dart'
    show ClockRhythmSpace, LineGlyph, LineIcon, StableContentSlot;
import '../domain/local_calendar_date.dart';
import '../domain/todo.dart';
import '../domain/todo_time.dart';
import '../domain/todo_title.dart';
import 'todo_date_math.dart';
import 'todo_date_panel.dart';
import 'todo_picker_field.dart';
import 'todo_providers.dart';
import 'todo_time_panel.dart';
import 'todo_title_feedback.dart';

enum _TodoEditorVariant { today, selectedDate, edit }

/// Where an edit form is shown, which sets its sizes and command layout.
enum TodoEditSurface {
  /// A desktop dialog: commands at the end of one line.
  dialog,

  /// A phone bottom sheet: touch-sized pickers and full-width commands.
  sheet,
}

/// The picker an edit form has unfolded under one of its fields.
enum _OpenPicker { none, date, time }

final class TodoEditor extends ConsumerStatefulWidget {
  /// The width from which a new Todo's field and commands share one line.
  static const double inlineMinimumWidth = 480;

  const TodoEditor.today({required this.date, this.focusNode, super.key})
    : todo = null,
      onFinished = null,
      surface = TodoEditSurface.dialog,
      _variant = _TodoEditorVariant.today;

  const TodoEditor.forDate({required this.date, this.focusNode, super.key})
    : todo = null,
      onFinished = null,
      surface = TodoEditSurface.dialog,
      _variant = _TodoEditorVariant.selectedDate;

  TodoEditor.edit({
    required TodoSnapshot todo,
    required this.onFinished,
    this.surface = TodoEditSurface.dialog,
    this.focusNode,
    super.key,
  }) : todo = todo,
       date = LocalCalendarDate.parse(todo.date),
       _variant = _TodoEditorVariant.edit;

  final LocalCalendarDate date;
  final TodoSnapshot? todo;
  final VoidCallback? onFinished;
  final FocusNode? focusNode;

  final TodoEditSurface surface;
  final _TodoEditorVariant _variant;

  @override
  ConsumerState<TodoEditor> createState() => _TodoEditorState();
}

/// The width from which an edit form sets its date and time side by side;
/// below it the full date would be cut off.
const double _dateAndTimeRowMinimumWidth = 380;

/// Fits a 24-hour time or the add-time prompt with its clear or picker cue.
const double _timeFieldWidth = 136;

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
  _OpenPicker _openPicker = _OpenPicker.none;

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
    final bool editable = !commandInFlight && !_isSubmitting;
    final TodoTitleFeedback feedback = _titleFeedback(localizations);
    final bool canSubmit = feedback.isValid && editable;
    final String titleLabel = switch (widget._variant) {
      _TodoEditorVariant.today => localizations.todoTodayInputLabel,
      _TodoEditorVariant.selectedDate => localizations.todoTodayPlaceholder,
      _TodoEditorVariant.edit => localizations.todoListEditTitle,
    };
    // The field shows its placeholder or a separate visible label; this
    // label stays available to assistive technology.
    final Widget title = Semantics(
      label: titleLabel,
      child: TextField(
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
          hintText: localizations.todoTodayPlaceholder,
          prefixIcon: _isEditing
              ? null
              : const LineIcon(LineGlyph.plus, size: 18),
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
      ),
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

    if (_isEditing) {
      return Focus(
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is! KeyDownEvent ||
              event.logicalKey != LogicalKeyboardKey.escape) {
            return KeyEventResult.ignored;
          }
          if (editable) {
            widget.onFinished?.call();
          }
          return KeyEventResult.handled;
        },
        child: _buildEditForm(
          context,
          localizations,
          title: title,
          counter: counter,
          editable: editable,
          canSubmit: canSubmit,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClockRhythmSpace.space8),
      child: _buildComposer(
        localizations,
        title: title,
        counter: counter,
        editable: editable,
        canSubmit: canSubmit,
      ),
    );
  }

  /// A new Todo: one field with its time and add commands, on one line when
  /// there is room.
  Widget _buildComposer(
    AppLocalizations localizations, {
    required Widget title,
    required Widget? counter,
    required bool editable,
    required bool canSubmit,
  }) {
    final List<Widget> controls = <Widget>[
      _buildTimeControl(localizations, editable),
      FilledButton.icon(
        key: const ValueKey<String>('todo-add'),
        onPressed: canSubmit ? () => unawaited(_submit()) : null,
        icon: const LineIcon(LineGlyph.plus),
        label: Text(localizations.todoActionAdd),
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool inline =
            constraints.maxWidth >= TodoEditor.inlineMinimumWidth &&
            MediaQuery.textScalerOf(context).scale(16) <= 20;
        if (inline) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: title),
                  for (final Widget control in controls) ...<Widget>[
                    const SizedBox(width: ClockRhythmSpace.space8),
                    control,
                  ],
                ],
              ),
              ?counter,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            title,
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
        );
      },
    );
  }

  /// An existing Todo: labelled title, date and time fields over the
  /// form's commands.
  Widget _buildEditForm(
    BuildContext context,
    AppLocalizations localizations, {
    required Widget title,
    required Widget? counter,
    required bool editable,
    required bool canSubmit,
  }) {
    final String date = LocalDateFormatter(
      Localizations.localeOf(context),
    ).formatFullDate(TodoDateMath.toLocalDateTime(_date));
    final String? time = _time;
    final Widget dateField = _LabeledField(
      label: localizations.todoFieldDate,
      child: TodoPickerField(
        key: const ValueKey<String>('todo-edit-date'),
        semanticLabel: <String>[
          localizations.todoListEditDate,
          date,
        ].join(', '),
        value: date,
        placeholder: date,
        expanded: _openPicker == _OpenPicker.date,
        onPressed: editable ? () => _togglePicker(_OpenPicker.date) : null,
      ),
    );
    final Widget timeField = _LabeledField(
      label: localizations.todoFieldTime,
      child: TodoPickerField(
        key: ValueKey<String>(
          time == null ? 'todo-add-time' : 'todo-edit-time',
        ),
        semanticLabel: <String>[
          localizations.todoListEditTime,
          time ?? localizations.todoActionAddTime,
        ].join(', '),
        value: time,
        placeholder: localizations.todoActionAddTime,
        expanded: _openPicker == _OpenPicker.time,
        onPressed: editable ? () => _togglePicker(_OpenPicker.time) : null,
        clearAction: time == null
            ? null
            : IconButton(
                key: const ValueKey<String>('todo-clear-time'),
                onPressed: editable
                    ? () => setState(() {
                        _time = null;
                      })
                    : null,
                tooltip: localizations.timePickerClear,
                icon: const LineIcon(LineGlyph.close, size: 16),
              ),
      ),
    );
    final TodoDataState? data = ref.watch(todoDataControllerProvider).value;
    final bool touchSized = widget.surface == TodoEditSurface.sheet;
    final Widget? datePanel = _openPicker == _OpenPicker.date && data != null
        ? TodoDatePanel(
            selected: _date,
            today: data.todayDate,
            summaryForMonth: data.collection.summaryForMonth,
            enabled: editable,
            onSelected: _chooseDate,
          )
        : null;
    final ({int hour, int minute})? timeParts = time == null
        ? null
        : const ClockTimeFormatter().parse(time);
    final Widget? timePanel = _openPicker == _OpenPicker.time
        ? TodoTimePanel(
            hour: timeParts?.hour,
            minute: timeParts?.minute,
            touchSized: touchSized,
            enabled: editable,
            onHourSelected: _chooseHour,
            onMinuteSelected: _chooseMinute,
          )
        : null;
    final Widget save = FilledButton(
      key: const ValueKey<String>('todo-save'),
      onPressed: canSubmit ? () => unawaited(_submit()) : null,
      child: Text(localizations.todoActionSave),
    );
    final Widget cancel = TextButton(
      key: const ValueKey<String>('todo-cancel'),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: editable ? widget.onFinished : null,
      child: Text(localizations.todoActionCancel),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _LabeledField(label: localizations.todoFieldTitle, child: title),
        ?counter,
        const SizedBox(height: ClockRhythmSpace.space16),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool sideBySide =
                constraints.maxWidth >= _dateAndTimeRowMinimumWidth &&
                MediaQuery.textScalerOf(context).scale(16) <= 20;
            // An open picker unfolds right under its own field, or under
            // the shared row when date and time sit side by side.
            if (!sideBySide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  dateField,
                  ..._unfolded(datePanel),
                  const SizedBox(height: ClockRhythmSpace.space16),
                  timeField,
                  ..._unfolded(timePanel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: dateField),
                    const SizedBox(width: ClockRhythmSpace.space12),
                    SizedBox(width: _timeFieldWidth, child: timeField),
                  ],
                ),
                ..._unfolded(datePanel ?? timePanel),
              ],
            );
          },
        ),
        const SizedBox(height: ClockRhythmSpace.space24),
        if (widget.surface == TodoEditSurface.sheet)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              save,
              const SizedBox(height: ClockRhythmSpace.space8),
              cancel,
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              cancel,
              const SizedBox(width: ClockRhythmSpace.space8),
              save,
            ],
          ),
      ],
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
              icon: const LineIcon(LineGlyph.close),
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
                icon: const LineIcon(LineGlyph.clock),
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

  List<Widget> _unfolded(Widget? panel) {
    return panel == null
        ? const <Widget>[]
        : <Widget>[const SizedBox(height: ClockRhythmSpace.space8), panel];
  }

  void _togglePicker(_OpenPicker picker) {
    // The picker takes over from typing: the title gives up its ring and,
    // on a phone, the keyboard that would cover the panel.
    _titleFocusNode.unfocus();
    setState(() {
      _openPicker = _openPicker == picker ? _OpenPicker.none : picker;
    });
  }

  void _chooseDate(LocalCalendarDate date) {
    setState(() {
      _date = date;
      _openPicker = _OpenPicker.none;
    });
  }

  /// An hour keeps the panel open for the minute that usually follows.
  void _chooseHour(int hour) {
    setState(() {
      _time = const ClockTimeFormatter().formatComponents(
        hour: hour,
        minute: _currentTimeParts()?.minute ?? 0,
      );
    });
  }

  /// A minute completes the time, so the panel folds away.
  void _chooseMinute(int minute) {
    setState(() {
      _time = const ClockTimeFormatter().formatComponents(
        hour: _currentTimeParts()?.hour ?? TimeOfDay.now().hour,
        minute: minute,
      );
      _openPicker = _OpenPicker.none;
    });
  }

  ({int hour, int minute})? _currentTimeParts() {
    final String? time = _time;
    return time == null ? null : const ClockTimeFormatter().parse(time);
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

/// A form field under its visible name. The name is left to the field's
/// own semantic label so it is not announced twice.
final class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
