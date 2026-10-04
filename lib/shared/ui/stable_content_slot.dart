import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Reserves the largest localized label without mounting hidden semantics.
final class StableContentSlot extends StatelessWidget {
  const StableContentSlot({
    required this.labels,
    required this.child,
    this.style,
    this.alignment = AlignmentDirectional.centerStart,
    super.key,
  });

  final List<String> labels;
  final Widget child;
  final TextStyle? style;
  final AlignmentGeometry alignment;

  static Size measureLabels(
    BuildContext context, {
    required Iterable<String> labels,
    required TextStyle style,
    double maxWidth = double.infinity,
  }) {
    return _LabelMetrics.fromContext(context, labels, style).measure(maxWidth);
  }

  @override
  Widget build(BuildContext context) {
    return _StableLabelBounds(
      metrics: _LabelMetrics.fromContext(
        context,
        labels,
        DefaultTextStyle.of(context).style.merge(style),
      ),
      child: Align(
        alignment: alignment,
        widthFactor: 1,
        heightFactor: 1,
        child: child,
      ),
    );
  }
}

final class _LabelMetrics {
  const _LabelMetrics({
    required this.labels,
    required this.style,
    required this.direction,
    required this.scaler,
    required this.locale,
  });

  factory _LabelMetrics.fromContext(
    BuildContext context,
    Iterable<String> labels,
    TextStyle style,
  ) {
    return _LabelMetrics(
      labels: List<String>.of(labels),
      style: style,
      direction: Directionality.of(context),
      scaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    );
  }

  final List<String> labels;
  final TextStyle style;
  final TextDirection direction;
  final TextScaler scaler;
  final Locale? locale;

  TextPainter _painter(String label, double width) {
    return TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: direction,
      textScaler: scaler,
      locale: locale,
    )..layout(maxWidth: width);
  }

  Size measure(double maxWidth) {
    double width = 0;
    double height = 0;
    for (final String label in labels) {
      final TextPainter painter = _painter(label, maxWidth);
      width = math.max(width, painter.width);
      height = math.max(height, painter.height);
      painter.dispose();
    }
    return Size(
      math.min(width.ceilToDouble(), maxWidth),
      height.ceilToDouble(),
    );
  }

  double get minimumIntrinsicWidth {
    double width = 0;
    for (final String label in labels) {
      final TextPainter painter = _painter(label, double.infinity);
      width = math.max(width, painter.minIntrinsicWidth);
      painter.dispose();
    }
    return width.ceilToDouble();
  }
}

final class _StableLabelBounds extends SingleChildRenderObjectWidget {
  const _StableLabelBounds({required this.metrics, required super.child});
  final _LabelMetrics metrics;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStableLabelBounds(metrics);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderStableLabelBounds renderObject,
  ) {
    renderObject.metrics = metrics;
  }
}

final class _RenderStableLabelBounds extends RenderProxyBox {
  _RenderStableLabelBounds(this._metrics);
  _LabelMetrics _metrics;

  set metrics(_LabelMetrics value) {
    _metrics = value;
    markNeedsLayout();
  }

  BoxConstraints _childConstraints(BoxConstraints available) {
    final Size reserved = _metrics.measure(available.maxWidth);
    return available.copyWith(
      minWidth: math
          .max(available.minWidth, reserved.width)
          .clamp(0, available.maxWidth),
      minHeight: math
          .max(available.minHeight, reserved.height)
          .clamp(0, available.maxHeight),
    );
  }

  @override
  void performLayout() {
    final BoxConstraints reserved = _childConstraints(constraints);
    child?.layout(reserved, parentUsesSize: true);
    size = constraints.constrain(child?.size ?? reserved.smallest);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final BoxConstraints reserved = _childConstraints(constraints);
    return constraints.constrain(
      child?.getDryLayout(reserved) ?? reserved.smallest,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _metrics.minimumIntrinsicWidth,
    super.computeMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    _metrics.measure(double.infinity).width,
    super.computeMaxIntrinsicWidth(height),
  );

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    _metrics.measure(width).height,
    super.computeMinIntrinsicHeight(width),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    _metrics.measure(width).height,
    super.computeMaxIntrinsicHeight(width),
  );
}
