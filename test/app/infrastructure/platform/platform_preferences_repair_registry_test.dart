import 'package:clock_rhythm/app/infrastructure/platform/platform_preferences_repair_registry.dart';
import 'package:clock_rhythm/contexts/preferences/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'watches the initial snapshot and publishes distinct repair changes',
    () async {
      final PlatformPreferencesRepairRegistry registry =
          PlatformPreferencesRepairRegistry();
      addTearDown(registry.dispose);
      final Future<void> expectation = expectLater(
        registry.watch(),
        emitsInOrder(<Set<PreferencesRepairNeed>>[
          const <PreferencesRepairNeed>{},
          const <PreferencesRepairNeed>{PreferencesRepairNeed.sound},
          const <PreferencesRepairNeed>{},
        ]),
      );

      registry.report(PreferencesRepairNeed.sound);
      registry.report(PreferencesRepairNeed.sound);
      registry.recordCommandResult(
        attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.sound},
        reported: const <PreferencesRepairNeed>{},
      );

      await expectation;
    },
  );

  test('records one command outcome without clearing unrelated repairs', () {
    final PlatformPreferencesRepairRegistry registry =
        PlatformPreferencesRepairRegistry();
    addTearDown(registry.dispose);
    registry.report(PreferencesRepairNeed.sound);
    registry.report(PreferencesRepairNeed.autoStart);

    registry.recordCommandResult(
      attempted: const <PreferencesRepairNeed>{PreferencesRepairNeed.sound},
      reported: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );

    expect(registry.current, const <PreferencesRepairNeed>{
      PreferencesRepairNeed.autoStart,
      PreferencesRepairNeed.notificationPayload,
    });
    expect(
      () => registry.current.add(PreferencesRepairNeed.visual),
      throwsUnsupportedError,
    );
  });
}
