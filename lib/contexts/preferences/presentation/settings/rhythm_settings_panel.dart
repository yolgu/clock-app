import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/i18n/public.dart';
import '../../../../shared/ui/public.dart' show SemanticStatusAnnouncement;
import '../../../rhythm/public_model.dart';
import '../../application/preferences_command_result.dart';
import '../../domain/language_preference.dart';
import '../../domain/rhythm_settings_draft.dart';
import '../preferences_platform_capabilities.dart';
import '../preferences_providers.dart';
import '../preferences_view_state.dart';
import 'clock_time_field.dart';
import 'duration_field.dart';
import 'rhythm_settings_form_input.dart';
import 'rhythm_settings_summary.dart';

final class RhythmSettingsPanel extends ConsumerStatefulWidget {
  const RhythmSettingsPanel({this.now = DateTime.now, super.key});

  final DateTime Function() now;

  @override
  ConsumerState<RhythmSettingsPanel> createState() =>
      _RhythmSettingsPanelState();
}

final class _RhythmSettingsPanelState extends ConsumerState<RhythmSettingsPanel>
    with RestorationMixin {
  final RestorableTextEditingController _focus =
      RestorableTextEditingController();
  final RestorableTextEditingController _rest =
      RestorableTextEditingController();
  final RestorableTextEditingController _start =
      RestorableTextEditingController();
  final RestorableTextEditingController _end =
      RestorableTextEditingController();
  final RestorableBool _autoStart = RestorableBool(false);
  final RestorableBool _expanded = RestorableBool(true);
  final RestorableBool _hasEdited = RestorableBool(false);

  RhythmSettingsFormResult? _validation;
  bool _initialized = false;
  bool _restoredFromBucket = false;
  PreferencesFeedback? _lastFeedback;

  @override
  String? get restorationId => 'rhythm_settings_panel';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_focus, 'focus_minutes');
    registerForRestoration(_rest, 'rest_minutes');
    registerForRestoration(_start, 'daily_start');
    registerForRestoration(_end, 'daily_end');
    registerForRestoration(_autoStart, 'auto_start');
    registerForRestoration(_expanded, 'expanded');
    registerForRestoration(_hasEdited, 'has_edited');
    _restoredFromBucket = _hasEdited.value;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PreferencesViewState>>(
      preferencesViewModelProvider,
      _handlePreferencesTransition,
    );
    final AsyncValue<PreferencesViewState> value = ref.watch(
      preferencesViewModelProvider,
    );
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Center(
        child: Text(AppLocalizations.of(context).messagePreferencesFailed),
      ),
      data: (PreferencesViewState state) {
        _scheduleSynchronization(state);
        return _buildPanel(context, state);
      },
    );
  }

  Widget _buildPanel(BuildContext context, PreferencesViewState state) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final PreferencesPlatformCapabilities capabilities = ref.watch(
      preferencesPlatformCapabilitiesProvider,
    );
    final bool mustStayExpanded = !state.preferences.initialSetupCompleted;
    final bool showsBody = mustStayExpanded || _expanded.value;
    final RhythmSettingsFormResult validation =
        _validation ?? _input().validate();
    final bool hasInvalidInput = !validation.isValid;
    final int? focusMinutes = int.tryParse(_focus.value.text);
    final int? restMinutes = int.tryParse(_rest.value.text);
    final bool showsDeepIdleWarning =
        capabilities.kind == PreferencesPlatformKind.android &&
        ((focusMinutes != null && focusMinutes < 9) ||
            (restMinutes != null && restMinutes < 9));

    return Card(
      key: const ValueKey<String>('rhythm-settings-panel'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.rhythmSettingsDisclosureTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      RhythmSettingsSummary(
                        state: state,
                        hasInvalidInput: hasInvalidInput,
                        observedAt: widget.now(),
                      ),
                    ],
                  ),
                ),
                if (!mustStayExpanded)
                  IconButton(
                    key: const ValueKey<String>('rhythm-settings-disclosure'),
                    tooltip: showsBody
                        ? copy.rhythmSettingsDisclosureCollapse
                        : copy.rhythmSettingsDisclosureExpand,
                    onPressed: () {
                      setState(() => _expanded.value = !_expanded.value);
                    },
                    icon: Icon(
                      showsBody ? Icons.expand_less : Icons.expand_more,
                    ),
                  ),
              ],
            ),
            if (showsBody) ...<Widget>[
              const SizedBox(height: 16),
              DurationField(
                label: copy.rhythmSettingsFocusMinutes,
                controller: _focus.value,
                minimum: DurationMinutes.minimum,
                maximum: DurationMinutes.maximumFocus,
                errorText:
                    validation.errors.contains(RhythmSettingsFieldError.focus)
                    ? copy.rhythmSettingsMinuteRange(
                        DurationMinutes.minimum,
                        DurationMinutes.maximumFocus,
                      )
                    : null,
                enabled: !state.isBusy,
                onChanged: (_) => _markEditedAndValidate(),
              ),
              const SizedBox(height: 8),
              DurationField(
                label: copy.rhythmSettingsRestMinutes,
                controller: _rest.value,
                minimum: DurationMinutes.minimum,
                maximum: DurationMinutes.maximumRest,
                errorText:
                    validation.errors.contains(RhythmSettingsFieldError.rest)
                    ? copy.rhythmSettingsMinuteRange(
                        DurationMinutes.minimum,
                        DurationMinutes.maximumRest,
                      )
                    : null,
                enabled: !state.isBusy,
                onChanged: (_) => _markEditedAndValidate(),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClockTimeField(
                      label: copy.rhythmSettingsDailyStart,
                      pickerTooltip: copy.timePickerPlaceholder,
                      controller: _start.value,
                      errorText:
                          validation.errors.contains(
                            RhythmSettingsFieldError.start,
                          )
                          ? copy.timePickerInvalid
                          : null,
                      enabled: !state.isBusy,
                      onChanged: (_) => _markEditedAndValidate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClockTimeField(
                      label: copy.rhythmSettingsDailyEnd,
                      pickerTooltip: copy.timePickerPlaceholder,
                      controller: _end.value,
                      errorText:
                          validation.errors.contains(
                            RhythmSettingsFieldError.end,
                          )
                          ? copy.timePickerInvalid
                          : null,
                      enabled: !state.isBusy,
                      onChanged: (_) => _markEditedAndValidate(),
                    ),
                  ),
                ],
              ),
              if (validation.errors.contains(
                RhythmSettingsFieldError.dailyWindow,
              ))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    copy.rhythmSettingsNextEventUnavailable,
                    key: const ValueKey<String>('daily-window-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (capabilities.showsAutoStart)
                SwitchListTile(
                  key: const ValueKey<String>('auto-start-control'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.rhythmSettingsAutoStart),
                  value: _autoStart.value,
                  onChanged: state.isBusy
                      ? null
                      : (bool enabled) {
                          setState(() => _autoStart.value = enabled);
                          _markEditedAndValidate();
                        },
                ),
              if (showsDeepIdleWarning)
                ListTile(
                  key: const ValueKey<String>('deep-idle-warning'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber),
                  title: Text(copy.rhythmSettingsDeepIdleWarning(9)),
                ),
              DropdownButtonFormField<LanguagePreference>(
                key: const ValueKey<String>('language-control'),
                initialValue: state.preferences.language,
                decoration: InputDecoration(labelText: copy.languageLabel),
                items: <DropdownMenuItem<LanguagePreference>>[
                  DropdownMenuItem<LanguagePreference>(
                    value: LanguagePreference.korean,
                    child: Text(copy.languageKoreanName),
                  ),
                  DropdownMenuItem<LanguagePreference>(
                    value: LanguagePreference.english,
                    child: Text(copy.languageEnglishName),
                  ),
                ],
                onChanged: state.isBusy
                    ? null
                    : (LanguagePreference? language) {
                        if (language != null &&
                            language != state.preferences.language) {
                          ref
                              .read(preferencesViewModelProvider.notifier)
                              .changeLanguage(language);
                        }
                      },
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  TextButton(
                    key: const ValueKey<String>('discard-rhythm-settings'),
                    onPressed:
                        state.isBusy || (!state.isDirty && !hasInvalidInput)
                        ? null
                        : _discard,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(copy.rhythmSettingsDiscard),
                  ),
                  FilledButton(
                    key: const ValueKey<String>('save-rhythm-settings'),
                    onPressed:
                        state.isBusy ||
                            hasInvalidInput ||
                            (state.preferences.initialSetupCompleted &&
                                !state.isDirty)
                        ? null
                        : () {
                            ref
                                .read(preferencesViewModelProvider.notifier)
                                .saveRhythm();
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(copy.rhythmSettingsSave),
                  ),
                ],
              ),
              if (state.feedback == PreferencesFeedback.saved)
                SemanticStatusAnnouncement(
                  message: copy.announcementPreferencesSaved,
                  child: Text(
                    copy.messagePreferencesSaved,
                    key: const ValueKey<String>('preferences-saved-feedback'),
                  ),
                ),
              if (state.failure == PreferencesFailure.rhythmSave ||
                  state.failure == PreferencesFailure.draftStore ||
                  state.failure == PreferencesFailure.language)
                SemanticStatusAnnouncement(
                  message: copy.failurePreferencesSave,
                  child: Text(
                    copy.failurePreferencesSave,
                    key: const ValueKey<String>('preferences-failed-feedback'),
                  ),
                ),
              if (state.repairNeeds.contains(PreferencesRepairNeed.draft))
                ListTile(
                  key: const ValueKey<String>('draft-reset-repair'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.rhythmSettingsDraftResetFailed),
                  trailing: TextButton(
                    onPressed: state.isBusy
                        ? null
                        : () => ref
                              .read(preferencesViewModelProvider.notifier)
                              .repairDraftStore(),
                    child: Text(copy.actionRetry),
                  ),
                ),
              if (state.repairNeeds.contains(
                PreferencesRepairNeed.rhythmSchedule,
              ))
                ListTile(
                  key: const ValueKey<String>('rhythm-schedule-repair'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.failureDeliveryRecoveryRequired),
                  trailing: TextButton(
                    onPressed: state.isBusy
                        ? null
                        : () => ref
                              .read(preferencesViewModelProvider.notifier)
                              .repairEffect(
                                PreferencesRepairNeed.rhythmSchedule,
                              ),
                    child: Text(copy.actionRetry),
                  ),
                ),
              if (state.repairNeeds.contains(PreferencesRepairNeed.autoStart))
                ListTile(
                  key: const ValueKey<String>('auto-start-repair'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.autoStartStatusNeedsAction),
                  trailing: TextButton(
                    onPressed: state.isBusy
                        ? null
                        : () => ref
                              .read(preferencesViewModelProvider.notifier)
                              .repairAutoStart(),
                    child: Text(copy.autoStartRepair),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _scheduleSynchronization(PreferencesViewState state) {
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (_restoredFromBucket) {
          _validateAndStore();
        } else {
          _synchronize(state.draft);
        }
      });
    }
    if ((state.feedback == PreferencesFeedback.saved ||
            state.feedback == PreferencesFeedback.discarded) &&
        state.feedback != _lastFeedback) {
      _lastFeedback = state.feedback;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _synchronize(state.draft);
        }
      });
    }
  }

  void _handlePreferencesTransition(
    AsyncValue<PreferencesViewState>? previous,
    AsyncValue<PreferencesViewState> next,
  ) {
    final PreferencesViewState? reloaded = next.value;
    if (!_initialized || previous?.isLoading != true || reloaded == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _synchronize(reloaded.draft);
      }
    });
  }

  RhythmSettingsFormInput _input() {
    return RhythmSettingsFormInput(
      focusMinutes: _focus.value.text,
      restMinutes: _rest.value.text,
      dailyStart: _start.value.text,
      dailyEnd: _end.value.text,
      autoStartEnabled: _autoStart.value,
    );
  }

  void _validateAndStore() {
    final RhythmSettingsFormResult result = _input().validate();
    setState(() => _validation = result);
    final RhythmSettingsDraft? draft = result.draft;
    if (draft != null) {
      ref.read(preferencesViewModelProvider.notifier).updateDraft(draft);
    }
  }

  void _markEditedAndValidate() {
    _hasEdited.value = true;
    _validateAndStore();
  }

  Future<void> _discard() async {
    await ref.read(preferencesViewModelProvider.notifier).discardDraft();
  }

  void _synchronize(RhythmSettingsDraft draft) {
    final RhythmSettingsDraftSnapshot snapshot = draft.snapshot();
    setState(() {
      _focus.value.text = snapshot.focusMinutes.toString();
      _rest.value.text = snapshot.restMinutes.toString();
      _start.value.text = snapshot.dailyStart;
      _end.value.text = snapshot.dailyEnd;
      _autoStart.value = snapshot.autoStartEnabled;
      _hasEdited.value = false;
      _validation = _input().validate();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _rest.dispose();
    _start.dispose();
    _end.dispose();
    _autoStart.dispose();
    _expanded.dispose();
    _hasEdited.dispose();
    super.dispose();
  }
}
