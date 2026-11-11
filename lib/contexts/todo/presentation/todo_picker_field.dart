import 'package:flutter/material.dart';

import '../../../shared/ui/public.dart'
    show ClockRhythmRadius, ClockRhythmSpace, LineGlyph, LineIcon;

/// A form field whose value comes from a picker. It is drawn like a text
/// field so a form reads as one set of fields, shows the chosen value or a
/// muted prompt, and opens its picker when pressed.
final class TodoPickerField extends StatefulWidget {
  const TodoPickerField({
    required this.semanticLabel,
    required this.value,
    required this.placeholder,
    required this.onPressed,
    this.expanded = false,
    this.clearAction,
    super.key,
  });

  /// What a screen reader announces: the field's purpose and current value.
  final String semanticLabel;
  final String? value;
  final String placeholder;
  final VoidCallback? onPressed;

  /// Whether the field's picker is unfolded beneath it. An open field keeps
  /// the accent ring so the panel reads as belonging to it.
  final bool expanded;

  /// Replaces the picker cue at the end of the field while a value can be
  /// cleared. It stays a separate target from the field itself.
  final Widget? clearAction;

  @override
  State<TodoPickerField> createState() => _TodoPickerFieldState();
}

final class _TodoPickerFieldState extends State<TodoPickerField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final InputDecorationThemeData fields = theme.inputDecorationTheme;
    final BorderRadius radius = BorderRadius.circular(
      ClockRhythmRadius.control,
    );
    final String? value = widget.value;
    final TextStyle? valueStyle = theme.textTheme.bodyLarge?.copyWith(
      color: value == null ? colors.onSurfaceVariant : colors.onSurface,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final Widget? clearAction = widget.clearAction;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fields.fillColor,
        borderRadius: radius,
        border: Border.all(color: colors.outlineVariant),
      ),
      position: DecorationPosition.background,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: _focused || widget.expanded
              ? Border.all(color: theme.focusColor, width: 2)
              : null,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                button: true,
                expanded: widget.expanded,
                enabled: widget.onPressed != null,
                label: widget.semanticLabel,
                excludeSemantics: true,
                child: InkWell(
                  onTap: widget.onPressed,
                  onFocusChange: (bool focused) {
                    setState(() {
                      _focused = focused;
                    });
                  },
                  borderRadius: radius,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: ClockRhythmSpace.space16,
                      end: ClockRhythmSpace.space12,
                      top: ClockRhythmSpace.space12,
                      bottom: ClockRhythmSpace.space12,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          // Large text wraps rather than cutting off the
                          // value the field exists to show.
                          child: Text(
                            value ?? widget.placeholder,
                            style: valueStyle,
                          ),
                        ),
                        if (clearAction == null)
                          LineIcon(
                            widget.expanded
                                ? LineGlyph.chevronUp
                                : LineGlyph.chevronDown,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ?clearAction,
          ],
        ),
      ),
    );
  }
}
