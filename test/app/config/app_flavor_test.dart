import 'package:clock_rhythm/app/config/app_flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unqualified developer builds default to the isolated beta flavor', () {
    expect(AppFlavorConfiguration.fromEnvironment().flavor, AppFlavor.beta);
  });

  test('production identity and version are stable', () {
    final AppFlavorConfiguration production = AppFlavorConfiguration.forFlavor(
      AppFlavor.production,
    );

    expect(production.version, '1.0.0+1');
    expect(production.androidApplicationId, 'dev.wndls.clockrhythm');
    expect(production.windowsIdentity, 'dev.wndls.clockrhythm');
    expect(
      production.windowsNotificationActivationGuid,
      'c7af2a63-9068-4bfa-9cc1-2c99ccb0ab7d',
    );
    expect(production.windowsAutoStartRegistrationName, 'Clock Rhythm');
    expect(production.windowsStartupTaskId, 'ClockRhythmStartup');
    expect(production.databaseName, 'clock_rhythm');
  });

  test('beta identity and storage are isolated from production', () {
    final AppFlavorConfiguration beta = AppFlavorConfiguration.forFlavor(
      AppFlavor.beta,
    );
    final AppFlavorConfiguration production = AppFlavorConfiguration.forFlavor(
      AppFlavor.production,
    );

    expect(beta.version, '0.1.0+1');
    expect(beta.androidApplicationId, 'dev.wndls.clockrhythm.beta');
    expect(beta.windowsIdentity, 'dev.wndls.clockrhythm.beta');
    expect(beta.windowsAutoStartRegistrationName, 'Clock Rhythm Beta');
    expect(beta.windowsStartupTaskId, 'ClockRhythmBetaStartup');
    expect(beta.databaseName, 'clock_rhythm_beta');
    expect(beta.databaseName, isNot(production.databaseName));
    expect(
      beta.windowsNotificationActivationGuid,
      isNot(production.windowsNotificationActivationGuid),
    );
  });

  test('rejects an unknown compile-time flavor', () {
    expect(() => AppFlavor.parse('nightly'), throwsArgumentError);
  });
}
