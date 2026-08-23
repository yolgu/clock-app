import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart';
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
    return Card(
      key: const ValueKey<String>('permission-status-panel'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              copy.permissionPanelTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(granted ? Icons.check_circle : Icons.warning_amber),
      title: Text(title),
      subtitle: Text(granted ? grantedLabel : requiredLabel),
      trailing: granted
          ? null
          : TextButton(onPressed: onOpenSettings, child: Text(actionLabel)),
    );
  }
}
