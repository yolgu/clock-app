import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_routes.dart';
import 'app_navigation_copy.dart';

final class WindowsTopNavigation extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: copy.navigationSemanticsLabel,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                child: SegmentedButton<MainDestination>(
                  showSelectedIcon: false,
                  segments: MainDestination.values
                      .map(
                        (MainDestination destination) =>
                            ButtonSegment<MainDestination>(
                              value: destination,
                              label: Text(copy.labelFor(destination)),
                            ),
                      )
                      .toList(growable: false),
                  selected: <MainDestination>{
                    MainDestination.values[selectedIndex],
                  },
                  onSelectionChanged: (Set<MainDestination> selection) {
                    onDestinationSelected(selection.single.index);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _moveSelection(int offset) {
    final int target = (selectedIndex + offset).clamp(
      0,
      MainDestination.values.length - 1,
    );
    if (target != selectedIndex) {
      onDestinationSelected(target);
    }
  }
}
