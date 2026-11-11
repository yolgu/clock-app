import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/ui/public.dart' show ClockRhythmLayout;
import '../navigation/app_routes.dart';
import '../platform_presentation_profile.dart';
import 'app_navigation_copy.dart';
import 'app_shortcuts.dart';
import 'bottom_tab_navigation.dart';
import 'side_navigation.dart';

/// Chooses the navigation by the room the window actually has: a sidebar
/// beside the page when it is wide, a bottom tab bar when it is narrow, on
/// every platform alike.
final class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.profile,
    required this.copy,
    this.releaseLabel,
    this.sidebarSummary,
    super.key,
  });

  /// The widest text scale at which the sidebar labels still fit.
  static const double _maximumSidebarLabelSize = 21;

  final StatefulNavigationShell navigationShell;
  final PlatformPresentationProfile profile;
  final AppNavigationCopy copy;
  final String? releaseLabel;
  final Widget? sidebarSummary;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final bool usesSidebar =
        media.size.width >= ClockRhythmLayout.wideBreakpoint &&
        media.textScaler.scale(14) <= _maximumSidebarLabelSize;
    final Widget scaffold = usesSidebar
        ? Scaffold(
            body: Row(
              children: <Widget>[
                SideNavigation(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _selectDestination,
                  copy: copy,
                  shortcutModifierLabel: _shortcutModifierLabel,
                  releaseLabel: releaseLabel,
                  summary: sidebarSummary,
                ),
                Expanded(
                  // Pages size their insets and columns from MediaQuery, so
                  // the region beside the sidebar is their viewport.
                  child: MediaQuery(
                    data: media.copyWith(
                      size: Size(
                        media.size.width - SideNavigation.width,
                        media.size.height,
                      ),
                    ),
                    child: navigationShell,
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomTabNavigation(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _selectDestination,
              copy: copy,
            ),
          );

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

  /// Ctrl+1 through Ctrl+5 select the destinations; the hint is shown only
  /// where a hardware keyboard is the norm.
  String? get _shortcutModifierLabel {
    return switch (profile) {
      PlatformPresentationProfile.windows => 'Ctrl+',
      PlatformPresentationProfile.macos => '⌃',
      PlatformPresentationProfile.android => null,
    };
  }

  void _selectDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
