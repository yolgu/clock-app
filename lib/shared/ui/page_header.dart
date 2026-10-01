import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Apple-style page heading: an optional small eyebrow, a bold Large Title
/// and an optional secondary description.
final class ClockRhythmPageHeader extends StatelessWidget {
  const ClockRhythmPageHeader({
    required this.title,
    this.eyebrow,
    this.description,
    this.trailing,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final Widget heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (eyebrow case final String value)
          Text(
            value,
            style: textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Semantics(
          header: true,
          child: Text(title, style: textTheme.headlineLarge),
        ),
        if (description case final String value)
          Padding(
            padding: const EdgeInsets.only(top: ClockRhythmSpace.space4),
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: ClockRhythmSpace.space20),
      child: trailing == null
          ? heading
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: heading),
                const SizedBox(width: ClockRhythmSpace.space12),
                trailing!,
              ],
            ),
    );
  }
}
