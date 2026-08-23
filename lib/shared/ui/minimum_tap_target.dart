import 'package:flutter/widgets.dart';

final class MinimumTapTarget extends StatelessWidget {
  const MinimumTapTarget({
    required this.child,
    this.minimumSize = 48,
    super.key,
  });

  final Widget child;
  final double minimumSize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minimumSize,
        minHeight: minimumSize,
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}
