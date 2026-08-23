import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/i18n/public.dart';

final class DurationField extends StatelessWidget {
  const DurationField({
    required this.label,
    required this.controller,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    required this.errorText,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final int minimum;
  final int maximum;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconButton(
          key: ValueKey<String>('decrease-$label'),
          tooltip: copy.rhythmSettingsDecrease(label),
          onPressed: enabled ? () => _step(-1) : null,
          icon: const Icon(Icons.remove),
        ),
        Expanded(
          child: TextField(
            key: ValueKey<String>('duration-$label'),
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              labelText: label,
              helperText: copy.rhythmSettingsMinuteMeta(minimum, maximum),
              errorText: errorText,
            ),
            onChanged: onChanged,
          ),
        ),
        IconButton(
          key: ValueKey<String>('increase-$label'),
          tooltip: copy.rhythmSettingsIncrease(label),
          onPressed: enabled ? () => _step(1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  void _step(int delta) {
    final int current = int.tryParse(controller.text) ?? minimum;
    final int next = (current + delta).clamp(minimum, maximum);
    controller.text = next.toString();
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    onChanged(controller.text);
  }
}
