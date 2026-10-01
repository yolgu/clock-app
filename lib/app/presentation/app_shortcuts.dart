import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../navigation/app_routes.dart';

final class AppShortcuts extends StatelessWidget {
  const AppShortcuts({
    required this.onDestinationSelected,
    required this.child,
    super.key,
  });

  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () {
          onDestinationSelected(MainDestination.clock.index);
        },
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () {
          onDestinationSelected(MainDestination.calendar.index);
        },
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () {
          onDestinationSelected(MainDestination.data.index);
        },
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () {
          onDestinationSelected(MainDestination.theme.index);
        },
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () {
          onDestinationSelected(MainDestination.settings.index);
        },
      },
      // Shortcuts only see key events from focused descendants, so anchor
      // focus here; Ctrl+1-5 then work right after launch.
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        debugLabel: 'App shortcuts',
        child: child,
      ),
    );
  }
}
