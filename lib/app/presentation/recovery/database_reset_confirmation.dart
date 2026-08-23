import 'package:flutter/material.dart';

import '../../../shared/i18n/public.dart';

final class DatabaseResetConfirmation extends StatefulWidget {
  const DatabaseResetConfirmation({required this.onConfirmed, super.key});

  final VoidCallback onConfirmed;

  @override
  State<DatabaseResetConfirmation> createState() =>
      _DatabaseResetConfirmationState();
}

final class _DatabaseResetConfirmationState
    extends State<DatabaseResetConfirmation> {
  bool _armed = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    return AlertDialog(
      key: const ValueKey<String>('database-reset-confirmation'),
      title: Text(copy.databaseRecoveryResetTitle),
      content: Text(copy.databaseRecoveryResetDescription),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(copy.actionCancel),
        ),
        if (!_armed)
          FilledButton.tonal(
            key: const ValueKey<String>('arm-database-reset'),
            onPressed: () => setState(() => _armed = true),
            child: Text(copy.databaseRecoveryReset),
          )
        else
          FilledButton(
            key: const ValueKey<String>('confirm-database-reset'),
            onPressed: widget.onConfirmed,
            child: Text(copy.databaseRecoveryConfirmReset),
          ),
      ],
    );
  }
}
