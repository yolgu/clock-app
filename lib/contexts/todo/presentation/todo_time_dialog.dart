import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/i18n/public.dart'
    show AppLocalizations, ClockTimeFormatter, ClockTimeParts;
import '../../../shared/ui/public.dart'
    show ClockRhythmSpace, LineGlyph, LineIcon;
import 'todo_time_panel.dart';

/// Asks for a Todo's 24-hour time in a dialog. Completes with null when the
/// dialog is dismissed without confirming.
Future<ClockTimeParts?> showTodoTimeDialog({
  required BuildContext context,
  required ClockTimeParts initialTime,
}) {
  return showDialog<ClockTimeParts>(
    context: context,
    builder: (BuildContext context) => TodoTimeDialog(initialTime: initialTime),
  );
}

/// A Todo's 24-hour time as an hour and a minute that can each be typed or
/// stepped with the buttons beside it.
final class TodoTimeDialog extends StatefulWidget {
  const TodoTimeDialog({required this.initialTime, super.key});

  final ClockTimeParts initialTime;

  @override
  State<TodoTimeDialog> createState() => _TodoTimeDialogState();
}

final class _TodoTimeDialogState extends State<TodoTimeDialog> {
  /// Fits both parts with their steppers on one line.
  static const double _maximumWidth = 368;

  late final _TimePartDraft _hour = _TimePartDraft(
    initialValue: widget.initialTime.hour,
    cycleLength: TimeOfDay.hoursPerDay,
    step: 1,
  );
  late final _TimePartDraft _minute = _TimePartDraft(
    initialValue: widget.initialTime.minute,
    cycleLength: TimeOfDay.minutesPerHour,
    step: TodoTimePanel.minuteStep,
  );

  /// The time both drafts spell, or null while either is out of range.
  ClockTimeParts? get _enteredTime {
    final int? hour = _hour.value;
    final int? minute = _minute.value;
    return hour == null || minute == null ? null : (hour: hour, minute: minute);
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  void _confirm() {
    final ClockTimeParts? time = _enteredTime;
    if (time != null) {
      Navigator.of(context).pop(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    return Dialog(
      constraints: const BoxConstraints(maxWidth: _maximumWidth),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ClockRhythmSpace.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                copy.todoListEditTime,
                style: theme.dialogTheme.titleTextStyle,
              ),
            ),
            const SizedBox(height: ClockRhythmSpace.space16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TimePartField(
                    draft: _hour,
                    label: copy.todoTimeHours,
                    keyPrefix: 'todo-time-hour',
                    autofocus: true,
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
                    draft: _minute,
                    label: copy.todoTimeMinutes,
                    keyPrefix: 'todo-time-minute',
                    onSubmitted: _confirm,
                  ),
                ),
              ],
            ),
            ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[
                _hour.controller,
                _minute.controller,
              ]),
              builder: (BuildContext context, Widget? child) {
                final bool canConfirm = _enteredTime != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (!canConfirm)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: ClockRhythmSpace.space8,
                        ),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            copy.timePickerInvalid,
                            key: const ValueKey<String>('todo-time-invalid'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: ClockRhythmSpace.space20),
                    // Enlarged text moves the commands onto separate lines
                    // instead of pushing them past the dialog's edge.
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: ClockRhythmSpace.space8,
                      runSpacing: ClockRhythmSpace.space8,
                      children: <Widget>[
                        TextButton(
                          key: const ValueKey<String>('todo-time-cancel'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(copy.actionCancel),
                        ),
                        FilledButton(
                          key: const ValueKey<String>('todo-time-confirm'),
                          onPressed: canConfirm ? _confirm : null,
                          child: Text(copy.actionConfirm),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// One editable part of a clock time, the hour or the minute. Its text is
/// the user's draft; [value] is that draft once it names a real value.
final class _TimePartDraft {
  _TimePartDraft({
    required int initialValue,
    required this.cycleLength,
    required this.step,
  }) : controller = TextEditingController(text: _twoDigits(initialValue)) {
    focusNode.addListener(_selectAllWhenFocused);
  }

  /// How many values the part has before it wraps: 24 hours or 60 minutes.
  final int cycleLength;

  /// The distance between the values the stepper stops at.
  final int step;

  final TextEditingController controller;
  final FocusNode focusNode = FocusNode();

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
  final VoidCallback onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final InputDecorationThemeData fields = theme.inputDecorationTheme;
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
                    draft.stepBy(1),
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    draft.stepBy(-1),
              },
              child: Semantics(
                label: copy.timePickerDirectInput(label),
                child: ListenableBuilder(
                  listenable: draft.controller,
                  builder: (BuildContext context, Widget? child) {
                    final bool invalid = draft.value == null;
                    return TextField(
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
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                      decoration: InputDecoration(
                        contentPadding: _digitPadding,
                        enabledBorder: invalid ? fields.errorBorder : null,
                        focusedBorder: invalid
                            ? fields.focusedErrorBorder
                            : null,
                      ),
                      onTap: draft.selectAll,
                      onSubmitted: (String text) => onSubmitted(),
                    );
                  },
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
                  onPressed: () => draft.stepBy(1),
                  icon: const LineIcon(LineGlyph.chevronUp, size: 16),
                ),
              ),
              const SizedBox(height: ClockRhythmSpace.space4),
              Expanded(
                child: IconButton(
                  key: ValueKey<String>('$keyPrefix-decrease'),
                  tooltip: copy.rhythmSettingsDecrease(label),
                  style: stepperStyle,
                  onPressed: () => draft.stepBy(-1),
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
