import 'package:flutter/material.dart';

import '../../../../shared/i18n/public.dart';

final class DigitalClock extends StatelessWidget {
  const DigitalClock({required this.now, super.key});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final String time = _format(now);
    return Semantics(
      key: const ValueKey<String>('digital-clock-semantics'),
      label: AppLocalizations.of(context).accessibilityDigitalClockLabel(time),
      liveRegion: false,
      child: ExcludeSemantics(
        child: Text(
          time,
          key: const ValueKey<String>('digital-clock'),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  String _format(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    final String second = value.second.toString().padLeft(2, '0');
    return '$hour : $minute : $second';
  }
}
