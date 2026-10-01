import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart'
    show ClockRhythmLayout, ClockRhythmPageHeader, ClockRhythmSpace;
import 'permission_status_panel.dart';
import 'preferences_platform_capabilities.dart';
import 'preferences_providers.dart';
import 'settings/rhythm_settings_panel.dart';
import 'sound/notification_sound_panel.dart';

/// The Settings destination: focus window and alerts, notification sound
/// and, where the platform needs them, delivery permissions.
final class PreferencesPage extends ConsumerWidget {
  const PreferencesPage({this.now = DateTime.now, super.key});

  /// Settings read best as a single comfortable column.
  static const double maximumColumnWidth = 760;

  final DateTime Function() now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final PreferencesPlatformCapabilities capabilities = ref.watch(
      preferencesPlatformCapabilitiesProvider,
    );
    final double width = MediaQuery.sizeOf(context).width;
    final EdgeInsets insets = ClockRhythmLayout.pageInsetsFor(width);
    final double horizontal = math.max(
      insets.left,
      (width - maximumColumnWidth) / 2,
    );
    return ListView(
      key: const PageStorageKey<String>('preferences-page-scroll'),
      restorationId: 'preferences_page_scroll',
      padding: insets.copyWith(left: horizontal, right: horizontal),
      children: <Widget>[
        ClockRhythmPageHeader(
          title: copy.settingsTitle,
          description: copy.settingsDescription,
        ),
        RhythmSettingsPanel(now: now),
        const SizedBox(height: ClockRhythmSpace.space20),
        const NotificationSoundPanel(),
        if (capabilities.showsDeliveryPermissions) ...<Widget>[
          const SizedBox(height: ClockRhythmSpace.space20),
          const PermissionStatusPanel(),
        ],
      ],
    );
  }
}
