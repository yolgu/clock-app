import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/preferences_changed_port.dart';
import '../application/preferences_command_result.dart';
import '../domain/language_preference.dart';
import '../domain/theme_preference.dart';
import '../domain/user_preferences.dart';
import 'preferences_actions.dart';
import 'preferences_dependencies.dart';

enum PreferencesOperation {
  idle,
  storingDraft,
  savingRhythm,
  changingImmediateSetting,
  previewingSound,
  stoppingSoundPreview,
}

enum PreferencesFeedback { none, saved, discarded, failed }

enum PreferencesFailure {
  none,
  draftStore,
  rhythmSave,
  language,
  theme,
  sound,
  volume,
  preview,
}

final class PreferencesDataState {
  PreferencesDataState({
    required this.preferences,
    this.operation = PreferencesOperation.idle,
    this.feedback = PreferencesFeedback.none,
    this.failure = PreferencesFailure.none,
    Set<PreferencesRepairNeed> repairNeeds = const <PreferencesRepairNeed>{},
  }) : repairNeeds = Set<PreferencesRepairNeed>.unmodifiable(repairNeeds);
  final UserPreferences preferences;
  final PreferencesOperation operation;
  final PreferencesFeedback feedback;
  final PreferencesFailure failure;
  final Set<PreferencesRepairNeed> repairNeeds;
  bool get isBusy => operation != PreferencesOperation.idle;

  PreferencesDataState copyWith({
    UserPreferences? preferences,
    PreferencesOperation? operation,
    PreferencesFeedback? feedback,
    PreferencesFailure? failure,
    Set<PreferencesRepairNeed>? repairNeeds,
  }) => PreferencesDataState(
    preferences: preferences ?? this.preferences,
    operation: operation ?? this.operation,
    feedback: feedback ?? this.feedback,
    failure: failure ?? this.failure,
    repairNeeds: repairNeeds ?? this.repairNeeds,
  );
}

final AsyncNotifierProvider<PreferencesDataController, PreferencesDataState>
preferencesDataControllerProvider =
    AsyncNotifierProvider<PreferencesDataController, PreferencesDataState>(
      PreferencesDataController.new,
    );

final class PreferencesDataController
    extends AsyncNotifier<PreferencesDataState> {
  PreferencesActions get _actions => ref.read(preferencesActionsProvider);

  @override
  Future<PreferencesDataState> build() async {
    final PreferencesInitialData initial = await ref.watch(
      preferencesInitialDataProvider.future,
    );
    Set<PreferencesRepairNeed> initialRepairNeeds = initial.repairNeeds;
    final StreamSubscription<Set<PreferencesRepairNeed>> subscription = _actions
        .watchRepairNeeds()
        .listen((Set<PreferencesRepairNeed> needs) {
          initialRepairNeeds = needs;
          final PreferencesDataState? current = state.value;
          if (current != null &&
              (current.repairNeeds.length != needs.length ||
                  !current.repairNeeds.containsAll(needs))) {
            state = AsyncData<PreferencesDataState>(
              current.copyWith(repairNeeds: needs),
            );
          }
        });
    ref.onDispose(() {
      unawaited(subscription.cancel());
    });
    return PreferencesDataState(
      preferences: initial.preferences,
      repairNeeds: initialRepairNeeds,
    );
  }

  PreferencesDataState? beginOperation(
    PreferencesOperation operation, {
    bool preserveFeedback = false,
  }) {
    final PreferencesDataState? current = state.value;
    final bool continuesDraft =
        operation == PreferencesOperation.storingDraft &&
        current?.operation == operation;
    if (current == null || (current.isBusy && !continuesDraft)) {
      return null;
    }
    state = AsyncData<PreferencesDataState>(
      current.copyWith(
        operation: operation,
        feedback: preserveFeedback
            ? current.feedback
            : PreferencesFeedback.none,
        failure: PreferencesFailure.none,
      ),
    );
    return current;
  }

  void finishOperation({
    PreferencesFeedback? feedback,
    PreferencesFailure? failure,
  }) {
    if (!ref.mounted) {
      return;
    }
    final PreferencesDataState current = state.requireValue;
    state = AsyncData<PreferencesDataState>(
      current.copyWith(
        operation: PreferencesOperation.idle,
        feedback: feedback,
        failure: failure,
      ),
    );
  }

  void reportFailure(PreferencesFailure failure) {
    finishOperation(feedback: PreferencesFeedback.failed, failure: failure);
  }

  void reportBackgroundFailure(PreferencesFailure failure) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData<PreferencesDataState>(
      state.requireValue.copyWith(
        feedback: PreferencesFeedback.failed,
        failure: failure,
      ),
    );
  }

  void acceptCommand(
    PreferencesCommandResult result, {
    required Set<PreferencesRepairNeed> resolves,
    PreferencesFeedback? feedback,
    PreferencesFailure? failure,
  }) {
    if (!ref.mounted) {
      return;
    }
    final PreferencesDataState current = state.requireValue;
    state = AsyncData<PreferencesDataState>(
      current.copyWith(
        preferences: result.preferences,
        operation: PreferencesOperation.idle,
        feedback: feedback,
        failure: failure,
        repairNeeds: <PreferencesRepairNeed>{
          ...current.repairNeeds.where(
            (PreferencesRepairNeed need) => !resolves.contains(need),
          ),
          ...result.repairNeeds,
        },
      ),
    );
  }

  Future<bool> applyImmediate(
    Future<PreferencesCommandResult> Function() command, {
    required PreferencesFailure failure,
    required Set<PreferencesRepairNeed> resolves,
  }) async {
    if (beginOperation(PreferencesOperation.changingImmediateSetting) == null) {
      return false;
    }
    try {
      final PreferencesCommandResult result = await command();
      acceptCommand(result, resolves: resolves);
      return true;
    } on Object {
      reportFailure(failure);
      return false;
    }
  }

  Future<void> changeLanguage(LanguagePreference language) async {
    await applyImmediate(
      () => _actions.changeLanguage(language),
      failure: PreferencesFailure.language,
      resolves: const <PreferencesRepairNeed>{
        PreferencesRepairNeed.notificationPayload,
      },
    );
  }

  Future<void> changeTheme(ThemePreference theme) async {
    await applyImmediate(
      () => _actions.changeTheme(theme),
      failure: PreferencesFailure.theme,
      resolves: const <PreferencesRepairNeed>{PreferencesRepairNeed.visual},
    );
  }

  Future<void> repairEffect(PreferencesRepairNeed need) async {
    final PreferencesChangeImpact impact = switch (need) {
      PreferencesRepairNeed.visual => PreferencesChangeImpact.visual,
      PreferencesRepairNeed.sound => PreferencesChangeImpact.sound,
      PreferencesRepairNeed.notificationPayload =>
        PreferencesChangeImpact.notificationPayload,
      PreferencesRepairNeed.rhythmSchedule =>
        PreferencesChangeImpact.rhythmSchedule,
      PreferencesRepairNeed.autoStart || PreferencesRepairNeed.draft =>
        throw ArgumentError.value(need, 'need', 'uses a dedicated repair path'),
    };
    await applyImmediate(
      () => _actions.repairEffect(impact),
      failure: need == PreferencesRepairNeed.visual
          ? PreferencesFailure.theme
          : PreferencesFailure.sound,
      resolves: <PreferencesRepairNeed>{need},
    );
  }

  Future<void> repairAutoStart() async {
    await applyImmediate(
      _actions.repairAutoStart,
      failure: PreferencesFailure.rhythmSave,
      resolves: const <PreferencesRepairNeed>{PreferencesRepairNeed.autoStart},
    );
  }

  Future<void> recoverFailedSave(PreferencesDataState beforeSave) async {
    try {
      final PreferencesInitialData loaded = await _actions.load();
      if (!ref.mounted) {
        return;
      }
      state = AsyncData<PreferencesDataState>(
        PreferencesDataState(
          preferences: loaded.preferences,
          feedback: PreferencesFeedback.failed,
          failure: PreferencesFailure.rhythmSave,
          repairNeeds: loaded.repairNeeds,
        ),
      );
    } on Object {
      if (ref.mounted) {
        state = AsyncData<PreferencesDataState>(
          beforeSave.copyWith(
            operation: PreferencesOperation.idle,
            feedback: PreferencesFeedback.failed,
            failure: PreferencesFailure.rhythmSave,
          ),
        );
      }
    }
  }
}
