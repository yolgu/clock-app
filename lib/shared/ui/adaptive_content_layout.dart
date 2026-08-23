import 'package:flutter/widgets.dart';

enum AdaptiveContentMode { compact, wide }

typedef AdaptiveContentBuilder =
    Widget Function(BuildContext context, AdaptiveContentMode mode);

final class AdaptiveContentLayout extends StatelessWidget {
  const AdaptiveContentLayout({
    required this.builder,
    this.wideMinimumWidth = 920,
    this.maximumWideBodyTextSize = 24,
    super.key,
  });

  final AdaptiveContentBuilder builder;
  final double wideMinimumWidth;
  final double maximumWideBodyTextSize;

  static AdaptiveContentMode resolve({
    required BoxConstraints constraints,
    required TextScaler textScaler,
    required double wideMinimumWidth,
    required double maximumWideBodyTextSize,
  }) {
    final double scaledBodyText = textScaler.scale(16);
    return constraints.maxWidth >= wideMinimumWidth &&
            scaledBodyText <= maximumWideBodyTextSize
        ? AdaptiveContentMode.wide
        : AdaptiveContentMode.compact;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return builder(
          context,
          resolve(
            constraints: constraints,
            textScaler: MediaQuery.textScalerOf(context),
            wideMinimumWidth: wideMinimumWidth,
            maximumWideBodyTextSize: maximumWideBodyTextSize,
          ),
        );
      },
    );
  }
}
