import 'dart:async';

import 'package:clock_rhythm/app/navigation/app_router.dart';
import 'package:clock_rhythm/app/platform_presentation_profile.dart';
import 'package:clock_rhythm/app/presentation/clock_rhythm_root.dart';
import 'package:clock_rhythm/contexts/preferences/public.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/features/data_transfer/public_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('durable language and theme changes rebuild the app root', (
    WidgetTester tester,
  ) async {
    final _RootPreferencesActions actions = _RootPreferencesActions();
    final AppDestinationPages pages = AppDestinationPages(
      clock: (_) => const _RootProbe(),
      calendar: (_, _) => const SizedBox.shrink(),
      data: (_) => const SizedBox.shrink(),
      theme: (_) => const SizedBox.shrink(),
    );
    final ClockRhythmRouter router = ClockRhythmRouter(
      profile: PlatformPresentationProfile.windows,
      pages: pages,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesActionsProvider.overrideWithValue(actions)],
        child: ClockRhythmRoot(router: router.router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ko'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey<String>('theme-color')))
          .data,
      ThemeCatalog.resolve(
        ThemePreference.current,
      ).background.color.toARGB32().toString(),
    );

    await tester.tap(find.byKey(const ValueKey<String>('change-root-style')));
    await tester.pumpAndSettle();

    expect(find.text('en'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey<String>('theme-color')))
          .data,
      ThemeCatalog.resolve(
        ThemePreference.nord,
      ).background.color.toARGB32().toString(),
    );
  });

  testWidgets('confirmed replacement suspends every routed mutation', (
    WidgetTester tester,
  ) async {
    int mutations = 0;
    final AppDestinationPages pages = AppDestinationPages(
      clock: (_) => FilledButton(
        key: const ValueKey<String>('mutating-action'),
        onPressed: () => mutations += 1,
        child: const Text('mutate'),
      ),
      calendar: (_, _) => const SizedBox.shrink(),
      data: (_) => const SizedBox.shrink(),
      theme: (_) => const SizedBox.shrink(),
    );
    final ClockRhythmRouter router = ClockRhythmRouter(
      profile: PlatformPresentationProfile.windows,
      pages: pages,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesActionsProvider.overrideWithValue(
            _RootPreferencesActions(),
          ),
          dataTransferViewModelProvider.overrideWithBuild((
            Ref ref,
            DataTransferViewModel notifier,
          ) {
            return const DataTransferState(phase: DataTransferPhase.confirming);
          }),
        ],
        child: ClockRhythmRoot(router: router.router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('mutating-action')),
      warnIfMissed: false,
    );

    expect(mutations, 0);
  });
}

final class _RootProbe extends ConsumerWidget {
  const _RootProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color background = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text(Localizations.localeOf(context).languageCode),
          Text(
            background.toARGB32().toString(),
            key: const ValueKey<String>('theme-color'),
          ),
          FilledButton(
            key: const ValueKey<String>('change-root-style'),
            onPressed: () async {
              final PreferencesViewModel viewModel = ref.read(
                preferencesViewModelProvider.notifier,
              );
              await viewModel.changeLanguage(LanguagePreference.english);
              await viewModel.changeTheme(ThemePreference.nord);
            },
            child: const Text('change'),
          ),
        ],
      ),
    );
  }
}

final class _RootPreferencesActions implements PreferencesActions {
  UserPreferences preferences = UserPreferences.defaults();

  @override
  Future<PreferencesInitialData> load() async {
    return PreferencesInitialData(
      preferences: preferences,
      draft: RhythmSettingsDraft.fromPreferences(preferences),
    );
  }

  @override
  Stream<Set<PreferencesRepairNeed>> watchRepairNeeds() {
    return const Stream<Set<PreferencesRepairNeed>>.empty();
  }

  @override
  Future<PreferencesCommandResult> changeLanguage(
    LanguagePreference language,
  ) async {
    preferences = preferences.changeLanguage(language);
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> changeTheme(ThemePreference theme) async {
    preferences = preferences.changeTheme(theme);
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> changeVolume(double volume) async {
    preferences = preferences.changeVolume(volume);
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> chooseCustomSound() async {
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<RhythmSettingsDraft> discardDraft() async {
    return RhythmSettingsDraft.fromPreferences(preferences);
  }

  @override
  Future<SoundPreviewPlayback> previewSound() async {
    return SoundPreviewPlayback(completed: Future<void>.value());
  }

  @override
  Future<PreferencesCommandResult> repairAutoStart() async {
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> repairEffect(
    PreferencesChangeImpact impact,
  ) async {
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> saveRhythm(RhythmSettingsDraft draft) async {
    preferences = preferences.applyRhythmSettings(
      configuration: draft.rhythmConfiguration,
      autoStartEnabled: draft.autoStartEnabled,
    );
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<void> stopSoundPreview() async {}

  @override
  Future<void> storeDraft(RhythmSettingsDraft draft) async {}

  @override
  Future<PreferencesCommandResult> toggleMute() async {
    preferences = preferences.toggleMute(
      UnmuteSoundBehavior.restorePreviousSelection,
    );
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> useBundledSound() async {
    preferences = preferences.changeNotificationSound(
      preferences.notificationSound.useBundledDefault(),
    );
    return PreferencesCommandResult(preferences: preferences);
  }
}
