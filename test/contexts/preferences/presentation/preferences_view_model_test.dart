import 'dart:async';

import 'package:clock_rhythm/contexts/preferences/public.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreferencesViewModel', () {
    test(
      'loads the durable preferences and separately restored draft',
      () async {
        final FakePreferencesActions actions = FakePreferencesActions();
        actions.draft = actions.draft.changeFocusMinutes(25);
        final ProviderContainer container = _container(actions);
        addTearDown(container.dispose);

        final PreferencesViewState state = await container.read(
          preferencesViewModelProvider.future,
        );

        expect(state.preferences.rhythmConfiguration.focusDuration.minutes, 50);
        expect(state.draft.rhythmConfiguration.focusDuration.minutes, 25);
        expect(state.isDirty, isTrue);
      },
    );

    test('stores each valid draft without changing durable settings', () async {
      final FakePreferencesActions actions = FakePreferencesActions();
      final ProviderContainer container = _container(actions);
      addTearDown(container.dispose);
      await container.read(preferencesViewModelProvider.future);
      final RhythmSettingsDraft changed = actions.draft.changeFocusMinutes(40);

      await container
          .read(preferencesViewModelProvider.notifier)
          .updateDraft(changed);

      final PreferencesViewState state = container
          .read(preferencesViewModelProvider)
          .requireValue;
      expect(actions.calls, contains('storeDraft'));
      expect(actions.preferences.rhythmConfiguration.focusDuration.minutes, 50);
      expect(state.draft, changed);
      expect(state.isDirty, isTrue);
    });

    test(
      'successful first save resets the draft and completes setup',
      () async {
        final FakePreferencesActions actions = FakePreferencesActions();
        final ProviderContainer container = _container(actions);
        addTearDown(container.dispose);
        await container.read(preferencesViewModelProvider.future);

        await container
            .read(preferencesViewModelProvider.notifier)
            .saveRhythm();

        final PreferencesViewState state = container
            .read(preferencesViewModelProvider)
            .requireValue;
        expect(state.preferences.initialSetupCompleted, isTrue);
        expect(state.isDirty, isFalse);
        expect(state.feedback, PreferencesFeedback.saved);
      },
    );

    test(
      'save failure reloads durable data and preserves unsaved draft',
      () async {
        final FakePreferencesActions actions = FakePreferencesActions();
        final ProviderContainer container = _container(actions);
        addTearDown(container.dispose);
        await container.read(preferencesViewModelProvider.future);
        final RhythmSettingsDraft changed = actions.draft.changeRestMinutes(20);
        await container
            .read(preferencesViewModelProvider.notifier)
            .updateDraft(changed);
        actions.failSave = true;

        await container
            .read(preferencesViewModelProvider.notifier)
            .saveRhythm();

        final PreferencesViewState state = container
            .read(preferencesViewModelProvider)
            .requireValue;
        expect(state.preferences, actions.preferences);
        expect(state.draft, changed);
        expect(state.isDirty, isTrue);
        expect(state.feedback, PreferencesFeedback.failed);
      },
    );

    test('immediate theme changes retain the rhythm draft', () async {
      final FakePreferencesActions actions = FakePreferencesActions();
      final ProviderContainer container = _container(actions);
      addTearDown(container.dispose);
      await container.read(preferencesViewModelProvider.future);
      final RhythmSettingsDraft changed = actions.draft.changeRestMinutes(15);
      await container
          .read(preferencesViewModelProvider.notifier)
          .updateDraft(changed);

      await container
          .read(preferencesViewModelProvider.notifier)
          .changeTheme(ThemePreference.nord);

      final PreferencesViewState state = container
          .read(preferencesViewModelProvider)
          .requireValue;
      expect(state.preferences.theme, ThemePreference.nord);
      expect(state.draft, changed);
      expect(state.isDirty, isTrue);
    });

    test('sound mode changes stop an active preview in screen state', () async {
      final FakePreferencesActions actions = FakePreferencesActions();
      final ProviderContainer container = _container(actions);
      addTearDown(container.dispose);
      await container.read(preferencesViewModelProvider.future);
      final PreferencesViewModel viewModel = container.read(
        preferencesViewModelProvider.notifier,
      );
      await viewModel.previewSound();
      expect(
        container
            .read(preferencesViewModelProvider)
            .requireValue
            .isSoundPreviewing,
        isTrue,
      );

      await viewModel.toggleMute();

      expect(
        container
            .read(preferencesViewModelProvider)
            .requireValue
            .isSoundPreviewing,
        isFalse,
      );
      expect(actions.calls, containsAllInOrder(<String>['preview', 'mute']));
    });

    test('reflects asynchronous platform repair state while mounted', () async {
      final FakePreferencesActions actions = FakePreferencesActions();
      final ProviderContainer container = _container(actions);
      addTearDown(container.dispose);
      await container.read(preferencesViewModelProvider.future);

      actions.publishRepairNeeds(const <PreferencesRepairNeed>{
        PreferencesRepairNeed.sound,
      });
      await pumpEventQueue();

      expect(
        container.read(preferencesViewModelProvider).requireValue.repairNeeds,
        const <PreferencesRepairNeed>{PreferencesRepairNeed.sound},
      );

      actions.publishRepairNeeds(const <PreferencesRepairNeed>{});
      await pumpEventQueue();

      expect(
        container.read(preferencesViewModelProvider).requireValue.repairNeeds,
        isEmpty,
      );
    });
  });
}

ProviderContainer _container(FakePreferencesActions actions) {
  addTearDown(actions.dispose);
  return ProviderContainer(
    overrides: [preferencesActionsProvider.overrideWithValue(actions)],
  );
}

final class FakePreferencesActions implements PreferencesActions {
  FakePreferencesActions()
    : preferences = UserPreferences.defaults(),
      draft = RhythmSettingsDraft.fromPreferences(UserPreferences.defaults());

  UserPreferences preferences;
  RhythmSettingsDraft draft;
  bool failSave = false;
  final List<String> calls = <String>[];
  Completer<void> previewCompletion = Completer<void>();
  final StreamController<Set<PreferencesRepairNeed>> _repairNeeds =
      StreamController<Set<PreferencesRepairNeed>>.broadcast(sync: true);
  Set<PreferencesRepairNeed> currentRepairNeeds = <PreferencesRepairNeed>{};

  @override
  Future<PreferencesInitialData> load() async {
    calls.add('load');
    return PreferencesInitialData(
      preferences: preferences,
      draft: draft,
      repairNeeds: currentRepairNeeds,
    );
  }

  @override
  Stream<Set<PreferencesRepairNeed>> watchRepairNeeds() {
    return _repairNeeds.stream;
  }

  void publishRepairNeeds(Set<PreferencesRepairNeed> repairNeeds) {
    currentRepairNeeds = Set<PreferencesRepairNeed>.of(repairNeeds);
    _repairNeeds.add(Set<PreferencesRepairNeed>.unmodifiable(repairNeeds));
  }

  Future<void> dispose() {
    return _repairNeeds.close();
  }

  @override
  Future<void> storeDraft(RhythmSettingsDraft nextDraft) async {
    calls.add('storeDraft');
    draft = nextDraft;
  }

  @override
  Future<RhythmSettingsDraft> discardDraft() async {
    calls.add('discardDraft');
    draft = RhythmSettingsDraft.fromPreferences(preferences);
    return draft;
  }

  @override
  Future<PreferencesCommandResult> saveRhythm(
    RhythmSettingsDraft nextDraft,
  ) async {
    calls.add('saveRhythm');
    if (failSave) {
      throw StateError('save failed');
    }
    preferences = preferences.applyRhythmSettings(
      configuration: nextDraft.rhythmConfiguration,
      autoStartEnabled: nextDraft.autoStartEnabled,
    );
    draft = RhythmSettingsDraft.fromPreferences(preferences);
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> changeLanguage(
    LanguagePreference language,
  ) async {
    calls.add('language');
    preferences = preferences.changeLanguage(language);
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> changeTheme(ThemePreference theme) async {
    calls.add('theme');
    preferences = preferences.changeTheme(theme);
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> useBundledSound() async {
    calls.add('defaultSound');
    preferences = preferences.changeNotificationSound(
      preferences.notificationSound.useBundledDefault(),
    );
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> chooseCustomSound() async {
    calls.add('customSound');
    preferences = preferences.changeNotificationSound(
      NotificationSoundPreference.custom(
        fileName: 'chosen.mp3',
        privateSource: 'private/chosen.mp3',
        volume: preferences.notificationSound.volume,
      ),
    );
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> changeVolume(double volume) async {
    calls.add('volume');
    preferences = preferences.changeVolume(volume);
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> toggleMute() async {
    calls.add('mute');
    preferences = preferences.toggleMute(
      UnmuteSoundBehavior.restorePreviousSelection,
    );
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<SoundPreviewPlayback> previewSound() async {
    calls.add('preview');
    return SoundPreviewPlayback(completed: previewCompletion.future);
  }

  @override
  Future<void> stopSoundPreview() async {
    calls.add('stopPreview');
  }

  @override
  Future<PreferencesCommandResult> repairEffect(
    PreferencesChangeImpact impact,
  ) async {
    calls.add('repair:${impact.name}');
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> repairAutoStart() async {
    calls.add('repairAutoStart');
    return PreferencesCommandResult(preferences: preferences);
  }
}
