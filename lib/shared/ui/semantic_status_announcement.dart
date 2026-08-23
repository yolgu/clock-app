import 'package:flutter/widgets.dart';

final class SemanticStatusAnnouncement extends StatelessWidget {
  const SemanticStatusAnnouncement({
    required this.message,
    required this.child,
    super.key,
  });

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      excludeSemantics: true,
      child: child,
    );
  }
}
