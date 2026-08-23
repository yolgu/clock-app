import 'package:flutter/material.dart';

import 'app_navigation_copy.dart';

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
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.schedule_outlined),
            selectedIcon: const Icon(Icons.schedule),
            label: copy.clockLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: copy.calendarLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storage_outlined),
            selectedIcon: const Icon(Icons.storage),
            label: copy.dataLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.palette_outlined),
            selectedIcon: const Icon(Icons.palette),
            label: copy.themeLabel,
          ),
        ],
      ),
    );
  }
}
