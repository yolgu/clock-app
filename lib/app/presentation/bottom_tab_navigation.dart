import 'package:flutter/material.dart';

import '../../shared/ui/public.dart' show LineIcon;
import '../navigation/app_routes.dart';
import 'app_navigation_copy.dart';
import 'destination_icons.dart';

/// The compact-layout navigation on every platform: a tab bar with a hairline
/// top edge whose selected glyph sits in a tinted pill.
final class BottomTabNavigation extends StatelessWidget {
  const BottomTabNavigation({
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
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: MainDestination.values
              .map(
                (MainDestination destination) => NavigationDestination(
                  icon: LineIcon(DestinationIcons.of(destination)),
                  label: copy.labelFor(destination),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
