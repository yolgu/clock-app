// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Clock Rhythm';

  @override
  String get navigationSemanticsLabel => 'App destinations';

  @override
  String get navigationClock => 'Clock';

  @override
  String get navigationCalendar => 'Calendar';

  @override
  String get navigationData => 'Data';

  @override
  String get navigationTheme => 'Theme';

  @override
  String get actionClose => 'Close';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionOpenSettings => 'Open settings';

  @override
  String get actionDiscard => 'Discard';

  @override
  String get actionSave => 'Save';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionImportPortableBackup => 'Import Portable Backup';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageKoreanCode => 'KOR';

  @override
  String get languageEnglishCode => 'EN';

  @override
  String get languageKoreanName => '한국어';

  @override
  String get languageEnglishName => 'English';

  @override
  String get messageLanguageChanged => 'Language changed.';

  @override
  String get rhythmStatusTitle => 'Status';

  @override
  String get rhythmStatusIdle => 'Idle';

  @override
  String get rhythmStatusRunning => 'Running';

  @override
  String get rhythmStatusPaused => 'Paused';

  @override
  String get rhythmStatusStoppedForToday => 'Done today';

  @override
  String get rhythmSettingsTitle => 'Focus window settings';

  @override
  String get rhythmSettingsDisclosureTitle =>
      'Focus window and notification settings';

  @override
  String get rhythmSettingsDisclosureExpand =>
      'Expand focus window and notification settings';

  @override
  String get rhythmSettingsDisclosureCollapse =>
      'Collapse focus window and notification settings';

  @override
  String get rhythmSettingsFocusMinutes => 'Focus Interval';

  @override
  String get rhythmSettingsRestMinutes => 'Rest Interval';

  @override
  String get rhythmSettingsDailyStart => 'Focus window start';

  @override
  String get rhythmSettingsDailyEnd => 'Focus window end';

  @override
  String get rhythmSettingsAutoStart => 'Start Clock Rhythm automatically';

  @override
  String get rhythmSettingsSave => 'Save settings';

  @override
  String get rhythmSettingsDiscard => 'Discard changes';

  @override
  String get rhythmSettingsUnsaved => 'Unsaved changes';

  @override
  String get rhythmSettingsDraftResetFailed =>
      'Settings were saved, but the temporary draft could not be reset.';

  @override
  String rhythmSettingsDecrease(String label) {
    return 'Decrease $label';
  }

  @override
  String rhythmSettingsIncrease(String label) {
    return 'Increase $label';
  }

  @override
  String rhythmSettingsMinuteMeta(int min, int max) {
    return 'min · $min-$max';
  }

  @override
  String rhythmSettingsMinuteRange(int min, int max) {
    return 'Enter $min-$max min.';
  }

  @override
  String rhythmSettingsNextEvent(String time) {
    return 'Next notification: $time';
  }

  @override
  String get rhythmSettingsNextEventUnavailable => 'Check the time settings.';

  @override
  String get rhythmSettingsOutsideDailyRhythm =>
      'The current time is outside the focus window.';

  @override
  String rhythmSettingsDeepIdleWarning(int minimumMinutes) {
    return 'Intervals shorter than $minimumMinutes minutes may be delayed or skipped while Android is in deep idle.';
  }

  @override
  String rhythmSettingsSummary(
    int focus,
    int rest,
    String dailyStart,
    String dailyEnd,
    String sound,
  ) {
    return '$focus min focus · $rest min rest · $dailyStart-$dailyEnd · $sound';
  }

  @override
  String get rhythmSettingsSummaryDirty => 'Save needed';

  @override
  String get rhythmSettingsSummaryInvalid => 'Time setting error';

  @override
  String get rhythmSettingsSummaryMuted => 'Muted';

  @override
  String get rhythmSettingsSummaryZeroVolume => 'Volume 0%';

  @override
  String get rhythmSettingsSummaryOutsideDailyRhythm => 'Outside focus window';

  @override
  String get rhythmControlStart => 'Start';

  @override
  String get rhythmControlPause => 'Pause';

  @override
  String get rhythmControlResume => 'Resume';

  @override
  String get rhythmControlStopForToday => 'Stop for Today';

  @override
  String get legacyCoexistenceWarningTitle =>
      'Before starting the Flutter beta';

  @override
  String get legacyCoexistenceWarningDescription =>
      'Pause the current Rhythm and quit the Neutralino Clock Rhythm app before starting here. Running both apps can send duplicate notifications.';

  @override
  String get legacyCoexistenceWarningConfirm => 'I paused and quit it';

  @override
  String get messagePreferencesSaved => 'Settings saved.';

  @override
  String get messagePreferencesFailed => 'Settings could not be saved.';

  @override
  String get messageRhythmRunning => 'Focus window is running.';

  @override
  String get messageRhythmPaused => 'Focus window paused.';

  @override
  String get messageRhythmResumed => 'Focus window resumed.';

  @override
  String get messageRhythmStoppedForToday => 'The current focus window ended.';

  @override
  String get autoStartStatusEnabled => 'Automatic startup is enabled.';

  @override
  String get autoStartStatusDisabled => 'Automatic startup is disabled.';

  @override
  String get autoStartStatusNeedsAction =>
      'Automatic startup needs your attention.';

  @override
  String get autoStartStatusError => 'Automatic startup could not be checked.';

  @override
  String get autoStartRepair => 'Repair automatic startup';

  @override
  String get soundEyebrow => 'Sound';

  @override
  String get soundTitle => 'Notification sound';

  @override
  String get soundDefaultLabel => 'Default';

  @override
  String get soundCustomFallback => 'Custom MP3';

  @override
  String get soundMutedLabel => 'Muted';

  @override
  String get soundChooseMp3 => 'Choose MP3';

  @override
  String get soundUseDefault => 'Use default';

  @override
  String get soundMute => 'Mute';

  @override
  String get soundUnmute => 'Turn sound on';

  @override
  String get soundPreview => 'Preview';

  @override
  String get soundStopPreview => 'Stop preview';

  @override
  String get soundVolume => 'Sound volume';

  @override
  String get soundVolumeLabel => 'App notification volume';

  @override
  String get soundZeroVolumeWarning =>
      'Volume is 0%. Notifications remain visible.';

  @override
  String soundCustomRequirements(int maxMebibytes) {
    return 'Choose one MP3 file no larger than $maxMebibytes MiB.';
  }

  @override
  String get soundRepair => 'Repair sound';

  @override
  String get messageCustomSoundChanged => 'Notification sound changed.';

  @override
  String get messageSoundMuted =>
      'Sound muted. Operating-system notifications stay visible.';

  @override
  String get messageSoundUnmuted => 'Sound turned on.';

  @override
  String get messageSoundPreviewStarted => 'Previewing notification sound.';

  @override
  String get messageSoundPreviewStopped => 'Sound preview stopped.';

  @override
  String get messageDefaultSoundRestored => 'Default sound restored.';

  @override
  String messageVolumeChanged(int volume) {
    return 'Notification volume set to $volume%.';
  }

  @override
  String get todoTodayEyebrow => 'Today';

  @override
  String get todoTodayTitle => 'Today';

  @override
  String get todoTodayInputLabel => 'Today Todo input';

  @override
  String get todoTodayPlaceholder => 'Write a Todo';

  @override
  String get todoActionAddTime => 'Add time';

  @override
  String get todoActionAdd => 'Add';

  @override
  String get todoActionEdit => 'Edit';

  @override
  String get todoActionDelete => 'Delete';

  @override
  String get todoActionSave => 'Save';

  @override
  String get todoActionCancel => 'Cancel';

  @override
  String todoActionComplete(String title) {
    return 'Complete $title';
  }

  @override
  String todoActionReopen(String title) {
    return 'Reopen $title';
  }

  @override
  String todoActionReorder(String title) {
    return 'Reorder $title';
  }

  @override
  String get todoListEmpty => 'No Todos yet.';

  @override
  String get todoListEditTitle => 'Edit Todo title';

  @override
  String get todoListEditDate => 'Edit Todo date';

  @override
  String get todoListEditTime => 'Edit Todo time';

  @override
  String get todoGroupIncomplete => 'Incomplete';

  @override
  String get todoGroupCompleted => 'Completed';

  @override
  String get todoValidationTitleRequired => 'Enter a Todo.';

  @override
  String todoValidationTitleTooLong(int max) {
    return 'Todos must be $max characters or fewer.';
  }

  @override
  String todoValidationTitleCounter(int count, int max) {
    return '$count/$max';
  }

  @override
  String todoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Todos',
      one: '1 Todo',
      zero: 'No Todos',
    );
    return '$_temp0';
  }

  @override
  String todoCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed Todos',
      one: '1 completed Todo',
      zero: 'No completed Todos',
    );
    return '$_temp0';
  }

  @override
  String get messageTodoAdded => 'Todo added.';

  @override
  String get messageTodoUpdated => 'Todo updated.';

  @override
  String get messageTodoCompleted => 'Todo completed.';

  @override
  String get messageTodoReopened => 'Todo reopened.';

  @override
  String get messageTodoDeleted => 'Todo deleted.';

  @override
  String get messageTodoActionFailed =>
      'The Todo action could not be completed.';

  @override
  String get timePickerPlaceholder => 'Select time';

  @override
  String get timePickerDirectLabel => 'Direct input';

  @override
  String timePickerDirectInput(String label) {
    return 'Direct input for $label';
  }

  @override
  String get timePickerEditing => 'Editing';

  @override
  String get timePickerHourGroup => 'Select hour';

  @override
  String get timePickerMinuteGroup => 'Select minute';

  @override
  String timePickerHourOption(String hour) {
    return '$hour:00';
  }

  @override
  String timePickerMinuteOption(String minute) {
    return '$minute min';
  }

  @override
  String get timePickerClear => 'Clear';

  @override
  String get timePickerClose => 'Close';

  @override
  String get timePickerInvalid =>
      'Enter a time from 00:00 to 23:59 in HH:mm format.';

  @override
  String get calendarEyebrow => 'Calendar';

  @override
  String get calendarTitle => 'Todo Calendar';

  @override
  String get calendarMonthEyebrow => 'Month';

  @override
  String get calendarSelectedEyebrow => 'Selected date';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarToday => 'Today';

  @override
  String calendarGridLabel(String month) {
    return 'Todo calendar for $month';
  }

  @override
  String calendarSelectedDateLabel(String date) {
    return 'Selected date: $date';
  }

  @override
  String get calendarNoTodo => 'No Todos';

  @override
  String get calendarWeekdaySunday => 'Sun';

  @override
  String get calendarWeekdayMonday => 'Mon';

  @override
  String get calendarWeekdayTuesday => 'Tue';

  @override
  String get calendarWeekdayWednesday => 'Wed';

  @override
  String get calendarWeekdayThursday => 'Thu';

  @override
  String get calendarWeekdayFriday => 'Fri';

  @override
  String get calendarWeekdaySaturday => 'Sat';

  @override
  String calendarDayTodoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Todos',
      one: '1 Todo',
      zero: 'No Todos',
    );
    return '$_temp0';
  }

  @override
  String get backupEyebrow => 'Data';

  @override
  String get backupTitle => 'Data management';

  @override
  String get backupDescription =>
      'Export Preferences and Todos to a Portable Backup, or replace local data from one.';

  @override
  String get backupExport => 'Export';

  @override
  String get backupImport => 'Import';

  @override
  String get backupPreviewTitle => 'Portable Backup preview';

  @override
  String get backupImportConfirmTitle => 'Import Portable Backup';

  @override
  String get backupImportConfirmDescription =>
      'Current Preferences and Todos will be fully replaced by this Portable Backup.';

  @override
  String get backupConfirmImport => 'Replace all local data';

  @override
  String get backupCancel => 'Cancel';

  @override
  String get backupPlainTextWarning =>
      'Portable Backup is readable plain JSON and has no password protection.';

  @override
  String get backupRhythmStopWarning =>
      'Confirming import stops current focus/rest delivery even if data replacement later fails.';

  @override
  String backupSummaryTodos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Todos',
      one: '1 Todo',
      zero: 'No Todos',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryCompletedTodos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed Todos',
      one: '1 completed Todo',
      zero: 'No completed Todos',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryTerms(int focus, int rest) {
    return 'Focus $focus min / Rest $rest min';
  }

  @override
  String backupSummaryWindow(String dailyStart, String dailyEnd) {
    return 'Focus window: $dailyStart-$dailyEnd';
  }

  @override
  String backupSummaryLanguage(String language) {
    return 'Language: $language';
  }

  @override
  String backupSummaryTheme(String theme) {
    return 'Theme: $theme';
  }

  @override
  String get backupSummaryAutoStartEnabled =>
      'Windows automatic startup: enabled';

  @override
  String get backupSummaryAutoStartDisabled =>
      'Windows automatic startup: disabled';

  @override
  String backupSummaryExportedAt(String exportedAt) {
    return 'Exported: $exportedAt';
  }

  @override
  String backupSummaryDateRange(String startDate, String endDate) {
    return 'Todo dates: $startDate – $endDate';
  }

  @override
  String get backupSummaryNoDateRange => 'Todo dates: none';

  @override
  String get backupSummaryCustomSoundSanitized =>
      'Custom Notification Sound will be replaced with the bundled default.';

  @override
  String get messageBackupExported => 'Portable Backup exported.';

  @override
  String get messageBackupImported =>
      'Portable Backup imported and all local data was replaced.';

  @override
  String get databaseRecoveryTitle => 'Database recovery';

  @override
  String get databaseRecoveryDescription =>
      'Clock Rhythm could not open the database. The original database has been preserved.';

  @override
  String get databaseRecoveryRetry => 'Retry opening database';

  @override
  String get databaseRecoveryImport => 'Import Portable Backup';

  @override
  String get databaseRecoveryReset => 'Reset database';

  @override
  String get databaseRecoveryResetTitle => 'Reset local database';

  @override
  String get databaseRecoveryResetDescription =>
      'A recovery copy will be created before a new empty database replaces the current one. This cannot be undone in Clock Rhythm.';

  @override
  String get databaseRecoveryConfirmReset => 'Create recovery copy and reset';

  @override
  String get permissionPanelTitle => 'Focus/rest delivery permissions';

  @override
  String get permissionNotificationTitle => 'Notifications';

  @override
  String get permissionExactAlarmTitle => 'Exact alarms';

  @override
  String get permissionGranted => 'Granted';

  @override
  String get permissionRequired => 'Required';

  @override
  String get permissionOpenNotificationSettings => 'Open notification settings';

  @override
  String get permissionOpenExactAlarmSettings => 'Open exact-alarm settings';

  @override
  String get permissionDeliveryRecoveryTitle =>
      'Focus/rest delivery needs attention';

  @override
  String get permissionDeliveryRecoveryDescription =>
      'Delivery stopped after a permission or system-state change. Review settings, then start again.';

  @override
  String get themeEyebrow => 'Theme';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeDescription =>
      'Keep the design structure and change the color palette.';

  @override
  String get themeCurrentName => 'Current';

  @override
  String get themeTokyoNightName => 'Tokyo Night';

  @override
  String get themeOneDarkProName => 'One Dark Pro';

  @override
  String get themeCatppuccinMochaName => 'Catppuccin Mocha';

  @override
  String get themeNordName => 'Nord';

  @override
  String get themeDraculaName => 'Dracula';

  @override
  String get themeGruvboxName => 'Gruvbox';

  @override
  String get themeNeonDuskName => 'Neon Dusk';

  @override
  String get themeNightOwlName => 'Night Owl';

  @override
  String get themeSynthwave84Name => 'Synthwave 84';

  @override
  String get themeAyuMirageDarkName => 'Ayu Mirage Dark';

  @override
  String get themeSelected => 'Selected';

  @override
  String get themeSelect => 'Select theme';

  @override
  String get messageThemeChanged => 'Theme changed.';

  @override
  String get routeErrorTitle => 'This destination cannot be opened';

  @override
  String get routeBackToClock => 'Back to Clock';

  @override
  String get trayOpen => 'Open Clock Rhythm';

  @override
  String get trayPause => 'Pause';

  @override
  String get trayResume => 'Resume';

  @override
  String get trayStopForToday => 'Stop for Today';

  @override
  String get trayQuit => 'Quit Clock Rhythm';

  @override
  String get announcementRhythmRunning => 'Focus window started.';

  @override
  String get announcementRhythmPaused => 'Focus window paused.';

  @override
  String get announcementRhythmResumed => 'Focus window resumed.';

  @override
  String get announcementRhythmStoppedForToday =>
      'The current focus window ended.';

  @override
  String get announcementPreferencesSaved => 'Settings saved.';

  @override
  String get announcementLanguageChanged => 'Language changed.';

  @override
  String get announcementThemeChanged => 'Theme changed.';

  @override
  String get announcementTodoAdded => 'Todo added.';

  @override
  String get announcementTodoUpdated => 'Todo updated.';

  @override
  String get announcementTodoCompleted => 'Todo completed.';

  @override
  String get announcementTodoReopened => 'Todo reopened.';

  @override
  String get announcementTodoDeleted => 'Todo deleted.';

  @override
  String get announcementBackupExported => 'Portable Backup exported.';

  @override
  String get announcementBackupImported =>
      'Portable Backup imported. Local data was replaced.';

  @override
  String get announcementError =>
      'An error occurred. Review the message on screen.';

  @override
  String accessibilityDigitalClockLabel(String time) {
    return 'Current time: $time';
  }

  @override
  String get accessibilitySelected => 'Selected';

  @override
  String get accessibilityCompleted => 'Completed';

  @override
  String get accessibilityIncomplete => 'Incomplete';

  @override
  String get accessibilityError => 'Error';

  @override
  String get notificationFocusEndedTitle => 'Time for a rest';

  @override
  String get notificationFocusEndedBody => 'The Focus Interval has ended.';

  @override
  String get notificationRestEndedTitle => 'Time to focus again';

  @override
  String get notificationRestEndedBody => 'The Rest Interval has ended.';

  @override
  String get failureUnknown => 'An unexpected error occurred.';

  @override
  String get failureRouteNotFound =>
      'The requested destination does not exist.';

  @override
  String get failureRouteInvalidCalendarDate =>
      'The calendar date in this link is invalid.';

  @override
  String get failurePreferencesSave =>
      'Settings could not be saved. Your unsaved changes are still available.';

  @override
  String get failureTodoLimitReached =>
      'This installation has reached its Todo limit.';

  @override
  String get failureTodoAction => 'The Todo action could not be completed.';

  @override
  String get failureCustomSoundInvalidFile => 'Choose a valid MP3 file.';

  @override
  String get failureCustomSoundTooLarge =>
      'The selected MP3 file is too large.';

  @override
  String get failureCustomSoundDecode =>
      'The selected MP3 file could not be decoded.';

  @override
  String get failureCustomSoundPlayback =>
      'The custom sound could not be played. The bundled sound was used for this event.';

  @override
  String get failureAutoStartReconciliation =>
      'Windows automatic startup could not be updated. Review the repair action.';

  @override
  String get failureBackupFileRead =>
      'The Portable Backup file could not be read.';

  @override
  String get failureBackupFileWrite =>
      'The Portable Backup file could not be written.';

  @override
  String get failureBackupFileTooLarge =>
      'The Portable Backup file is too large.';

  @override
  String get failureBackupInvalidJson => 'The selected file is not valid JSON.';

  @override
  String get failureBackupAppNameMismatch =>
      'This file is not a Clock Rhythm Portable Backup.';

  @override
  String get failureBackupUnsupportedSchemaVersion =>
      'This Portable Backup version is not supported.';

  @override
  String get failureBackupInvalidExportedAt =>
      'The Portable Backup export time is invalid.';

  @override
  String get failureBackupMissingRequiredData =>
      'The Portable Backup is missing required data.';

  @override
  String get failureBackupInvalidPreferences =>
      'The Portable Backup contains invalid Preferences.';

  @override
  String get failureBackupTooManyTodos =>
      'The Portable Backup contains too many Todos.';

  @override
  String get failureBackupReplacement =>
      'Local data could not be replaced. Existing durable data was preserved, and focus/rest delivery remains Idle.';

  @override
  String get failureBackupExport =>
      'The Portable Backup could not be exported.';

  @override
  String get failureDatabaseOpen =>
      'The database could not be opened. The original database was preserved.';

  @override
  String get failureDatabaseMigration =>
      'The database could not be updated. The original database was preserved.';

  @override
  String get failureDatabaseCorrupted =>
      'The database appears to be damaged. The original database was preserved.';

  @override
  String get failureDatabaseRecoveryCopy =>
      'A recovery copy could not be created, so the database was not reset.';

  @override
  String get failureNotificationPermissionRequired =>
      'Notification permission is required to start focus/rest delivery.';

  @override
  String get failureExactAlarmPermissionRequired =>
      'Exact-alarm access is required to start focus/rest delivery.';

  @override
  String get failureNotificationAndExactAlarmPermissionRequired =>
      'Notification permission and exact-alarm access are required to start focus/rest delivery.';

  @override
  String get failureDeliveryPermissionLost =>
      'Focus/rest delivery stopped because a required permission is no longer available.';

  @override
  String get failureDeliveryRecoveryRequired =>
      'Focus/rest delivery needs recovery. Review settings and start again.';

  @override
  String failureBackupTodoIdInvalid(int index) {
    return 'Todo $index in the backup has an invalid ID.';
  }

  @override
  String failureBackupTodoIdDuplicate(int index) {
    return 'Todo $index in the backup has a duplicate ID.';
  }

  @override
  String failureBackupTodoTitleInvalid(int index) {
    return 'Todo $index in the backup has an invalid title.';
  }

  @override
  String failureBackupTodoDateInvalid(int index) {
    return 'Todo $index in the backup has an invalid Gregorian date.';
  }

  @override
  String failureBackupTodoTimeInvalid(int index) {
    return 'Todo $index in the backup does not use a valid HH:mm time.';
  }

  @override
  String failureBackupTodoCompletionInvalid(int index) {
    return 'Todo $index in the backup has an invalid completion value.';
  }

  @override
  String failureBackupTodoTimestampsInvalid(int index) {
    return 'Todo $index in the backup has invalid timestamps.';
  }

  @override
  String failureBackupTodoDisplayOrderInvalid(int index) {
    return 'Todo $index in the backup has an invalid display order.';
  }
}
