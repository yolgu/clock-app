import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/i18n/public.dart' show ClockTimeFormatter;

final class ClockTimeField extends StatelessWidget {
  const ClockTimeField({
    required this.label,
    required this.pickerTooltip,
    required this.controller,
    required this.onChanged,
    required this.errorText,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String pickerTooltip;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey<String>('clock-time-$label'),
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.datetime,
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(5),
      ],
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: IconButton(
          key: ValueKey<String>('clock-time-picker-$label'),
          tooltip: pickerTooltip,
          onPressed: enabled ? () => _selectTime(context) : null,
          icon: const Icon(Icons.schedule_outlined),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    const ClockTimeFormatter formatter = ClockTimeFormatter();
    final TimeOfDay initialTime = _resolveInitialTime(formatter);
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: label,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected == null || !context.mounted) {
      return;
    }
    final String formatted = formatter.formatComponents(
      hour: selected.hour,
      minute: selected.minute,
    );
    controller.text = formatted;
    onChanged(formatted);
  }

  TimeOfDay _resolveInitialTime(ClockTimeFormatter formatter) {
    try {
      final ({int hour, int minute}) parts = formatter.parse(controller.text);
      return TimeOfDay(hour: parts.hour, minute: parts.minute);
    } on FormatException {
      return TimeOfDay.now();
    }
  }
}
