import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/route_error.dart';
import 'app_navigation_copy.dart';

final class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({required this.error, required this.copy, super.key});

  final RouteError error;
  final AppNavigationCopy copy;

  @override
  Widget build(BuildContext context) {
    final String message = switch (error.kind) {
      RouteErrorKind.malformedCalendarDate => copy.malformedCalendarDateMessage,
      RouteErrorKind.unknownLocation => copy.unknownLocationMessage,
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  copy.routeErrorTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(message),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    context.go('/clock');
                  },
                  child: Text(copy.backToClockLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
