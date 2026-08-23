enum AppFlavor {
  beta('beta'),
  production('production');

  const AppFlavor(this.id);

  final String id;

  static AppFlavor parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'beta' => AppFlavor.beta,
      'production' => AppFlavor.production,
      _ => throw ArgumentError.value(
        value,
        'CLOCK_RHYTHM_FLAVOR',
        'must be beta or production',
      ),
    };
  }
}

final class AppFlavorConfiguration {
  const AppFlavorConfiguration._({
    required this.flavor,
    required this.displayName,
    required this.semanticVersion,
    required this.buildNumber,
    required this.androidApplicationId,
    required this.windowsIdentity,
    required this.windowsNotificationActivationGuid,
    required this.windowsAutoStartRegistrationName,
    required this.windowsStartupTaskId,
    required this.databaseName,
  });

  static AppFlavorConfiguration fromEnvironment() {
    return forFlavor(
      AppFlavor.parse(
        const String.fromEnvironment(
          'CLOCK_RHYTHM_FLAVOR',
          defaultValue: 'beta',
        ),
      ),
    );
  }

  static AppFlavorConfiguration forFlavor(AppFlavor flavor) {
    return switch (flavor) {
      AppFlavor.beta => const AppFlavorConfiguration._(
        flavor: AppFlavor.beta,
        displayName: 'Clock Rhythm Beta',
        semanticVersion: '0.1.0',
        buildNumber: 1,
        androidApplicationId: 'dev.wndls.clockrhythm.beta',
        windowsIdentity: 'dev.wndls.clockrhythm.beta',
        windowsNotificationActivationGuid:
            '8e7a9bf1-4556-4f3c-bf57-0a15b82b2131',
        windowsAutoStartRegistrationName: 'Clock Rhythm Beta',
        windowsStartupTaskId: 'ClockRhythmBetaStartup',
        databaseName: 'clock_rhythm_beta',
      ),
      AppFlavor.production => const AppFlavorConfiguration._(
        flavor: AppFlavor.production,
        displayName: 'Clock Rhythm',
        semanticVersion: '1.0.0',
        buildNumber: 1,
        androidApplicationId: 'dev.wndls.clockrhythm',
        windowsIdentity: 'dev.wndls.clockrhythm',
        windowsNotificationActivationGuid:
            'c7af2a63-9068-4bfa-9cc1-2c99ccb0ab7d',
        windowsAutoStartRegistrationName: 'Clock Rhythm',
        windowsStartupTaskId: 'ClockRhythmStartup',
        databaseName: 'clock_rhythm',
      ),
    };
  }

  final AppFlavor flavor;
  final String displayName;
  final String semanticVersion;
  final int buildNumber;
  final String androidApplicationId;
  final String windowsIdentity;
  final String windowsNotificationActivationGuid;
  final String windowsAutoStartRegistrationName;
  final String windowsStartupTaskId;
  final String databaseName;

  String get version => '$semanticVersion+$buildNumber';

  bool get isBeta => flavor == AppFlavor.beta;
}
