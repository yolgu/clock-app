import 'dart:io';

import 'package:clock_rhythm/app/composition/app_platform_services.dart';
import 'package:clock_rhythm/app/composition/clock_rhythm_runtime.dart';
import 'package:clock_rhythm/app/infrastructure/device_state/device_sound_locator_store.dart';
import 'package:clock_rhythm/app/infrastructure/persistence/database_startup.dart';
import 'package:clock_rhythm/app/infrastructure/platform/platform_preferences_repair_registry.dart';
import 'package:clock_rhythm/app/infrastructure/system_clock.dart';
import 'package:clock_rhythm/app/platform_presentation_profile.dart';
import 'package:clock_rhythm/contexts/preferences/public.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/contexts/rhythm/public.dart';
import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart'
    show RhythmActions;
import 'package:clock_rhythm/features/data_transfer/infrastructure/json/backup_v1_codec.dart';
import 'package:clock_rhythm/features/data_transfer/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  testWidgets('wires durable providers and all five product destinations', (
    WidgetTester tester,
  ) async {
    final TestDatabase database = TestDatabase.open();
    final _MemoryDeviceSoundLocatorStore deviceState =
        _MemoryDeviceSoundLocatorStore();
    final _MemoryDraftStore draftStore = _MemoryDraftStore();
    final ClockRhythmRuntime runtime = await ClockRhythmRuntime.create(
      databaseReady: DatabaseReady(
        database: database.database,
        databasePath: 'memory.sqlite',
      ),
      platformServices: _platformServices(),
      deviceSoundLocatorStore: deviceState,
      draftStore: draftStore,
      backupFile: _MemoryBackupFilePort(),
      backupCodec: const BackupV1Codec(),
    );
    addTearDown(runtime.dispose);

    await tester.pumpWidget(runtime.buildApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('clock-face-repaint-boundary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('today-todo-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('rhythm-status-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('rhythm-controls')),
      findsOneWidget,
    );
    final ScrollableState clockScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey<String>('clock-page-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(clockScroll.position.pixels, 0, reason: 'opens at the clock face');
    expect(
      find.byKey(const ValueKey<String>('rhythm-settings-panel')),
      findsNothing,
    );
    final Finder settingsShortcut = find.byKey(
      const ValueKey<String>('rhythm-settings-shortcut'),
    );
    await tester.ensureVisible(settingsShortcut);
    await tester.pumpAndSettle();
    await tester.tap(settingsShortcut);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('rhythm-settings-panel')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const PageStorageKey<String>('preferences-page-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('notification-sound-panel')),
      findsOneWidget,
    );

    await tester.tap(find.text('데이터'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('data-management-panel')),
      findsOneWidget,
    );

    await tester.tap(find.text('테마'));
    await tester.pumpAndSettle();
    expect(find.byType(ThemePage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await runtime.dispose();
  });

  testWidgets(
    'confirmed import reloads mounted Preferences and Todo views from durable replacement',
    (WidgetTester tester) async {
      final TestDatabase database = TestDatabase.open();
      final ClockRhythmRuntime runtime = await ClockRhythmRuntime.create(
        databaseReady: DatabaseReady(
          database: database.database,
          databasePath: 'memory.sqlite',
        ),
        platformServices: _platformServices(),
        deviceSoundLocatorStore: _MemoryDeviceSoundLocatorStore(),
        draftStore: _MemoryDraftStore(),
        backupFile: _MemoryBackupFilePort(
          File(
            'test/fixtures/backups/neutralino-v1-full.json',
          ).readAsBytesSync(),
        ),
        backupCodec: const BackupV1Codec(),
        systemClock: SystemClock(now: () => DateTime(2026, 6, 2, 10)),
      );
      addTearDown(runtime.dispose);

      await tester.pumpWidget(runtime.buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Portable task'), findsNothing);

      await tester.tap(find.text('데이터'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('import-backup')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('confirm-backup-import')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data'), findsWidgets);
      await tester.tap(find.text('Clock').first);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const PageStorageKey<String>('clock-page-scroll')),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(find.text('Portable task'), findsOneWidget);
      expect(
        find.text('40 min focus · 12 min rest · 22:00-02:00 · Default'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await runtime.dispose();
    },
  );

  testWidgets(
    'restores a running native delivery without replacing its schedule',
    (WidgetTester tester) async {
      final TestDatabase database = TestDatabase.open();
      final _RecordingRhythmDelivery delivery = _RecordingRhythmDelivery();
      final _FixedDeliveryRecovery recovery = _FixedDeliveryRecovery(
        DeliveryRecoveryStatus(
          disposition: DeliveryRecoveryDisposition.running,
          reason: null,
          revision: 7,
          observedAt: DateTime(2026, 8, 23, 9),
          configuration: RhythmConfiguration.defaults(),
        ),
      );
      final ClockRhythmRuntime runtime = await ClockRhythmRuntime.create(
        databaseReady: DatabaseReady(
          database: database.database,
          databasePath: 'memory.sqlite',
        ),
        platformServices: _platformServices(
          delivery: delivery,
          recovery: recovery,
        ),
        deviceSoundLocatorStore: _MemoryDeviceSoundLocatorStore(),
        draftStore: _MemoryDraftStore(),
        backupFile: _MemoryBackupFilePort(),
        backupCodec: const BackupV1Codec(),
      );
      addTearDown(runtime.dispose);

      await tester.pumpWidget(runtime.buildApp());
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('rhythm-status-value')),
            )
            .data,
        '실행 중',
      );
      expect(recovery.auditCount, 1);
      expect(recovery.explicitRecoveryCount, 0);
      expect(delivery.cancelCount, 0);
      expect(delivery.scheduleCount, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await runtime.dispose();
    },
  );

  test('disposes platform services when native recovery audit fails', () async {
    final TestDatabase database = TestDatabase.open();
    int disposeCount = 0;

    await expectLater(
      ClockRhythmRuntime.create(
        databaseReady: DatabaseReady(
          database: database.database,
          databasePath: 'memory.sqlite',
        ),
        platformServices: _platformServices(
          recovery: const _FailingDeliveryRecovery(),
          onDisposed: () => disposeCount += 1,
        ),
        deviceSoundLocatorStore: _MemoryDeviceSoundLocatorStore(),
        draftStore: _MemoryDraftStore(),
        backupFile: _MemoryBackupFilePort(),
        backupCodec: const BackupV1Codec(),
      ),
      throwsStateError,
    );

    expect(disposeCount, 1);
  });

  testWidgets(
    'keeps interrupted native delivery idle until the user starts again',
    (WidgetTester tester) async {
      final TestDatabase database = TestDatabase.open();
      final _RecordingRhythmDelivery delivery = _RecordingRhythmDelivery();
      final _FixedDeliveryRecovery recovery = _FixedDeliveryRecovery(
        DeliveryRecoveryStatus(
          disposition: DeliveryRecoveryDisposition.needsUserRecovery,
          reason: DeliveryRecoveryReason.registrationMissing,
          revision: 8,
          observedAt: DateTime(2026, 8, 23, 9),
          configuration: RhythmConfiguration.defaults(),
        ),
      );
      final ClockRhythmRuntime runtime = await ClockRhythmRuntime.create(
        databaseReady: DatabaseReady(
          database: database.database,
          databasePath: 'memory.sqlite',
        ),
        platformServices: _platformServices(
          delivery: delivery,
          recovery: recovery,
        ),
        deviceSoundLocatorStore: _MemoryDeviceSoundLocatorStore(),
        draftStore: _MemoryDraftStore(),
        backupFile: _MemoryBackupFilePort(),
        backupCodec: const BackupV1Codec(),
      );
      addTearDown(runtime.dispose);

      await tester.pumpWidget(runtime.buildApp());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('rhythm-command-failure')),
        findsOneWidget,
      );
      expect(delivery.cancelCount, 0);
      expect(delivery.scheduleCount, 0);

      await tester.tap(find.byKey(const ValueKey<String>('start-rhythm')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('rhythm-status-value')),
            )
            .data,
        '실행 중',
      );
      expect(
        find.byKey(const ValueKey<String>('rhythm-command-failure')),
        findsNothing,
      );
      expect(recovery.auditCount, 1);
      expect(recovery.explicitRecoveryCount, 0);
      expect(delivery.scheduleCount, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await runtime.dispose();
    },
  );
}

AppPlatformServices _platformServices({
  _RecordingRhythmDelivery? delivery,
  DeliveryRecoveryPort? recovery,
  void Function()? onDisposed,
}) {
  final _RecordingRhythmDelivery effectiveDelivery =
      delivery ?? _RecordingRhythmDelivery();
  final _NoOpSoundPreview soundPreview = _NoOpSoundPreview();
  final PlatformPreferencesRepairRegistry repairState =
      PlatformPreferencesRepairRegistry();
  return AppPlatformServices(
    presentationProfile: PlatformPresentationProfile.windows,
    preferencesCapabilities: PreferencesPlatformCapabilities.windows,
    autoStart: const _PassThroughAutoStart(),
    notificationSoundFile: const _NoCustomSoundFile(),
    preferencesRepairState: repairState,
    soundPreview: soundPreview,
    rhythmDelivery: effectiveDelivery,
    rhythmStartCapability: const _GrantedRhythmCapability(),
    rhythmStatusSink: const _NoOpRhythmStatusSink(),
    deliveryRecovery: recovery,
    refreshDeliveryPayload: (UserPreferences preferences) async {},
    refreshSound: (UserPreferences preferences) async {},
    stopActiveAudio: soundPreview.stop,
    bindRhythmActions: (RhythmActions actions) async {},
    dispose: () async {
      await repairState.dispose();
      onDisposed?.call();
    },
  );
}

final class _MemoryDeviceSoundLocatorStore implements DeviceSoundLocatorStore {
  DeviceSoundLocatorState state = DeviceSoundLocatorState.empty;

  @override
  Future<DeviceSoundLocatorState> load() async => state;

  @override
  Future<void> save(DeviceSoundLocatorState state) async {
    this.state = state;
  }
}

final class _MemoryDraftStore implements DraftStore {
  RhythmSettingsDraft? value;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<RhythmSettingsDraft?> load() async => value;

  @override
  Future<void> save(RhythmSettingsDraft draft) async {
    value = draft;
  }
}

final class _MemoryBackupFilePort implements BackupFilePort {
  const _MemoryBackupFilePort([this.importBytes]);

  final List<int>? importBytes;

  @override
  Future<BackupFileContent?> pickImport({required int maximumBytes}) async {
    final List<int>? bytes = importBytes;
    return bytes == null ? null : BackupFileContent(bytes);
  }

  @override
  Future<bool> saveExport({
    required String suggestedFileName,
    required List<int> bytes,
  }) async {
    return true;
  }
}

final class _PassThroughAutoStart implements AutoStartPort {
  const _PassThroughAutoStart();

  @override
  Future<AutoStartReconciliation> reconcile({
    required bool desiredEnabled,
  }) async {
    return AutoStartReconciliation(
      desiredEnabled: desiredEnabled,
      actualEnabled: desiredEnabled,
    );
  }
}

final class _NoCustomSoundFile implements NotificationSoundFilePort {
  const _NoCustomSoundFile();

  @override
  Future<SelectedNotificationSound?> chooseCustomMp3() async => null;
}

final class _NoOpSoundPreview implements SoundPreviewPort {
  @override
  Future<SoundPreviewPlayback> play(NotificationSoundPreference sound) async {
    return SoundPreviewPlayback(completed: Future<void>.value());
  }

  @override
  Future<void> stop() async {}
}

final class _RecordingRhythmDelivery implements RhythmDeliveryPort {
  RhythmEvent? event;
  int cancelCount = 0;
  int scheduleCount = 0;

  @override
  Future<void> cancelScheduledEvent() async {
    cancelCount += 1;
    event = null;
  }

  @override
  Future<void> schedule(RhythmEvent event) async {
    scheduleCount += 1;
    this.event = event;
  }
}

final class _FixedDeliveryRecovery implements DeliveryRecoveryPort {
  _FixedDeliveryRecovery(this.status);

  final DeliveryRecoveryStatus status;
  int auditCount = 0;
  int explicitRecoveryCount = 0;

  @override
  Future<DeliveryRecoveryStatus> auditForeground() async {
    auditCount += 1;
    return status;
  }

  @override
  Future<DeliveryRecoveryStatus> recoverExplicitly() async {
    explicitRecoveryCount += 1;
    return status;
  }
}

final class _FailingDeliveryRecovery implements DeliveryRecoveryPort {
  const _FailingDeliveryRecovery();

  @override
  Future<DeliveryRecoveryStatus> auditForeground() async {
    throw StateError('native recovery audit failed');
  }

  @override
  Future<DeliveryRecoveryStatus> recoverExplicitly() async {
    throw StateError('native recovery audit failed');
  }
}

final class _GrantedRhythmCapability implements RhythmStartCapability {
  const _GrantedRhythmCapability();

  @override
  Future<void> openSettings(RhythmStartFailure failure) async {}

  @override
  Future<RhythmStartCapabilityResult> requestForExplicitStart() async {
    return const RhythmStartCapabilityResult.granted();
  }
}

final class _NoOpRhythmStatusSink implements RhythmStatusSink {
  const _NoOpRhythmStatusSink();

  @override
  Future<void> publish(RhythmStatusSnapshot snapshot) async {}
}
