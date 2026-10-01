import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart' show ClockRhythmCard;
import 'preferences_platform_capabilities.dart';
import 'preferences_providers.dart';

final class PermissionStatusPanel extends ConsumerStatefulWidget {
  const PermissionStatusPanel({super.key});

  @override
  ConsumerState<PermissionStatusPanel> createState() =>
      _PermissionStatusPanelState();
}

final class _PermissionStatusPanelState
    extends ConsumerState<PermissionStatusPanel>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(deliveryPermissionProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final AsyncValue<DeliveryPermissionSnapshot?> value = ref.watch(
      deliveryPermissionProvider,
    );
    return ClockRhythmCard.padded(
      key: const ValueKey<String>('permission-status-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const SizedBox.square(
                  dimension: 36,
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  copy.permissionPanelTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) =>
                Text(copy.permissionDeliveryRecoveryDescription),
            data: (DeliveryPermissionSnapshot? snapshot) {
              if (snapshot == null) {
                return Text(copy.permissionDeliveryRecoveryDescription);
              }
              return Column(
                children: <Widget>[
                  _PermissionRow(
                    key: const ValueKey<String>('notification-permission'),
                    title: copy.permissionNotificationTitle,
                    granted: snapshot.notificationGranted,
                    grantedLabel: copy.permissionGranted,
                    requiredLabel: copy.permissionRequired,
                    actionLabel: copy.permissionOpenNotificationSettings,
                    onOpenSettings: () => ref
                        .read(deliveryPermissionActionsProvider)
                        ?.openNotificationSettings(),
                  ),
                  _PermissionRow(
                    key: const ValueKey<String>('exact-alarm-permission'),
                    title: copy.permissionExactAlarmTitle,
                    granted: snapshot.exactAlarmGranted,
                    grantedLabel: copy.permissionGranted,
                    requiredLabel: copy.permissionRequired,
                    actionLabel: copy.permissionOpenExactAlarmSettings,
                    onOpenSettings: () => ref
                        .read(deliveryPermissionActionsProvider)
                        ?.openExactAlarmSettings(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.title,
    required this.granted,
    required this.grantedLabel,
    required this.requiredLabel,
    required this.actionLabel,
    required this.onOpenSettings,
    super.key,
  });

  final String title;
  final bool granted;
  final String grantedLabel;
  final String requiredLabel;
  final String actionLabel;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        granted ? Icons.check_circle_rounded : Icons.error_rounded,
        color: granted ? colors.secondary : colors.error,
      ),
      title: Text(title),
      subtitle: Text(granted ? grantedLabel : requiredLabel),
      trailing: granted
          ? null
          : TextButton(onPressed: onOpenSettings, child: Text(actionLabel)),
    );
  }
}
