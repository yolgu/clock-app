import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'permission_status_panel.dart';
import 'preferences_platform_capabilities.dart';
import 'preferences_providers.dart';
import 'settings/rhythm_settings_panel.dart';
import 'sound/notification_sound_panel.dart';

final class PreferencesPage extends ConsumerWidget {
  const PreferencesPage({this.now = DateTime.now, super.key});

  final DateTime Function() now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PreferencesPlatformCapabilities capabilities = ref.watch(
      preferencesPlatformCapabilitiesProvider,
    );
    return ListView(
      key: const PageStorageKey<String>('preferences-page-scroll'),
      restorationId: 'preferences_page_scroll',
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        RhythmSettingsPanel(now: now),
        const SizedBox(height: 16),
        const NotificationSoundPanel(),
        if (capabilities.showsDeliveryPermissions) ...<Widget>[
          const SizedBox(height: 16),
          const PermissionStatusPanel(),
        ],
      ],
    );
  }
}
