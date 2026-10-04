import 'package:clock_rhythm/app/infrastructure/coordinating_preferences_changed_port.dart';
import 'package:clock_rhythm/app/infrastructure/provider_data_import_refresh_adapter.dart';
import 'package:clock_rhythm/app/infrastructure/rhythm_import_safety_adapter.dart';
import 'package:clock_rhythm/contexts/preferences/public.dart';
import 'package:clock_rhythm/contexts/rhythm/public.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'routes preference impacts to their single owning side effect',
    () async {
      final RhythmSession session = RhythmSession.idle(
        configuration: RhythmConfiguration.defaults(),
      )..start(RhythmConfiguration.defaults());
      final _RecordingRhythmDelivery delivery = _RecordingRhythmDelivery();
      final _RecordingRhythmStatusSink statusSink =
          _RecordingRhythmStatusSink();
      final RhythmService reschedule = RhythmService(
        session: session,
        clock: _FixedRhythmClock(DateTime(2026, 8, 23, 6)),
        delivery: delivery,
        statusSink: statusSink,
      );
      int payloadRefreshes = 0;
      int soundRefreshes = 0;
      final CoordinatingPreferencesChangedPort port =
          CoordinatingPreferencesChangedPort(
            rescheduleRhythm: reschedule,
            refreshDeliveryPayload: (UserPreferences preferences) async {
              payloadRefreshes += 1;
            },
            refreshSound: (UserPreferences preferences) async {
              soundRefreshes += 1;
            },
          );
      final UserPreferences preferences = UserPreferences.defaults();

      await port.publish(
        PreferencesChangedEvent(
          preferences: preferences,
          impact: PreferencesChangeImpact.visual,
        ),
      );
      await port.publish(
        PreferencesChangedEvent(
          preferences: preferences,
          impact: PreferencesChangeImpact.sound,
        ),
      );
      await port.publish(
        PreferencesChangedEvent(
          preferences: preferences,
          impact: PreferencesChangeImpact.notificationPayload,
        ),
      );
      await port.publish(
        PreferencesChangedEvent(
          preferences: preferences,
          impact: PreferencesChangeImpact.rhythmSchedule,
        ),
      );

      expect(soundRefreshes, 1);
      expect(payloadRefreshes, 1);
      expect(delivery.cancelCount, 1);
      expect(delivery.scheduled, hasLength(1));
      expect(statusSink.snapshots, hasLength(1));
    },
  );

  test(
    'import safety cancels delivery and audio before publishing Idle',
    () async {
      final List<String> order = <String>[];
      final RhythmSession session = RhythmSession.idle(
        configuration: RhythmConfiguration.defaults(),
      )..start(RhythmConfiguration.defaults());
      final _RecordingRhythmDelivery delivery = _RecordingRhythmDelivery(
        onCancel: () => order.add('delivery'),
      );
      final _RecordingRhythmStatusSink statusSink = _RecordingRhythmStatusSink(
        onPublish: (RhythmStatusSnapshot snapshot) {
          order.add('status:${snapshot.status.name}');
        },
      );
      final RhythmImportSafetyAdapter safety = RhythmImportSafetyAdapter(
        session: session,
        delivery: delivery,
        statusSink: statusSink,
        clock: _FixedRhythmClock(DateTime(2026, 8, 23, 6)),
        stopActiveAudio: () async {
          order.add('audio');
        },
      );

      await safety.stopForImport();

      expect(order, <String>['delivery', 'audio', 'status:idle']);
      expect(session.status, RhythmSessionStatus.idle);
    },
  );

  test(
    'import refresh resets the draft and invalidates runtime state',
    () async {
      final UserPreferences imported = UserPreferences.defaults()
          .changeLanguage(LanguagePreference.english)
          .changeTheme(ThemePreference.nord);
      final _MemorySettingsRepository settings = _MemorySettingsRepository(
        imported,
      );
      final _MemoryDraftStore drafts = _MemoryDraftStore();
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      UserPreferences? applied;
      final ProviderDataImportRefreshAdapter refresh =
          ProviderDataImportRefreshAdapter(
            settingsRepository: settings,
            draftStore: drafts,
            container: () => container,
            applyImportedPreferences: (UserPreferences preferences) async {
              applied = preferences;
            },
          );

      await refresh.refreshAfterImport();

      expect(drafts.saved, RhythmSettingsDraft.fromPreferences(imported));
      expect(applied, imported);
    },
  );
}

final class _FixedRhythmClock implements Clock {
  const _FixedRhythmClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final class _RecordingRhythmDelivery implements RhythmDeliveryPort {
  _RecordingRhythmDelivery({this.onCancel});

  final void Function()? onCancel;
  int cancelCount = 0;
  final List<RhythmEvent> scheduled = <RhythmEvent>[];

  @override
  Future<void> cancelScheduledEvent() async {
    cancelCount += 1;
    onCancel?.call();
  }

  @override
  Future<void> schedule(RhythmEvent event) async {
    scheduled.add(event);
  }
}

final class _RecordingRhythmStatusSink implements RhythmStatusSink {
  _RecordingRhythmStatusSink({this.onPublish});

  final void Function(RhythmStatusSnapshot snapshot)? onPublish;
  final List<RhythmStatusSnapshot> snapshots = <RhythmStatusSnapshot>[];

  @override
  Future<void> publish(RhythmStatusSnapshot snapshot) async {
    snapshots.add(snapshot);
    onPublish?.call(snapshot);
  }
}

final class _MemorySettingsRepository implements SettingsRepository {
  _MemorySettingsRepository(this.preferences);

  UserPreferences preferences;

  @override
  Future<UserPreferences> load() async => preferences;

  @override
  Future<void> save(UserPreferences preferences) async {
    this.preferences = preferences;
  }
}

final class _MemoryDraftStore implements DraftStore {
  RhythmSettingsDraft? saved;

  @override
  Future<void> clear() async {
    saved = null;
  }

  @override
  Future<RhythmSettingsDraft?> load() async => saved;

  @override
  Future<void> save(RhythmSettingsDraft draft) async {
    saved = draft;
  }
}
