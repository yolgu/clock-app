import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart'
    show AppLocalizations, ClockTimeFormatter, LocalDateFormatter;
import '../../../shared/ui/public.dart'
    show ClockRhythmSpace, LineGlyph, LineIcon, StableContentSlot;
import '../domain/local_calendar_date.dart';
import '../domain/todo_time.dart';
import '../domain/todo_title.dart';
import 'todo_date_math.dart';
import 'todo_providers.dart';
import 'todo_schedule_dialog.dart';
import 'todo_title_feedback.dart';

enum _TodoEditorVariant { today, selectedDate }

/// Where a new Todo is written: its title with the commands that schedule
/// and add it.
final class TodoEditor extends ConsumerStatefulWidget {
  /// The width from which a new Todo's field and commands share one line.
  static const double inlineMinimumWidth = 480;

  const TodoEditor.today({required this.date, this.focusNode, super.key})
    : _variant = _TodoEditorVariant.today;

  const TodoEditor.forDate({required this.date, this.focusNode, super.key})
    : _variant = _TodoEditorVariant.selectedDate;

  /// The date of the list this editor adds to, which a new Todo gets unless
  /// another date is picked for it.
  final LocalCalendarDate date;
  final FocusNode? focusNode;

  final _TodoEditorVariant _variant;

  @override
  ConsumerState<TodoEditor> createState() => _TodoEditorState();
}

final class _TodoEditorState extends ConsumerState<TodoEditor> {
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _ownedFocusNode = FocusNode(debugLabel: 'Todo title');
  FocusNode get _titleFocusNode => widget.focusNode ?? _ownedFocusNode;
  FocusNode? _submissionFocus;
  bool _focusMovedDuringSubmission = false;
  late LocalCalendarDate _date = widget.date;
  String? _time;
  bool _hasInteractedWithTitle = false;
  bool _isSubmitting = false;

  /// Whether the new Todo carries a date or time picked for it.
  bool get _hasPickedSchedule => _time != null || _date != widget.date;

  @override
  void didUpdateWidget(covariant TodoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
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
    };
    // The field shows its placeholder; this label stays available to
    // assistive technology.
    final Widget title = Semantics(
      label: titleLabel,
      child: TextField(
        key: const ValueKey<String>('todo-create-title'),
        controller: _titleController,
        focusNode: _titleFocusNode,
        enabled: !commandInFlight || _isSubmitting,
        readOnly: _isSubmitting,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: localizations.todoTodayPlaceholder,
          prefixIcon: const LineIcon(LineGlyph.plus, size: 18),
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
    final List<Widget> controls = <Widget>[
      _buildScheduleControl(context, localizations, editable),
      FilledButton.icon(
        key: const ValueKey<String>('todo-add'),
        onPressed: canSubmit ? () => unawaited(_submit()) : null,
        icon: const LineIcon(LineGlyph.plus),
        label: Text(localizations.todoActionAdd),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClockRhythmSpace.space8),
      child: LayoutBuilder(
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
      ),
    );
  }

  /// Opens the schedule dialog and shows what was picked: the time, led by
  /// the date when the Todo will land outside this editor's list.
  Widget _buildScheduleControl(
    BuildContext context,
    AppLocalizations localizations,
    bool enabled,
  ) {
    final String? time = _time;
    final String picked = <String>[
      if (_date != widget.date)
        LocalDateFormatter(
          Localizations.localeOf(context),
        ).formatMonthDay(TodoDateMath.toLocalDateTime(_date)),
      ?time,
    ].join(' ');
    final String label = picked.isEmpty
        ? localizations.todoActionAddTime
        : picked;
    final String semanticLabel = <String>[
      localizations.todoScheduleEdit,
      label,
    ].join(', ');
    final VoidCallback? pickSchedule = enabled
        ? () => unawaited(_pickSchedule())
        : null;
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Visibility(
            visible: _hasPickedSchedule,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: IconButton(
              key: const ValueKey<String>('todo-clear-time'),
              onPressed: enabled ? _forgetPickedSchedule : null,
              tooltip: localizations.timePickerClear,
              icon: const LineIcon(LineGlyph.close),
            ),
          ),
          Flexible(
            child: Semantics(
              label: semanticLabel,
              button: true,
              enabled: enabled,
              onTap: pickSchedule,
              excludeSemantics: true,
              child: OutlinedButton.icon(
                key: ValueKey<String>(
                  time == null ? 'todo-add-time' : 'todo-edit-time',
                ),
                onPressed: pickSchedule,
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
                  child: Text(label),
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
    final bool succeeded = await ref
        .read(todoDataControllerProvider.notifier)
        .createTodo(title: _titleController.text, date: _date, time: _time);
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      if (succeeded) {
        _titleController.clear();
        _date = widget.date;
        _time = null;
        _hasInteractedWithTitle = false;
      }
    });
    if (!succeeded) {
      FocusManager.instance.removeListener(_trackSubmissionFocus);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.removeListener(_trackSubmissionFocus);
      if (mounted &&
          widget.date == submittedDate &&
          TickerMode.valuesOf(context).enabled &&
          !_focusMovedDuringSubmission) {
        _titleFocusNode.requestFocus();
      }
    });
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

  /// Offers the current time when none is picked yet, since the command
  /// reads as adding a time.
  Future<void> _pickSchedule() async {
    final TodoSchedule? picked = await showTodoScheduleDialog(
      context: context,
      initial: (
        date: _date,
        time:
            _time ??
            const ClockTimeFormatter().formatLocalDateTime(DateTime.now()),
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _date = picked.date;
      _time = picked.time;
    });
  }

  void _forgetPickedSchedule() {
    setState(() {
      _date = widget.date;
      _time = null;
    });
  }
}
