import 'package:flutter/widgets.dart';

import '../../shared/i18n/public.dart' show AppLocalizations;
import '../navigation/app_routes.dart';

final class AppNavigationCopy {
  const AppNavigationCopy({
    required this.clockLabel,
    required this.navigationSemanticsLabel,
    required this.calendarLabel,
    required this.dataLabel,
    required this.themeLabel,
    required this.routeErrorTitle,
    required this.malformedCalendarDateMessage,
    required this.unknownLocationMessage,
    required this.backToClockLabel,
  });

  final String clockLabel;
  final String navigationSemanticsLabel;
  final String calendarLabel;
  final String dataLabel;
  final String themeLabel;
  final String routeErrorTitle;
  final String malformedCalendarDateMessage;
  final String unknownLocationMessage;
  final String backToClockLabel;

  factory AppNavigationCopy.fromContext(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    return AppNavigationCopy(
      clockLabel: localizations.navigationClock,
      navigationSemanticsLabel: localizations.navigationSemanticsLabel,
      calendarLabel: localizations.navigationCalendar,
      dataLabel: localizations.navigationData,
      themeLabel: localizations.navigationTheme,
      routeErrorTitle: localizations.routeErrorTitle,
      malformedCalendarDateMessage:
          localizations.failureRouteInvalidCalendarDate,
      unknownLocationMessage: localizations.failureRouteNotFound,
      backToClockLabel: localizations.routeBackToClock,
    );
  }

  String labelFor(MainDestination destination) {
    return switch (destination) {
      MainDestination.clock => clockLabel,
      MainDestination.calendar => calendarLabel,
      MainDestination.data => dataLabel,
      MainDestination.theme => themeLabel,
    };
  }
}
