import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/ui/public.dart'
    show
        ClockRhythmLayout,
        ClockRhythmMotion,
        ClockRhythmRadius,
        ClockRhythmSpace,
        LineGlyph,
        LineIcon;
import '../navigation/app_routes.dart';
import 'app_navigation_copy.dart';
import 'destination_icons.dart';

/// The wide-layout navigation: a quiet sidebar listing the five destinations
/// with their keyboard shortcuts, next to the page content.
final class SideNavigation extends StatefulWidget {
  const SideNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.copy,
    required this.shortcutModifierLabel,
    this.releaseLabel,
    this.summary,
    super.key,
  });

  static const double width = 232;

  /// A pre-release channel name shown beside the app name, such as Beta.
  final String? releaseLabel;

  /// A glanceable panel under the destinations, such as today's summary.
  final Widget? summary;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppNavigationCopy copy;

  /// The modifier shown before each destination number, such as `Ctrl+` on
  /// Windows or `⌃` on macOS; null hides the hints where no keyboard is
  /// expected.
  final String? shortcutModifierLabel;

  @override
  State<SideNavigation> createState() => _SideNavigationState();
}

final class _SideNavigationState extends State<SideNavigation> {
  late final List<FocusNode> _destinationFocusNodes = MainDestination.values
      .map(
        (MainDestination destination) => FocusNode(
          debugLabel: 'Side destination: ${widget.copy.labelFor(destination)}',
        ),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String? modifier = widget.shortcutModifierLabel;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.copy.navigationSemanticsLabel,
      child: Material(
        color: Color.lerp(theme.scaffoldBackgroundColor, colors.surface, 0.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: SafeArea(
            right: false,
            child: SizedBox(
              width: SideNavigation.width,
              child: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                    _moveSelection(-1);
                  },
                  const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                    _moveSelection(1);
                  },
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClockRhythmSpace.space12,
                    vertical: ClockRhythmSpace.space16,
                  ),
                  children: <Widget>[
                    _AppIdentity(
                      name: widget.copy.appTitle,
                      releaseLabel: widget.releaseLabel,
                    ),
                    const SizedBox(height: ClockRhythmSpace.space20),
                    for (final MainDestination destination
                        in MainDestination.values)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: ClockRhythmSpace.space4 / 2,
                        ),
                        child: _SideDestination(
                          key: ValueKey<String>(
                            'side-destination-${destination.name}',
                          ),
                          label: widget.copy.labelFor(destination),
                          icon: DestinationIcons.of(destination),
                          shortcutHint: modifier == null
                              ? null
                              : '$modifier${destination.index + 1}',
                          selected: widget.selectedIndex == destination.index,
                          focusNode: _destinationFocusNodes[destination.index],
                          onPressed: () {
                            widget.onDestinationSelected(destination.index);
                          },
                        ),
                      ),
                    if (widget.summary case final Widget summary) ...<Widget>[
                      const SizedBox(height: ClockRhythmSpace.space20),
                      summary,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _moveSelection(int offset) {
    final int target = (widget.selectedIndex + offset).clamp(
      0,
      MainDestination.values.length - 1,
    );
    if (target != widget.selectedIndex) {
      widget.onDestinationSelected(target);
      _destinationFocusNodes[target].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final FocusNode focusNode in _destinationFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}

final class _AppIdentity extends StatelessWidget {
  const _AppIdentity({required this.name, required this.releaseLabel});

  final String name;
  final String? releaseLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClockRhythmSpace.space8,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(7),
              ),
              child: LineIcon(
                LineGlyph.clock,
                size: 17,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: ClockRhythmSpace.space8 + 2),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (releaseLabel case final String label)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(ClockRhythmRadius.small),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  child: Text(label, style: theme.textTheme.labelSmall),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _SideDestination extends StatefulWidget {
  const _SideDestination({
    required this.label,
    required this.icon,
    required this.shortcutHint,
    required this.selected,
    required this.focusNode,
    required this.onPressed,
    super.key,
  });

  final String label;
  final LineGlyph icon;
  final String? shortcutHint;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  State<_SideDestination> createState() => _SideDestinationState();
}

final class _SideDestinationState extends State<_SideDestination> {
  late bool _focused = widget.focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(_SideDestination oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      _focused = widget.focusNode.hasFocus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Duration transitionDuration = ClockRhythmMotion.accessibleDuration(
      context,
      ClockRhythmMotion.fast,
    );
    final Color labelColor = widget.selected
        ? colors.onSurface
        : colors.onSurfaceVariant;
    final BorderRadius shape = BorderRadius.circular(ClockRhythmRadius.small);
    final String? shortcutHint = widget.shortcutHint;

    return MergeSemantics(
      child: Semantics(
        selected: widget.selected,
        child: TextButton(
          focusNode: widget.focusNode,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll<Size>(
              Size.fromHeight(ClockRhythmLayout.minimumInteractiveDimension),
            ),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.zero,
            ),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(borderRadius: shape),
            ),
            backgroundColor: WidgetStatePropertyAll<Color>(
              widget.selected
                  ? colors.surfaceContainerHigh
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStatePropertyAll<Color>(labelColor),
            animationDuration: transitionDuration,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: widget.onPressed,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: ClockRhythmLayout.minimumInteractiveDimension,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ClockRhythmSpace.space12,
            ),
            foregroundDecoration: BoxDecoration(
              border: _focused
                  ? Border.all(color: theme.focusColor, width: 2)
                  : null,
              borderRadius: shape,
            ),
            child: Row(
              children: <Widget>[
                LineIcon(widget.icon, size: 18, color: labelColor),
                const SizedBox(width: ClockRhythmSpace.space8 + 2),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: labelColor,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (shortcutHint != null)
                  ExcludeSemantics(
                    child: Text(
                      shortcutHint,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFocusChange() {
    final bool focused = widget.focusNode.hasFocus;
    if (_focused != focused) {
      setState(() {
        _focused = focused;
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }
}
