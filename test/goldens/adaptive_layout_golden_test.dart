import 'package:clock_rhythm/app/presentation/android_bottom_navigation.dart';
import 'package:clock_rhythm/app/presentation/app_navigation_copy.dart';
import 'package:clock_rhythm/app/presentation/clock_page.dart';
import 'package:clock_rhythm/app/presentation/windows_top_navigation.dart';
import 'package:clock_rhythm/contexts/preferences/public.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart';
import 'package:clock_rhythm/contexts/todo/public.dart';
import 'package:clock_rhythm/contexts/todo/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contexts/rhythm/presentation/support/fake_rhythm_actions.dart';
import '../contexts/todo/presentation/support/todo_presentation_test_support.dart';

void main() {
  testWidgets('compact Korean calendar at 200-percent text', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(360, 800));
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'open', title: '길어도 읽을 수 있는 오늘의 할 일', time: '08:30'),
      createTestTodo(
        id: 'done',
        title: '완료한 할 일',
        displayOrder: 1,
        completed: true,
      ),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(
      DateTime(2026, 6, 2, 10),
    );
    addTearDown(dateClock.dispose);

    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        locale: const Locale('ko'),
        textScaler: const TextScaler.linear(2),
        theme: ClockRhythmTheme.build(
          ThemeCatalog.resolve(ThemePreference.current),
        ),
        child: const RepaintBoundary(
          key: ValueKey<String>('golden-surface'),
          child: CalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('golden-surface')),
      matchesGoldenFile('baselines/compact_calendar_ko_200.png'),
    );
  });

  testWidgets('wide English calendar in Neon Dusk', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1280, 800));
    final TestTodoRepository repository = TestTodoRepository(<Todo>[
      createTestTodo(id: 'open', title: 'Prepare release evidence'),
      createTestTodo(
        id: 'done',
        title: 'Verify portable backup',
        displayOrder: 1,
        completed: true,
      ),
    ]);
    final TestTodoDateClock dateClock = TestTodoDateClock(
      DateTime(2026, 6, 2, 10),
    );
    addTearDown(dateClock.dispose);

    await tester.pumpWidget(
      buildTodoTestApp(
        repository: repository,
        dateClock: dateClock,
        theme: ClockRhythmTheme.build(
          ThemeCatalog.resolve(ThemePreference.monokaiPro),
        ),
        child: const RepaintBoundary(
          key: ValueKey<String>('golden-surface'),
          child: CalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('golden-surface')),
      matchesGoldenFile('baselines/wide_calendar_en_neon_dusk.png'),
    );
  });

  testWidgets('wide Windows Clock uses the current design tokens', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1280, 800));
    final _GoldenPreferencesActions preferences = _GoldenPreferencesActions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesActionsProvider.overrideWithValue(preferences),
          preferencesPlatformCapabilitiesProvider.overrideWithValue(
            PreferencesPlatformCapabilities.windows,
          ),
          rhythmActionsProvider.overrideWithValue(FakeRhythmActions()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ClockRhythmTheme.build(
            ThemeCatalog.resolve(ThemePreference.current),
            platform: TargetPlatform.windows,
          ),
          home: Builder(
            builder: (BuildContext context) {
              return RepaintBoundary(
                key: const ValueKey<String>('golden-surface'),
                child: Scaffold(
                  body: Column(
                    children: <Widget>[
                      WindowsTopNavigation(
                        selectedIndex: 0,
                        onDestinationSelected: (_) {},
                        copy: AppNavigationCopy.fromContext(context),
                      ),
                      Expanded(
                        child: ClockPage(
                          now: () => DateTime(2026, 6, 2, 9, 41),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('golden-surface')),
      matchesGoldenFile('baselines/windows_clock_en_current.png'),
    );
  });

  testWidgets('compact Android Theme uses the current design tokens', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(360, 800));
    final _GoldenPreferencesActions preferences = _GoldenPreferencesActions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesActionsProvider.overrideWithValue(preferences),
          preferencesPlatformCapabilitiesProvider.overrideWithValue(
            PreferencesPlatformCapabilities.android,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ClockRhythmTheme.build(
            ThemeCatalog.resolve(ThemePreference.current),
            platform: TargetPlatform.android,
          ),
          home: Builder(
            builder: (BuildContext context) {
              return RepaintBoundary(
                key: const ValueKey<String>('golden-surface'),
                child: Scaffold(
                  body: const ThemePage(),
                  bottomNavigationBar: AndroidBottomNavigation(
                    selectedIndex: 3,
                    onDestinationSelected: (_) {},
                    copy: AppNavigationCopy.fromContext(context),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('golden-surface')),
      matchesGoldenFile('baselines/android_theme_ko_current.png'),
    );
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

final class _GoldenPreferencesActions implements PreferencesActions {
  _GoldenPreferencesActions()
    : preferences = UserPreferences.defaults().completeInitialSetup();

  UserPreferences preferences;

  RhythmSettingsDraft get _draft {
    return RhythmSettingsDraft.fromPreferences(preferences);
  }

  PreferencesCommandResult get _result {
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesInitialData> load() async {
    return PreferencesInitialData(preferences: preferences, draft: _draft);
  }

  @override
  Stream<Set<PreferencesRepairNeed>> watchRepairNeeds() {
    return const Stream<Set<PreferencesRepairNeed>>.empty();
  }

  @override
  Future<void> storeDraft(RhythmSettingsDraft draft) async {}

  @override
  Future<RhythmSettingsDraft> discardDraft() async => _draft;

  @override
  Future<PreferencesCommandResult> saveRhythm(RhythmSettingsDraft draft) async {
    preferences = preferences.applyRhythmSettings(
      configuration: draft.rhythmConfiguration,
      autoStartEnabled: draft.autoStartEnabled,
    );
    return _result;
  }

  @override
  Future<PreferencesCommandResult> changeLanguage(
    LanguagePreference language,
  ) async {
    preferences = preferences.changeLanguage(language);
    return _result;
  }

  @override
  Future<PreferencesCommandResult> changeTheme(ThemePreference theme) async {
    preferences = preferences.changeTheme(theme);
    return _result;
  }

  @override
  Future<PreferencesCommandResult> useBundledSound() async => _result;

  @override
  Future<PreferencesCommandResult> chooseCustomSound() async => _result;

  @override
  Future<PreferencesCommandResult> changeVolume(double volume) async {
    preferences = preferences.changeVolume(volume);
    return _result;
  }

  @override
  Future<PreferencesCommandResult> toggleMute() async => _result;

  @override
  Future<SoundPreviewPlayback> previewSound() async {
    return SoundPreviewPlayback(completed: Future<void>.value());
  }

  @override
  Future<void> stopSoundPreview() async {}

  @override
  Future<PreferencesCommandResult> repairEffect(
    PreferencesChangeImpact impact,
  ) async {
    return _result;
  }

  @override
  Future<PreferencesCommandResult> repairAutoStart() async => _result;
}
