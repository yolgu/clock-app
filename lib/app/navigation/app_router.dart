import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../platform_presentation_profile.dart';
import '../presentation/app_navigation_copy.dart';
import '../presentation/app_shell.dart';
import '../presentation/route_error_page.dart';
import 'app_routes.dart';
import 'route_error.dart';

typedef DestinationPageBuilder = Widget Function(BuildContext context);
typedef CalendarPageBuilder =
    Widget Function(BuildContext context, AppCalendarDate? selectedDate);
typedef AppNavigationCopyResolver =
    AppNavigationCopy Function(BuildContext context);

final class AppDestinationPages {
  const AppDestinationPages({
    required this.clock,
    required this.calendar,
    required this.data,
    required this.theme,
    required this.settings,
  });

  final DestinationPageBuilder clock;
  final CalendarPageBuilder calendar;
  final DestinationPageBuilder data;
  final DestinationPageBuilder theme;
  final DestinationPageBuilder settings;

  factory AppDestinationPages.placeholders(AppNavigationCopy copy) {
    return AppDestinationPages(
      clock: (_) => _DestinationPlaceholder(label: copy.clockLabel),
      calendar: (_, _) => _DestinationPlaceholder(label: copy.calendarLabel),
      data: (_) => _DestinationPlaceholder(label: copy.dataLabel),
      theme: (_) => _DestinationPlaceholder(label: copy.themeLabel),
      settings: (_) => _DestinationPlaceholder(label: copy.settingsLabel),
    );
  }

  factory AppDestinationPages.localizedPlaceholders() {
    return AppDestinationPages(
      clock: (BuildContext context) => _DestinationPlaceholder(
        label: AppNavigationCopy.fromContext(context).clockLabel,
      ),
      calendar: (BuildContext context, _) => _DestinationPlaceholder(
        label: AppNavigationCopy.fromContext(context).calendarLabel,
      ),
      data: (BuildContext context) => _DestinationPlaceholder(
        label: AppNavigationCopy.fromContext(context).dataLabel,
      ),
      theme: (BuildContext context) => _DestinationPlaceholder(
        label: AppNavigationCopy.fromContext(context).themeLabel,
      ),
      settings: (BuildContext context) => _DestinationPlaceholder(
        label: AppNavigationCopy.fromContext(context).settingsLabel,
      ),
    );
  }
}

final class ClockRhythmRouter {
  ClockRhythmRouter({
    required PlatformPresentationProfile profile,
    AppNavigationCopy? navigationCopy,
    AppDestinationPages? pages,
    String initialLocation = '/clock',
  }) {
    final AppNavigationCopyResolver resolveNavigationCopy =
        navigationCopy == null
        ? AppNavigationCopy.fromContext
        : (_) => navigationCopy;
    final AppDestinationPages destinationPages =
        pages ??
        (navigationCopy == null
            ? AppDestinationPages.localizedPlaceholders()
            : AppDestinationPages.placeholders(navigationCopy));
    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: initialLocation,
      restorationScopeId: 'clock_rhythm_router',
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          restorationScopeId: 'main_destinations',
          pageBuilder:
              (
                BuildContext context,
                GoRouterState state,
                StatefulNavigationShell navigationShell,
              ) {
                return MaterialPage<void>(
                  key: state.pageKey,
                  restorationId: 'main_destinations_page',
                  child: AppShell(
                    navigationShell: navigationShell,
                    profile: profile,
                    copy: resolveNavigationCopy(context),
                  ),
                );
              },
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              navigatorKey: _clockNavigatorKey,
              restorationScopeId: 'clock_branch',
              routes: <RouteBase>[
                GoRoute(
                  path: MainDestination.clock.location,
                  name: 'clock',
                  builder: (BuildContext context, GoRouterState state) {
                    return destinationPages.clock(context);
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _calendarNavigatorKey,
              restorationScopeId: 'calendar_branch',
              routes: <RouteBase>[
                GoRoute(
                  path: MainDestination.calendar.location,
                  name: 'calendar',
                  builder: (BuildContext context, GoRouterState state) {
                    final String? dateSource =
                        state.uri.queryParameters['date'];
                    if (dateSource == null) {
                      return destinationPages.calendar(context, null);
                    }
                    try {
                      return destinationPages.calendar(
                        context,
                        AppCalendarDate.parse(dateSource),
                      );
                    } on FormatException {
                      return RouteErrorPage(
                        error: RouteError.malformedCalendarDate(
                          state.uri.toString(),
                        ),
                        copy: resolveNavigationCopy(context),
                      );
                    }
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _dataNavigatorKey,
              restorationScopeId: 'data_branch',
              routes: <RouteBase>[
                GoRoute(
                  path: MainDestination.data.location,
                  name: 'data',
                  builder: (BuildContext context, GoRouterState state) {
                    return destinationPages.data(context);
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _themeNavigatorKey,
              restorationScopeId: 'theme_branch',
              routes: <RouteBase>[
                GoRoute(
                  path: MainDestination.theme.location,
                  name: 'theme',
                  builder: (BuildContext context, GoRouterState state) {
                    return destinationPages.theme(context);
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _settingsNavigatorKey,
              restorationScopeId: 'settings_branch',
              routes: <RouteBase>[
                GoRoute(
                  path: MainDestination.settings.location,
                  name: 'settings',
                  builder: (BuildContext context, GoRouterState state) {
                    return destinationPages.settings(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) {
        return RouteErrorPage(
          error: RouteError.unknownLocation(state.uri.toString()),
          copy: resolveNavigationCopy(context),
        );
      },
    );
  }

  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
  final GlobalKey<NavigatorState> _clockNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'clock');
  final GlobalKey<NavigatorState> _calendarNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'calendar');
  final GlobalKey<NavigatorState> _dataNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'data',
  );
  final GlobalKey<NavigatorState> _themeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'theme');
  final GlobalKey<NavigatorState> _settingsNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'settings');

  late final GoRouter router;

  void dispose() {
    router.dispose();
  }
}

final class _DestinationPlaceholder extends StatelessWidget {
  const _DestinationPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, key: ValueKey<String>('page-$label')));
  }
}
