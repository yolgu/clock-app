import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart'
    show AppLocalizations, ClockTimeFormatter, ClockTimeParts;
import '../../../shared/ui/public.dart'
    show ClockRhythmSpace, LineGlyph, LineIcon;
import '../domain/local_calendar_date.dart';
import 'todo_date_panel.dart';
import 'todo_providers.dart';

/// When a Todo happens: its date and, when it has one, its 24-hour `HH:mm`
/// time.
typedef TodoSchedule = ({LocalCalendarDate date, String? time});

/// Asks for a Todo's date and optional time in a dialog. Completes once the
/// dialog has left the screen, with null when it was dismissed without
/// confirming.
Future<TodoSchedule?> showTodoScheduleDialog({
  required BuildContext context,
  required TodoSchedule initial,
}) async {
  ModalRoute<Object?>? route;
  final TodoSchedule? chosen = await showDialog<TodoSchedule>(
    context: context,
    builder: (BuildContext context) {
      route = ModalRoute.of(context);
      return TodoScheduleDialog(initial: initial);
    },
  );
  await route?.completed;
  return chosen;
}

/// A Todo's schedule: its time as an hour and a minute that can each be typed
/// or stepped, over the month its date is picked from.
final class TodoScheduleDialog extends ConsumerStatefulWidget {
  const TodoScheduleDialog({required this.initial, super.key});

  final TodoSchedule initial;

  @override
  ConsumerState<TodoScheduleDialog> createState() => _TodoScheduleDialogState();
}

final class _TodoScheduleDialogState extends ConsumerState<TodoScheduleDialog> {
  /// Fits the hour and the minute with their steppers on one line.
  static const double _maximumWidth = 368;

  /// The distance between the minutes the stepper stops at.
  static const int _minuteStep = 5;

  late LocalCalendarDate _date = widget.initial.date;
  late final _TimeDraft _time = _TimeDraft(
    initial: widget.initial.time,
    minuteStep: _minuteStep,
  );

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_time.isValid) {
      Navigator.of(
        context,
      ).pop<TodoSchedule>((date: _date, time: _time.formatted));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final TodoDataState? data = ref.watch(todoDataControllerProvider).value;
    return Dialog(
      // A phone keeps enough width for seven day cells.
      insetPadding: const EdgeInsets.symmetric(
        horizontal: ClockRhythmSpace.space16,
        vertical: ClockRhythmSpace.space24,
      ),
      constraints: const BoxConstraints(maxWidth: _maximumWidth),
      child: Padding(
        padding: const EdgeInsets.all(ClockRhythmSpace.space24),
        child: ListenableBuilder(
          listenable: _time.changes,
          builder: (BuildContext context, Widget? child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    copy.todoScheduleEdit,
                    style: theme.dialogTheme.titleTextStyle,
                  ),
                ),
                const SizedBox(height: ClockRhythmSpace.space16),
                // A short window scrolls the pickers; the title and the
                // commands stay in view.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildTime(theme, copy),
                        if (!_time.isValid)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: ClockRhythmSpace.space8,
                            ),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                copy.timePickerInvalid,
                                key: const ValueKey<String>(
                                  'todo-time-invalid',
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: ClockRhythmSpace.space16),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: ClockRhythmSpace.space8),
                        if (data != null)
                          TodoDatePanel(
                            selected: _date,
                            today: data.todayDate,
                            summaryForMonth: data.collection.summaryForMonth,
                            onSelected: (LocalCalendarDate date) {
                              setState(() {
                                _date = date;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: ClockRhythmSpace.space20),
                _buildCommands(theme, copy),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTime(ThemeData theme, AppLocalizations copy) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _TimePartField(
            draft: _time.hour,
            label: copy.todoTimeHours,
            keyPrefix: 'todo-time-hour',
            invalid: _time.rejects(_time.hour),
            autofocus: true,
            onStep: (int direction) => _time.step(_time.hour, direction),
            onSubmitted: _confirm,
          ),
        ),
        ExcludeSemantics(
          child: SizedBox(
            width: ClockRhythmSpace.space20,
            child: Text(
              ClockTimeFormatter.separator,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w300,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: _TimePartField(
            draft: _time.minute,
            label: copy.todoTimeMinutes,
            keyPrefix: 'todo-time-minute',
            invalid: _time.rejects(_time.minute),
            onStep: (int direction) => _time.step(_time.minute, direction),
            onSubmitted: _confirm,
          ),
        ),
      ],
    );
  }

  /// Clearing the time sits apart from the commands that close the dialog.
  /// Enlarged text moves them onto separate lines instead of pushing them
  /// past the dialog's edge.
  Widget _buildCommands(ThemeData theme, AppLocalizations copy) {
    final ButtonStyle quiet = TextButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurfaceVariant,
    );
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: ClockRhythmSpace.space8,
      runSpacing: ClockRhythmSpace.space8,
      children: <Widget>[
        TextButton(
          key: const ValueKey<String>('todo-schedule-clear-time'),
          style: quiet,
          onPressed: _time.isEmpty ? null : _time.clear,
          child: Text(copy.todoScheduleClearTime),
        ),
        Wrap(
          spacing: ClockRhythmSpace.space8,
          runSpacing: ClockRhythmSpace.space8,
          children: <Widget>[
            TextButton(
              key: const ValueKey<String>('todo-schedule-cancel'),
              style: quiet,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(copy.actionCancel),
            ),
            FilledButton(
              key: const ValueKey<String>('todo-schedule-confirm'),
              onPressed: _time.isValid ? _confirm : null,
              child: Text(copy.actionConfirm),
            ),
          ],
        ),
      ],
    );
  }
}

/// A Todo's optional time while it is typed: an hour and a minute that are
/// either both empty, meaning no time, or together name a time of day.
final class _TimeDraft {
  _TimeDraft({required String? initial, required int minuteStep})
    : this._(
        initial == null ? null : const ClockTimeFormatter().parse(initial),
        minuteStep,
      );

  _TimeDraft._(ClockTimeParts? initial, int minuteStep)
    : hour = _TimePartDraft(
        initialValue: initial?.hour,
        cycleLength: TimeOfDay.hoursPerDay,
        step: 1,
      ),
      minute = _TimePartDraft(
        initialValue: initial?.minute,
        cycleLength: TimeOfDay.minutesPerHour,
        step: minuteStep,
      );

  final _TimePartDraft hour;
  final _TimePartDraft minute;

  /// Notifies whenever either part's text changes.
  late final Listenable changes = Listenable.merge(<Listenable>[
    hour.controller,
    minute.controller,
  ]);

  bool get isEmpty => hour.isEmpty && minute.isEmpty;

  bool get isValid => isEmpty || formatted != null;

  /// The typed time as `HH:mm`; null when there is no time or the parts do
  /// not name one yet.
  String? get formatted {
    final int? hourValue = hour.value;
    final int? minuteValue = minute.value;
    return hourValue == null || minuteValue == null
        ? null
        : const ClockTimeFormatter().formatComponents(
            hour: hourValue,
            minute: minuteValue,
          );
  }

  /// Whether [part] is what keeps the draft from naming a time.
  bool rejects(_TimePartDraft part) => !isEmpty && part.value == null;

  /// Steps [part]. Stepping out of an empty time starts the other part at
  /// zero so the two name a time at once.
  void step(_TimePartDraft part, int direction) {
    final _TimePartDraft other = identical(part, hour) ? minute : hour;
    if (other.isEmpty) {
      other.startAtZero();
    }
    part.stepBy(direction);
  }

  void clear() {
    hour.clear();
    minute.clear();
  }

  void dispose() {
    hour.dispose();
    minute.dispose();
  }
}

/// One editable part of a clock time, the hour or the minute. Its text is
/// the user's draft; [value] is that draft once it names a real value.
final class _TimePartDraft {
  _TimePartDraft({
    required int? initialValue,
    required this.cycleLength,
    required this.step,
  }) : controller = TextEditingController(
         text: initialValue == null ? '' : _twoDigits(initialValue),
       ) {
    focusNode.addListener(_selectAllWhenFocused);
  }

  /// How many values the part has before it wraps: 24 hours or 60 minutes.
  final int cycleLength;

  /// The distance between the values the stepper stops at.
  final int step;

  final TextEditingController controller;
  final FocusNode focusNode = FocusNode();

  bool get isEmpty => controller.text.isEmpty;

  int? get value {
    final int? parsed = int.tryParse(controller.text);
    return parsed != null && parsed < cycleLength ? parsed : null;
  }

  /// Moves to the nearest stop above or below, wrapping past either end. A
  /// draft that names no value steps from zero.
  void stepBy(int direction) {
    final int current = value ?? 0;
    final int stop = direction > 0
        ? (current ~/ step + 1) * step
        : ((current + step - 1) ~/ step - 1) * step;
    controller.text = _twoDigits(stop % cycleLength);
    selectAll();
  }

  void startAtZero() {
    controller.text = _twoDigits(0);
  }

  void clear() {
    controller.clear();
  }

  /// Selects the whole draft so the next typed digit replaces it instead of
  /// being refused as a third digit.
  void selectAll() {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void dispose() {
    focusNode.dispose();
    controller.dispose();
  }

  void _selectAllWhenFocused() {
    if (focusNode.hasFocus) {
      selectAll();
    }
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

/// A time part's two-digit field with its up and down steppers beside it.
final class _TimePartField extends StatelessWidget {
  const _TimePartField({
    required this.draft,
    required this.label,
    required this.keyPrefix,
    required this.invalid,
    required this.onStep,
    required this.onSubmitted,
    this.autofocus = false,
  });

  /// Stacks two steppers of the minimum tap size beside one line of digits.
  static const EdgeInsets _digitPadding = EdgeInsets.symmetric(
    horizontal: ClockRhythmSpace.space4,
    vertical: ClockRhythmSpace.space24,
  );

  final _TimePartDraft draft;

  /// The part's visible name, such as "Hour".
  final String label;
  final String keyPrefix;

  /// Whether the draft's text is what makes the time unusable.
  final bool invalid;

  /// Steps the part up for a positive direction and down for a negative one.
  final ValueChanged<int> onStep;
  final VoidCallback onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final InputDecorationThemeData fields = theme.inputDecorationTheme;
    final TextStyle? digits = theme.textTheme.displayMedium?.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final ButtonStyle stepperStyle = IconButton.styleFrom(
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    onStep(1),
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    onStep(-1),
              },
              child: Semantics(
                label: copy.timePickerDirectInput(label),
                child: TextField(
                  key: ValueKey<String>(keyPrefix),
                  controller: draft.controller,
                  focusNode: draft.focusNode,
                  autofocus: autofocus,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  style: digits,
                  decoration: InputDecoration(
                    hintText: ClockTimeFormatter.unsetPart,
                    hintStyle: digits?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    contentPadding: _digitPadding,
                    enabledBorder: invalid ? fields.errorBorder : null,
                    focusedBorder: invalid ? fields.focusedErrorBorder : null,
                  ),
                  onTap: draft.selectAll,
                  onSubmitted: (String text) => onSubmitted(),
                ),
              ),
            ),
          ),
          const SizedBox(width: ClockRhythmSpace.space4),
          Column(
            children: <Widget>[
              Expanded(
                child: IconButton(
                  key: ValueKey<String>('$keyPrefix-increase'),
                  tooltip: copy.rhythmSettingsIncrease(label),
                  style: stepperStyle,
                  onPressed: () => onStep(1),
                  icon: const LineIcon(LineGlyph.chevronUp, size: 16),
                ),
              ),
              const SizedBox(height: ClockRhythmSpace.space4),
              Expanded(
                child: IconButton(
                  key: ValueKey<String>('$keyPrefix-decrease'),
                  tooltip: copy.rhythmSettingsDecrease(label),
                  style: stepperStyle,
                  onPressed: () => onStep(-1),
                  icon: const LineIcon(LineGlyph.chevronDown, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
