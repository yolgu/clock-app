import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';
import '../platform_presentation_profile.dart';
import 'android_bottom_navigation.dart';
import 'app_navigation_copy.dart';
import 'app_shortcuts.dart';
import 'windows_top_navigation.dart';

final class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.profile,
    required this.copy,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final PlatformPresentationProfile profile;
  final AppNavigationCopy copy;

  @override
  Widget build(BuildContext context) {
    final Widget scaffold = switch (profile) {
      PlatformPresentationProfile.windows ||
      PlatformPresentationProfile.macos => Scaffold(
        body: Column(
          children: <Widget>[
            WindowsTopNavigation(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _selectDestination,
              copy: copy,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      PlatformPresentationProfile.android => Scaffold(
        body: navigationShell,
        bottomNavigationBar: AndroidBottomNavigation(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _selectDestination,
          copy: copy,
        ),
      ),
    };

    return PopScope<Object?>(
      canPop: navigationShell.currentIndex == MainDestination.clock.index,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop &&
            navigationShell.currentIndex != MainDestination.clock.index) {
          navigationShell.goBranch(MainDestination.clock.index);
        }
      },
      child: AppShortcuts(
        onDestinationSelected: _selectDestination,
        child: scaffold,
      ),
    );
  }

  void _selectDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
