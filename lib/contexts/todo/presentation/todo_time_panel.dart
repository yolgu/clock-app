import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/i18n/public.dart' show AppLocalizations;
import '../../../shared/ui/public.dart'
    show ClockRhythmRadius, ClockRhythmSpace;

/// A Todo's 24-hour time, picked from every hour and five-minute step at
/// once, unfolded under the time field.
final class TodoTimePanel extends StatelessWidget {
  const TodoTimePanel({
    required this.hour,
    required this.minute,
    required this.onHourSelected,
    required this.onMinuteSelected,
    this.touchSized = false,
    this.enabled = true,
    super.key,
  });

  static const int minuteStep = 5;
  static const int _columns = 6;

  /// The chosen hour and minute; null until the Todo has a time.
  final int? hour;
  final int? minute;
  final ValueChanged<int> onHourSelected;
  final ValueChanged<int> onMinuteSelected;

  /// Uses the larger cells of a touch layout.
  final bool touchSized;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context);
    final double cellHeight = touchSized ? 44 : 36;
    return Semantics(
      container: true,
      label: localizations.todoTimePanelLabel,
      child: DecoratedBox(
        key: const ValueKey<String>('todo-time-panel'),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(ClockRhythmRadius.card),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ClockRhythmSpace.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TimeGroup(
                title: localizations.todoTimeHours,
                values: List<int>.generate(24, (int value) => value),
                selected: hour,
                cellHeight: cellHeight,
                keyPrefix: 'todo-hour',
                semanticLabel: localizations.todoTimeHourValue,
                onSelected: enabled ? onHourSelected : null,
              ),
              const SizedBox(height: ClockRhythmSpace.space12),
              _TimeGroup(
                title: localizations.todoTimeMinutes,
                values: List<int>.generate(
                  60 ~/ minuteStep,
                  (int index) => index * minuteStep,
                ),
                selected: minute,
                cellHeight: cellHeight,
                keyPrefix: 'todo-minute',
                semanticLabel: localizations.todoTimeMinuteValue,
                onSelected: enabled ? onMinuteSelected : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TimeGroup extends StatelessWidget {
  const _TimeGroup({
    required this.title,
    required this.values,
    required this.selected,
    required this.cellHeight,
    required this.keyPrefix,
    required this.semanticLabel,
    required this.onSelected,
  });

  final String title;
  final List<int> values;
  final int? selected;
  final double cellHeight;
  final String keyPrefix;
  final String Function(String value) semanticLabel;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(
      ClockRhythmRadius.control,
    );
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: TodoTimePanel._columns,
            crossAxisSpacing: ClockRhythmSpace.space4,
            mainAxisSpacing: ClockRhythmSpace.space4,
            mainAxisExtent: cellHeight * math.max(1, textScale),
          ),
          itemCount: values.length,
          itemBuilder: (BuildContext context, int index) {
            final int value = values[index];
            final String text = value.toString().padLeft(2, '0');
            final bool isSelected = value == selected;
            final ValueChanged<int>? select = onSelected;
            return Semantics(
              button: true,
              selected: isSelected,
              label: semanticLabel(text),
              excludeSemantics: true,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: ValueKey<String>('$keyPrefix-$text'),
                  onTap: select == null ? null : () => select(value),
                  borderRadius: radius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primaryContainer : null,
                      borderRadius: radius,
                      border: Border.all(
                        color: isSelected ? colors.primary : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
