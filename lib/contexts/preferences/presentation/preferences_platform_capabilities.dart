enum PreferencesPlatformKind { windows, android, macos }

final class PreferencesPlatformCapabilities {
  const PreferencesPlatformCapabilities._({
    required this.kind,
    required this.showsAutoStart,
    required this.showsCustomSound,
    required this.showsVolume,
    required this.showsDeliveryPermissions,
  });

  static const PreferencesPlatformCapabilities windows =
      PreferencesPlatformCapabilities._(
        kind: PreferencesPlatformKind.windows,
        showsAutoStart: true,
        showsCustomSound: true,
        showsVolume: true,
        showsDeliveryPermissions: false,
      );

  static const PreferencesPlatformCapabilities android =
      PreferencesPlatformCapabilities._(
        kind: PreferencesPlatformKind.android,
        showsAutoStart: false,
        showsCustomSound: false,
        showsVolume: false,
        showsDeliveryPermissions: true,
      );

  static const PreferencesPlatformCapabilities macos =
      PreferencesPlatformCapabilities._(
        kind: PreferencesPlatformKind.macos,
        showsAutoStart: false,
        showsCustomSound: false,
        showsVolume: true,
        showsDeliveryPermissions: false,
      );

  final PreferencesPlatformKind kind;
  final bool showsAutoStart;
  final bool showsCustomSound;
  final bool showsVolume;
  final bool showsDeliveryPermissions;
}

final class DeliveryPermissionSnapshot {
  const DeliveryPermissionSnapshot({
    required this.notificationGranted,
    required this.exactAlarmGranted,
  });

  final bool notificationGranted;
  final bool exactAlarmGranted;
}

abstract interface class DeliveryPermissionActions {
  Future<DeliveryPermissionSnapshot> load();

  Future<void> openNotificationSettings();

  Future<void> openExactAlarmSettings();
}
