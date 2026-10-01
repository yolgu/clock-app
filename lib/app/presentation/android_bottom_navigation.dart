import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import 'app_navigation_copy.dart';
import 'destination_icons.dart';

/// An iOS-style tab bar: hairline top edge, tinted glyphs, no indicator.
final class AndroidBottomNavigation extends StatelessWidget {
  const AndroidBottomNavigation({
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: MainDestination.values
              .map(
                (MainDestination destination) => NavigationDestination(
                  icon: Icon(DestinationIcons.of(destination, selected: false)),
                  selectedIcon: Icon(
                    DestinationIcons.of(destination, selected: true),
                  ),
                  label: copy.labelFor(destination),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
