import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/ui/public.dart'
    show
        ClockRhythmLayout,
        ClockRhythmMotion,
        ClockRhythmRadius,
        ClockRhythmSpace;
import '../navigation/app_routes.dart';
import 'app_navigation_copy.dart';
import 'destination_icons.dart';

/// A macOS-style toolbar: one centered segmented control whose selected
/// segment is a raised capsule inside a quiet track.
final class WindowsTopNavigation extends StatefulWidget {
  const WindowsTopNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.copy,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppNavigationCopy copy;

  @override
  State<WindowsTopNavigation> createState() => _WindowsTopNavigationState();
}

final class _WindowsTopNavigationState extends State<WindowsTopNavigation> {
  late final List<FocusNode> _destinationFocusNodes = MainDestination.values
      .map(
        (MainDestination destination) => FocusNode(
          debugLabel:
              'Windows destination: ${widget.copy.labelFor(destination)}',
        ),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool showsIcons =
        MediaQuery.textScalerOf(context).scale(14) <= 18 &&
        MediaQuery.sizeOf(context).width >= 760;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.copy.navigationSemanticsLabel,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          bottom: false,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: SizedBox(
              height: ClockRhythmLayout.windowsNavigationHeight,
              child: Center(
                child: CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                      _moveSelection(-1);
                    },
                    const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                      _moveSelection(1);
                    },
                    const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                      _moveSelection(-1);
                    },
                    const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                      _moveSelection(1);
                    },
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClockRhythmSpace.space16,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          ClockRhythmRadius.pill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: MainDestination.values
                            .map(
                              (
                                MainDestination destination,
                              ) => _WindowsDestinationTab(
                                key: ValueKey<String>(
                                  'windows-destination-${destination.name}',
                                ),
                                label: widget.copy.labelFor(destination),
                                icon: showsIcons
                                    ? DestinationIcons.of(
                                        destination,
                                        selected:
                                            widget.selectedIndex ==
                                            destination.index,
                                      )
                                    : null,
                                selected:
                                    widget.selectedIndex == destination.index,
                                focusNode:
                                    _destinationFocusNodes[destination.index],
                                onPressed: () {
                                  widget.onDestinationSelected(
                                    destination.index,
                                  );
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
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

final class _WindowsDestinationTab extends StatefulWidget {
  const _WindowsDestinationTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.focusNode,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  State<_WindowsDestinationTab> createState() => _WindowsDestinationTabState();
}

final class _WindowsDestinationTabState extends State<_WindowsDestinationTab> {
  late bool _focused = widget.focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(_WindowsDestinationTab oldWidget) {
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
    final Duration transitionDuration = ClockRhythmMotion.accessibleDuration(
      context,
      ClockRhythmMotion.standard,
    );
    final Color labelColor = widget.selected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
    final BorderRadius capsule = BorderRadius.circular(ClockRhythmRadius.pill);
    final IconData? icon = widget.icon;

    return MergeSemantics(
      child: Semantics(
        selected: widget.selected,
        child: TextButton(
          focusNode: widget.focusNode,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll<Size>(
              Size.square(ClockRhythmLayout.minimumInteractiveDimension),
            ),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.zero,
            ),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(borderRadius: capsule),
            ),
            overlayColor: const WidgetStatePropertyAll<Color>(
              Colors.transparent,
            ),
            foregroundColor: WidgetStatePropertyAll<Color>(labelColor),
            animationDuration: transitionDuration,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: widget.onPressed,
          child: AnimatedContainer(
            duration: transitionDuration,
            curve: ClockRhythmMotion.emphasized,
            margin: const EdgeInsets.all(ClockRhythmSpace.space4),
            constraints: const BoxConstraints(
              minWidth: ClockRhythmLayout.minimumInteractiveDimension - 8,
              minHeight: ClockRhythmLayout.minimumInteractiveDimension - 8,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ClockRhythmSpace.space16,
            ),
            decoration: BoxDecoration(
              color: widget.selected
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.transparent,
              borderRadius: capsule,
              boxShadow: widget.selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            foregroundDecoration: BoxDecoration(
              border: _focused
                  ? Border.all(color: theme.focusColor, width: 2)
                  : null,
              borderRadius: capsule,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 18, color: labelColor),
                  const SizedBox(width: ClockRhythmSpace.space8),
                ],
                AnimatedDefaultTextStyle(
                  duration: transitionDuration,
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: labelColor,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                  child: Text(widget.label),
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
