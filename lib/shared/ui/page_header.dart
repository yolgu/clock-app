import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A destination page with its heading.
///
/// Where the page has room for a toolbar it opens with a slim bar that names
/// the page as a breadcrumb (section / title) and stays put while the content
/// scrolls; a description then reads as the first block of content. Narrow
/// pages scroll a large title instead, with the description above it.
final class ClockRhythmPage extends StatelessWidget {
  const ClockRhythmPage({
    required this.section,
    required this.title,
    required this.builder,
    this.description,
    this.compactEyebrow,
    this.trailing,
    super.key,
  });

  /// The content width from which the page uses the toolbar heading.
  static const double toolbarMinimumWidth = ClockRhythmLayout.compactBreakpoint;

  static bool usesToolbar(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= toolbarMinimumWidth;
  }

  final String section;
  final String title;
  final String? description;

  /// The line above a narrow page's large title; defaults to the
  /// description, then the section.
  final String? compactEyebrow;
  final Widget? trailing;

  /// Builds the scrolling content. [lead] is the part of the heading that
  /// scrolls with the content and must come first.
  final Widget Function(BuildContext context, Widget lead) builder;

  @override
  Widget build(BuildContext context) {
    if (!usesToolbar(context)) {
      return builder(
        context,
        _LargeTitle(
          eyebrow: compactEyebrow ?? description ?? section,
          title: title,
          trailing: trailing,
        ),
      );
    }
    final String? intro = description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Toolbar(section: section, title: title, trailing: trailing),
        Expanded(
          child: builder(
            context,
            intro == null
                ? const SizedBox.shrink()
                : _Intro(title: title, description: intro),
          ),
        ),
      ],
    );
  }
}

final class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.section,
    required this.title,
    required this.trailing,
  });

  final String section;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted = theme.colorScheme.onSurfaceVariant;
    final TextStyle? crumb = theme.textTheme.bodyMedium?.copyWith(color: muted);
    final double horizontal = ClockRhythmLayout.horizontalInsetFor(
      MediaQuery.sizeOf(context).width,
    );
    return DecoratedBox(
      key: const ValueKey<String>('page-toolbar'),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: ClockRhythmSpace.space8,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  label: title,
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: section),
                        const TextSpan(text: '  /  '),
                        TextSpan(
                          text: title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    style: crumb,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (trailing case final Widget value) ...<Widget>[
                const SizedBox(width: ClockRhythmSpace.space12),
                value,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _Intro extends StatelessWidget {
  const _Intro({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: ClockRhythmSpace.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: ClockRhythmSpace.space4),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

final class _LargeTitle extends StatelessWidget {
  /// The largest body text size at which side content fits beside the title.
  static const double _sideBySideMaximumBody = 20;

  const _LargeTitle({
    required this.eyebrow,
    required this.title,
    required this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.headlineMedium),
        ),
      ],
    );
    final Widget? side = trailing;
    // Large text leaves no room beside the title, so the side content moves
    // underneath it instead of squeezing the heading into a narrow column.
    final bool stacked =
        MediaQuery.textScalerOf(context).scale(16) > _sideBySideMaximumBody;
    return Padding(
      padding: const EdgeInsets.only(bottom: ClockRhythmSpace.space16),
      child: switch (side) {
        null => heading,
        final Widget value when stacked => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            heading,
            const SizedBox(height: ClockRhythmSpace.space8),
            value,
          ],
        ),
        final Widget value => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: heading),
            const SizedBox(width: ClockRhythmSpace.space12),
            value,
          ],
        ),
      },
    );
  }
}

/// A quiet outlined pill naming a state, led by a colored dot.
final class ClockRhythmStatusChip extends StatelessWidget {
  const ClockRhythmStatusChip({
    required this.label,
    required this.tone,
    this.labelKey,
    super.key,
  });

  final String label;
  final Color tone;
  final Key? labelKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ClockRhythmRadius.pill),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClockRhythmSpace.space12,
          vertical: ClockRhythmSpace.space4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 6),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                key: labelKey,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
