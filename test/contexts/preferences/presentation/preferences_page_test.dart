import 'dart:async';

import 'package:clock_rhythm/contexts/preferences/public.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'LB-003 disclosure toggles editable Rhythm Settings while sound controls remain available',
    (WidgetTester tester) async {
      final FakeWidgetPreferencesActions actions =
          FakeWidgetPreferencesActions();
      _replacePreferences(
        actions,
        UserPreferences.defaults().completeInitialSetup(),
      );
      await tester.pumpWidget(
        _testApp(
          actions: actions,
          capabilities: PreferencesPlatformCapabilities.windows,
        ),
      );
      await tester.pumpAndSettle();

      final Finder disclosure = find.byKey(
        const ValueKey<String>('rhythm-settings-disclosure'),
      );
      final Finder startInput = find.byKey(
        const ValueKey<String>('clock-time-Focus window start'),
      );
      final Finder soundPanel = find.byKey(
        const ValueKey<String>('notification-sound-panel'),
      );
      expect(startInput, findsOneWidget);

      await tester.tap(disclosure);
      await tester.pumpAndSettle();

      expect(startInput, findsNothing);
      expect(soundPanel, findsOneWidget);

      await tester.tap(disclosure);
      await tester.pumpAndSettle();

      expect(startInput, findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(soundPanel, findsOneWidget);
    },
  );

  testWidgets(
    'LB-008 start and end inputs preserve exact 24-hour HH:mm values in both locales',
    (WidgetTester tester) async {
      const List<({Locale locale, String startLabel, String endLabel})> cases =
          <({Locale locale, String startLabel, String endLabel})>[
            (
              locale: Locale('en'),
              startLabel: 'Focus window start',
              endLabel: 'Focus window end',
            ),
            (
              locale: Locale('ko'),
              startLabel: '집중 시간대 시작',
              endLabel: '집중 시간대 종료',
            ),
          ];

      for (final ({Locale locale, String startLabel, String endLabel}) testCase
          in cases) {
        await tester.pumpWidget(
          _testApp(
            actions: FakeWidgetPreferencesActions(),
            capabilities: PreferencesPlatformCapabilities.windows,
            locale: testCase.locale,
          ),
        );
        await tester.pumpAndSettle();

        final TextField start = tester.widget<TextField>(
          find.byKey(ValueKey<String>('clock-time-${testCase.startLabel}')),
        );
        final TextField end = tester.widget<TextField>(
          find.byKey(ValueKey<String>('clock-time-${testCase.endLabel}')),
        );
        expect(start.controller!.text, '05:00');
        expect(end.controller!.text, '18:00');
        expect(start.keyboardType, TextInputType.datetime);
        expect(end.keyboardType, TextInputType.datetime);
        expect(find.textContaining('AM'), findsNothing);
        expect(find.textContaining('PM'), findsNothing);
        expect(find.textContaining('오전'), findsNothing);
        expect(find.textContaining('오후'), findsNothing);

        await tester.tap(
          find.byKey(
            ValueKey<String>('clock-time-picker-${testCase.startLabel}'),
          ),
        );
        await tester.pumpAndSettle();
        final Finder picker = find.byType(TimePickerDialog);
        expect(picker, findsOneWidget);
        expect(
          MediaQuery.of(tester.element(picker)).alwaysUse24HourFormat,
          isTrue,
        );
        Navigator.of(tester.element(picker)).pop();
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  testWidgets(
    'LB-009 direct time input takes focus and marks the valid edit as unsaved',
    (WidgetTester tester) async {
      final FakeWidgetPreferencesActions actions =
          FakeWidgetPreferencesActions();
      await tester.pumpWidget(
        _testApp(
          actions: actions,
          capabilities: PreferencesPlatformCapabilities.windows,
        ),
      );
      await tester.pumpAndSettle();

      final Finder startInput = find.byKey(
        const ValueKey<String>('clock-time-Focus window start'),
      );
      await tester.tap(startInput);
      await tester.pump();

      final EditableText editable = tester.widget<EditableText>(
        find.descendant(of: startInput, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.enterText(startInput, '23:00');
      await tester.pumpAndSettle();

      expect(actions.draft.snapshot().dailyStart, '23:00');
      expect(
        actions.preferences.rhythmConfiguration.dailyRhythm.start.text,
        '05:00',
      );
      expect(
        find.byKey(const ValueKey<String>('rhythm-summary-dirty')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Windows exposes desktop-only settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        actions: FakeWidgetPreferencesActions(),
        capabilities: PreferencesPlatformCapabilities.windows,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('auto-start-control')), findsOne);
    expect(
      find.byKey(const ValueKey<String>('permission-status-panel')),
      findsNothing,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('choose-custom-sound')), findsOne);
    expect(find.byKey(const ValueKey<String>('sound-volume')), findsOne);
  });

  testWidgets(
    'LB-015 zero volume warns while the audible sound remains unmuted',
    (WidgetTester tester) async {
      final FakeWidgetPreferencesActions actions =
          FakeWidgetPreferencesActions();
      _replacePreferences(actions, UserPreferences.defaults().changeVolume(0));
      await tester.pumpWidget(
        _testApp(
          actions: actions,
          capabilities: PreferencesPlatformCapabilities.windows,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(
        actions.preferences.notificationSound.mode,
        NotificationSoundMode.bundledDefault,
      );
      expect(
        find.byKey(const ValueKey<String>('zero-volume-warning')),
        findsOneWidget,
      );
      expect(
        find.text('Volume is 0%. Notifications remain visible.'),
        findsOneWidget,
      );
      final OutlinedButton preview = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey<String>('sound-preview-control')),
      );
      expect(preview.onPressed, isNull);
    },
  );

  testWidgets('LB-016 sound preview failure is rendered as localized feedback', (
    WidgetTester tester,
  ) async {
    final FakeWidgetPreferencesActions actions = FakeWidgetPreferencesActions()
      ..failPreview = true;
    await tester.pumpWidget(
      _testApp(
        actions: actions,
        capabilities: PreferencesPlatformCapabilities.windows,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final Finder preview = find.byKey(
      const ValueKey<String>('sound-preview-control'),
    );
    await tester.ensureVisible(preview);
    await tester.pumpAndSettle();
    await tester.tap(preview);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('sound-operation-failure')),
      findsOneWidget,
    );
    expect(
      find.text(
        'The custom sound could not be played. The bundled sound was used for this event.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'LB-095 Preferences presents Rhythm Settings and sound controls in one scrollable view',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(
          actions: FakeWidgetPreferencesActions(),
          capabilities: PreferencesPlatformCapabilities.windows,
        ),
      );
      await tester.pumpAndSettle();

      final ListView preferencesViewport = tester.widget<ListView>(
        find.byType(ListView),
      );
      final SliverChildListDelegate childrenDelegate =
          preferencesViewport.childrenDelegate as SliverChildListDelegate;
      expect(
        childrenDelegate.children.whereType<RhythmSettingsPanel>(),
        hasLength(1),
      );
      expect(
        childrenDelegate.children.whereType<NotificationSoundPanel>(),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'LB-096 collapsed summary describes the saved rhythm and notification settings',
    (WidgetTester tester) async {
      final FakeWidgetPreferencesActions actions =
          FakeWidgetPreferencesActions();
      _replacePreferences(
        actions,
        UserPreferences.defaults().completeInitialSetup(),
      );
      await tester.pumpWidget(
        _testApp(
          actions: actions,
          capabilities: PreferencesPlatformCapabilities.windows,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('rhythm-settings-disclosure')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('50 min focus · 10 min rest · 05:00-18:00 · Default'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('clock-time-Focus window start')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'LB-097 summary keeps both unsaved and invalid warnings visible',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(
          actions: FakeWidgetPreferencesActions(),
          capabilities: PreferencesPlatformCapabilities.windows,
        ),
      );
      await tester.pumpAndSettle();

      final Finder focusInput = find.byKey(
        const ValueKey<String>('duration-Focus Interval'),
      );
      await tester.enterText(focusInput, '40');
      await tester.pumpAndSettle();
      await tester.enterText(focusInput, '181');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('rhythm-summary-dirty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('rhythm-summary-invalid')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'LB-098 collapsed summary keeps the durable Mute warning visible',
    (WidgetTester tester) async {
      final FakeWidgetPreferencesActions actions =
          FakeWidgetPreferencesActions();
      final UserPreferences muted = UserPreferences.defaults()
          .toggleMute(UnmuteSoundBehavior.restorePreviousSelection)
          .completeInitialSetup();
      _replacePreferences(actions, muted);
      await tester.pumpWidget(
        _testApp(
          actions: actions,
          capabilities: PreferencesPlatformCapabilities.windows,
          home: PreferencesPage(now: () => DateTime(2026, 6, 2, 23)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('rhythm-settings-disclosure')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('50 min focus · 10 min rest · 05:00-18:00 · Muted'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('rhythm-settings-next-event')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('rhythm-summary-outside-window')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('clock-time-Focus window start')),
        findsNothing,
      );
    },
  );

  testWidgets('Android hides desktop controls and warns below nine minutes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        actions: FakeWidgetPreferencesActions(),
        capabilities: PreferencesPlatformCapabilities.android,
        permissionActions: FakeDeliveryPermissionActions(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('auto-start-control')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('choose-custom-sound')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('sound-volume')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('duration-Focus Interval')),
      '8',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('deep-idle-warning')), findsOne);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('permission-status-panel')),
      findsOne,
    );
  });

  testWidgets('first setup stays expanded and permits the first clean save', (
    WidgetTester tester,
  ) async {
    final FakeWidgetPreferencesActions actions = FakeWidgetPreferencesActions();
    await tester.pumpWidget(
      _testApp(
        actions: actions,
        capabilities: PreferencesPlatformCapabilities.windows,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('rhythm-settings-disclosure')),
      findsNothing,
    );
    final FilledButton save = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('save-rhythm-settings')),
    );
    expect(save.onPressed, isNotNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('save-rhythm-settings')),
    );
    await tester.pumpAndSettle();

    expect(actions.preferences.initialSetupCompleted, isTrue);
    expect(
      find.byKey(const ValueKey<String>('rhythm-settings-disclosure')),
      findsOne,
    );
  });

  testWidgets('invalid raw time survives restoration and keeps save disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        actions: FakeWidgetPreferencesActions(),
        capabilities: PreferencesPlatformCapabilities.windows,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('clock-time-Focus window start')),
      '7:00',
    );
    await tester.pump();
    await tester.restartAndRestore();
    await tester.pumpAndSettle();

    expect(find.text('7:00'), findsOne);
    expect(
      find.text('Enter a time from 00:00 to 23:59 in HH:mm format.'),
      findsOne,
    );
    final FilledButton save = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('save-rhythm-settings')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('discard resets a valid dirty draft to durable settings', (
    WidgetTester tester,
  ) async {
    final FakeWidgetPreferencesActions actions = FakeWidgetPreferencesActions();
    await tester.pumpWidget(
      _testApp(
        actions: actions,
        capabilities: PreferencesPlatformCapabilities.windows,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('duration-Focus Interval')),
      '40',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('rhythm-summary-dirty')),
      findsOne,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('discard-rhythm-settings')),
    );
    await tester.pumpAndSettle();

    expect(find.text('50'), findsOne);
    expect(
      find.byKey(const ValueKey<String>('rhythm-summary-dirty')),
      findsNothing,
    );
  });

  testWidgets('provider reload replaces mounted raw draft after import', (
    WidgetTester tester,
  ) async {
    final FakeWidgetPreferencesActions actions = FakeWidgetPreferencesActions();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        preferencesActionsProvider.overrideWithValue(actions),
        preferencesPlatformCapabilitiesProvider.overrideWithValue(
          PreferencesPlatformCapabilities.windows,
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _testApp(
        actions: actions,
        capabilities: PreferencesPlatformCapabilities.windows,
        container: container,
      ),
    );
    await tester.pumpAndSettle();
    final Finder focusField = find.byKey(
      const ValueKey<String>('duration-Focus Interval'),
    );
    await tester.enterText(focusField, '40');
    await tester.pumpAndSettle();

    final RhythmSettingsDraft importedDraft =
        RhythmSettingsDraft.fromPreferences(
          actions.preferences,
        ).changeFocusMinutes(25);
    actions.preferences = actions.preferences.applyRhythmSettings(
      configuration: importedDraft.rhythmConfiguration,
      autoStartEnabled: importedDraft.autoStartEnabled,
    );
    actions.draft = RhythmSettingsDraft.fromPreferences(actions.preferences);
    container.invalidate(preferencesViewModelProvider);
    await tester.pump();
    await tester.pumpAndSettle();

    final TextField reloadedField = tester.widget<TextField>(focusField);
    expect(reloadedField.controller!.text, '25');
    expect(
      container
          .read(preferencesViewModelProvider)
          .requireValue
          .draft
          .rhythmConfiguration
          .focusDuration
          .minutes,
      25,
    );
  });

  testWidgets(
    'compact Android settings keep actions usable at 200-percent text',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _testApp(
          actions: FakeWidgetPreferencesActions(),
          capabilities: PreferencesPlatformCapabilities.android,
          permissionActions: FakeDeliveryPermissionActions(),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final Finder save = find.byKey(
        const ValueKey<String>('save-rhythm-settings'),
      );
      await tester.ensureVisible(save);
      expect(save, findsOneWidget);
      expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
    },
  );

  testWidgets('minimum Windows layout remains usable at 200-percent text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(720, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _testApp(
        actions: FakeWidgetPreferencesActions(),
        capabilities: PreferencesPlatformCapabilities.windows,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey<String>('sound-volume')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('choose-custom-sound')),
      findsOneWidget,
    );
  });

  testWidgets('compact theme grid remains usable at 200-percent text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _testApp(
        actions: FakeWidgetPreferencesActions(),
        capabilities: PreferencesPlatformCapabilities.android,
        textScaler: const TextScaler.linear(2),
        home: const ThemePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey<String>('theme-current')), findsOneWidget);
  });

  testWidgets('settings actions meet target-size and label guidelines', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _testApp(
        actions: FakeWidgetPreferencesActions(),
        capabilities: PreferencesPlatformCapabilities.android,
        permissionActions: FakeDeliveryPermissionActions(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('theme choices meet target-size and label guidelines', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _testApp(
        actions: FakeWidgetPreferencesActions(),
        capabilities: PreferencesPlatformCapabilities.android,
        home: const ThemePage(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}

Widget _testApp({
  required FakeWidgetPreferencesActions actions,
  required PreferencesPlatformCapabilities capabilities,
  DeliveryPermissionActions? permissionActions,
  ProviderContainer? container,
  TextScaler textScaler = TextScaler.noScaling,
  Widget home = const PreferencesPage(),
  Locale locale = const Locale('en'),
}) {
  final Widget app = MaterialApp(
    restorationScopeId: 'preferences-test-app',
    locale: locale,
    supportedLocales: LanguageLocaleMapper.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(body: home),
  );
  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(
    overrides: [
      preferencesActionsProvider.overrideWithValue(actions),
      preferencesPlatformCapabilitiesProvider.overrideWithValue(capabilities),
      deliveryPermissionActionsProvider.overrideWithValue(permissionActions),
    ],
    child: app,
  );
}

void _replacePreferences(
  FakeWidgetPreferencesActions actions,
  UserPreferences preferences,
) {
  actions.preferences = preferences;
  actions.draft = RhythmSettingsDraft.fromPreferences(preferences);
}

final class FakeWidgetPreferencesActions implements PreferencesActions {
  FakeWidgetPreferencesActions()
    : preferences = UserPreferences.defaults(),
      draft = RhythmSettingsDraft.fromPreferences(UserPreferences.defaults());

  UserPreferences preferences;
  RhythmSettingsDraft draft;
  bool failPreview = false;
  final Completer<void> previewCompletion = Completer<void>();

  @override
  Future<PreferencesInitialData> load() async {
    return PreferencesInitialData(preferences: preferences, draft: draft);
  }

  @override
  Stream<Set<PreferencesRepairNeed>> watchRepairNeeds() {
    return const Stream<Set<PreferencesRepairNeed>>.empty();
  }

  @override
  Future<void> storeDraft(RhythmSettingsDraft next) async {
    draft = next;
  }

  @override
  Future<RhythmSettingsDraft> discardDraft() async {
    draft = RhythmSettingsDraft.fromPreferences(preferences);
    return draft;
  }

  @override
  Future<PreferencesCommandResult> saveRhythm(RhythmSettingsDraft next) async {
    preferences = preferences.applyRhythmSettings(
      configuration: next.rhythmConfiguration,
      autoStartEnabled: next.autoStartEnabled,
    );
    draft = RhythmSettingsDraft.fromPreferences(preferences);
    return PreferencesCommandResult(preferences: preferences);
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
  Future<PreferencesCommandResult> useBundledSound() async {
    preferences = preferences.changeNotificationSound(
      preferences.notificationSound.useBundledDefault(),
    );
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> chooseCustomSound() async {
    preferences = preferences.changeNotificationSound(
      NotificationSoundPreference.custom(
        fileName: 'chosen.mp3',
        privateSource: 'private/chosen.mp3',
      ),
    );
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> changeVolume(double volume) async {
    preferences = preferences.changeVolume(volume);
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> toggleMute() async {
    preferences = preferences.toggleMute(
      UnmuteSoundBehavior.restorePreviousSelection,
    );
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<SoundPreviewPlayback> previewSound() async {
    if (failPreview) {
      throw StateError('preview failed');
    }
    return SoundPreviewPlayback(completed: previewCompletion.future);
  }

  @override
  Future<void> stopSoundPreview() async {}

  @override
  Future<PreferencesCommandResult> repairEffect(
    PreferencesChangeImpact impact,
  ) async {
    return PreferencesCommandResult(preferences: preferences);
  }

  @override
  Future<PreferencesCommandResult> repairAutoStart() async {
    return PreferencesCommandResult(preferences: preferences);
  }
}

final class FakeDeliveryPermissionActions implements DeliveryPermissionActions {
  @override
  Future<DeliveryPermissionSnapshot> load() async {
    return const DeliveryPermissionSnapshot(
      notificationGranted: false,
      exactAlarmGranted: false,
    );
  }

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> openNotificationSettings() async {}
}
