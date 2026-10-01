import 'package:flutter/material.dart';

import '../../../../shared/i18n/public.dart';

final class DigitalClock extends StatelessWidget {
  const DigitalClock({required this.now, super.key});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = _parts(now);
    final TextStyle? base = Theme.of(context).textTheme.displayMedium;
    return Semantics(
      key: const ValueKey<String>('digital-clock-semantics'),
      label: AppLocalizations.of(
        context,
      ).accessibilityDigitalClockLabel(parts.join(' : ')),
      liveRegion: false,
      child: ExcludeSemantics(
        child: Text(
          parts.join(':'),
          key: const ValueKey<String>('digital-clock'),
          style: base?.copyWith(
            fontSize: 52,
            height: 60 / 52,
            fontWeight: FontWeight.w200,
            letterSpacing: -1,
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
