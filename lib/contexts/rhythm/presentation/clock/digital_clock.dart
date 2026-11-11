import 'package:flutter/material.dart';

import '../../../../shared/i18n/public.dart';

/// The time in tabular figures. A compact clock leaves the seconds to a
/// caption beside it; screen readers always hear the full time.
final class DigitalClock extends StatelessWidget {
  const DigitalClock({
    required this.now,
    this.showsSeconds = true,
    this.fontSize = 52,
    super.key,
  });

  final DateTime now;
  final bool showsSeconds;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = _parts(now);
    final TextStyle? base = Theme.of(context).textTheme.displayMedium;
    final List<String> shown = showsSeconds ? parts : parts.sublist(0, 2);
    return Semantics(
      key: const ValueKey<String>('digital-clock-semantics'),
      label: AppLocalizations.of(
        context,
      ).accessibilityDigitalClockLabel(parts.join(' : ')),
      liveRegion: false,
      child: ExcludeSemantics(
        child: Text(
          shown.join(':'),
          key: const ValueKey<String>('digital-clock'),
          style: base?.copyWith(
            fontSize: fontSize,
            height: 1.1,
            fontWeight: FontWeight.w500,
            letterSpacing: -fontSize * 0.03,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  List<String> _parts(DateTime value) {
    return <int>[
      value.hour,
      value.minute,
      value.second,
    ].map((int part) => part.toString().padLeft(2, '0')).toList();
  }
}
