import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Clock Rhythm'**
  String get appTitle;

  /// No description provided for @navigationSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'App destinations'**
  String get navigationSemanticsLabel;

  /// No description provided for @navigationClock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get navigationClock;

  /// No description provided for @navigationCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navigationCalendar;

  /// No description provided for @navigationData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get navigationData;

  /// No description provided for @navigationTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get navigationTheme;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get actionOpenSettings;

  /// No description provided for @actionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionImportPortableBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Portable Backup'**
  String get actionImportPortableBackup;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageKoreanCode.
  ///
  /// In en, this message translates to:
  /// **'KOR'**
  String get languageKoreanCode;

  /// No description provided for @languageEnglishCode.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageEnglishCode;

  /// No description provided for @languageKoreanName.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKoreanName;

  /// No description provided for @languageEnglishName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishName;

  /// No description provided for @messageLanguageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed.'**
  String get messageLanguageChanged;

  /// No description provided for @rhythmStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get rhythmStatusTitle;

  /// No description provided for @rhythmStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get rhythmStatusIdle;

  /// No description provided for @rhythmStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get rhythmStatusRunning;

  /// No description provided for @rhythmStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get rhythmStatusPaused;

  /// No description provided for @rhythmStatusStoppedForToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get rhythmStatusStoppedForToday;

  /// No description provided for @rhythmSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus window settings'**
  String get rhythmSettingsTitle;

  /// No description provided for @rhythmSettingsDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus window and notification settings'**
  String get rhythmSettingsDisclosureTitle;

  /// No description provided for @rhythmSettingsDisclosureExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand focus window and notification settings'**
  String get rhythmSettingsDisclosureExpand;

  /// No description provided for @rhythmSettingsDisclosureCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse focus window and notification settings'**
  String get rhythmSettingsDisclosureCollapse;

  /// No description provided for @rhythmSettingsFocusMinutes.
  ///
  /// In en, this message translates to:
  /// **'Focus Interval'**
  String get rhythmSettingsFocusMinutes;

  /// No description provided for @rhythmSettingsRestMinutes.
  ///
  /// In en, this message translates to:
  /// **'Rest Interval'**
  String get rhythmSettingsRestMinutes;

  /// No description provided for @rhythmSettingsDailyStart.
  ///
  /// In en, this message translates to:
  /// **'Focus window start'**
  String get rhythmSettingsDailyStart;

  /// No description provided for @rhythmSettingsDailyEnd.
  ///
  /// In en, this message translates to:
  /// **'Focus window end'**
  String get rhythmSettingsDailyEnd;

  /// No description provided for @rhythmSettingsAutoStart.
  ///
  /// In en, this message translates to:
  /// **'Start Clock Rhythm automatically'**
  String get rhythmSettingsAutoStart;

  /// No description provided for @rhythmSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get rhythmSettingsSave;

  /// No description provided for @rhythmSettingsDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get rhythmSettingsDiscard;

  /// No description provided for @rhythmSettingsUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get rhythmSettingsUnsaved;

  /// No description provided for @rhythmSettingsDraftResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Settings were saved, but the temporary draft could not be reset.'**
  String get rhythmSettingsDraftResetFailed;

  /// No description provided for @rhythmSettingsDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease {label}'**
  String rhythmSettingsDecrease(String label);

  /// No description provided for @rhythmSettingsIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase {label}'**
  String rhythmSettingsIncrease(String label);

  /// No description provided for @rhythmSettingsMinuteMeta.
  ///
  /// In en, this message translates to:
  /// **'min · {min}-{max}'**
  String rhythmSettingsMinuteMeta(int min, int max);

  /// No description provided for @rhythmSettingsMinuteRange.
  ///
  /// In en, this message translates to:
  /// **'Enter {min}-{max} min.'**
  String rhythmSettingsMinuteRange(int min, int max);

  /// No description provided for @rhythmSettingsNextEvent.
  ///
  /// In en, this message translates to:
  /// **'Next notification: {time}'**
  String rhythmSettingsNextEvent(String time);

  /// No description provided for @rhythmSettingsNextEventUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Check the time settings.'**
  String get rhythmSettingsNextEventUnavailable;

  /// No description provided for @rhythmSettingsOutsideDailyRhythm.
  ///
  /// In en, this message translates to:
  /// **'The current time is outside the focus window.'**
  String get rhythmSettingsOutsideDailyRhythm;

  /// No description provided for @rhythmSettingsDeepIdleWarning.
  ///
  /// In en, this message translates to:
  /// **'Intervals shorter than {minimumMinutes} minutes may be delayed or skipped while Android is in deep idle.'**
  String rhythmSettingsDeepIdleWarning(int minimumMinutes);

  /// No description provided for @rhythmSettingsSummary.
  ///
  /// In en, this message translates to:
  /// **'{focus} min focus · {rest} min rest · {dailyStart}-{dailyEnd} · {sound}'**
  String rhythmSettingsSummary(
    int focus,
    int rest,
    String dailyStart,
    String dailyEnd,
    String sound,
  );

  /// No description provided for @rhythmSettingsSummaryDirty.
  ///
  /// In en, this message translates to:
  /// **'Save needed'**
  String get rhythmSettingsSummaryDirty;

  /// No description provided for @rhythmSettingsSummaryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Time setting error'**
  String get rhythmSettingsSummaryInvalid;

  /// No description provided for @rhythmSettingsSummaryMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get rhythmSettingsSummaryMuted;

  /// No description provided for @rhythmSettingsSummaryZeroVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume 0%'**
  String get rhythmSettingsSummaryZeroVolume;

  /// No description provided for @rhythmSettingsSummaryOutsideDailyRhythm.
  ///
  /// In en, this message translates to:
  /// **'Outside focus window'**
  String get rhythmSettingsSummaryOutsideDailyRhythm;

  /// No description provided for @rhythmControlStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get rhythmControlStart;

  /// No description provided for @rhythmControlPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get rhythmControlPause;

  /// No description provided for @rhythmControlResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get rhythmControlResume;

  /// No description provided for @rhythmControlStopForToday.
  ///
  /// In en, this message translates to:
  /// **'Stop for Today'**
  String get rhythmControlStopForToday;

  /// No description provided for @legacyCoexistenceWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Before starting the Flutter beta'**
  String get legacyCoexistenceWarningTitle;

  /// No description provided for @legacyCoexistenceWarningDescription.
  ///
  /// In en, this message translates to:
  /// **'Pause the current Rhythm and quit the Neutralino Clock Rhythm app before starting here. Running both apps can send duplicate notifications.'**
  String get legacyCoexistenceWarningDescription;

  /// No description provided for @legacyCoexistenceWarningConfirm.
  ///
  /// In en, this message translates to:
  /// **'I paused and quit it'**
  String get legacyCoexistenceWarningConfirm;

  /// No description provided for @messagePreferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get messagePreferencesSaved;

  /// No description provided for @messagePreferencesFailed.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be saved.'**
  String get messagePreferencesFailed;

  /// No description provided for @messageRhythmRunning.
  ///
  /// In en, this message translates to:
  /// **'Focus window is running.'**
  String get messageRhythmRunning;

  /// No description provided for @messageRhythmPaused.
  ///
  /// In en, this message translates to:
  /// **'Focus window paused.'**
  String get messageRhythmPaused;

  /// No description provided for @messageRhythmResumed.
  ///
  /// In en, this message translates to:
  /// **'Focus window resumed.'**
  String get messageRhythmResumed;

  /// No description provided for @messageRhythmStoppedForToday.
  ///
  /// In en, this message translates to:
  /// **'The current focus window ended.'**
  String get messageRhythmStoppedForToday;

  /// No description provided for @autoStartStatusEnabled.
  ///
  /// In en, this message translates to:
  /// **'Automatic startup is enabled.'**
  String get autoStartStatusEnabled;

  /// No description provided for @autoStartStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Automatic startup is disabled.'**
  String get autoStartStatusDisabled;

  /// No description provided for @autoStartStatusNeedsAction.
  ///
  /// In en, this message translates to:
  /// **'Automatic startup needs your attention.'**
  String get autoStartStatusNeedsAction;

  /// No description provided for @autoStartStatusError.
  ///
  /// In en, this message translates to:
  /// **'Automatic startup could not be checked.'**
  String get autoStartStatusError;

  /// No description provided for @autoStartRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair automatic startup'**
  String get autoStartRepair;

  /// No description provided for @soundEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get soundEyebrow;

  /// No description provided for @soundTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get soundTitle;

  /// No description provided for @soundDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get soundDefaultLabel;

  /// No description provided for @soundCustomFallback.
  ///
  /// In en, this message translates to:
  /// **'Custom MP3'**
  String get soundCustomFallback;

  /// No description provided for @soundMutedLabel.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get soundMutedLabel;

  /// No description provided for @soundChooseMp3.
  ///
  /// In en, this message translates to:
  /// **'Choose MP3'**
  String get soundChooseMp3;

  /// No description provided for @soundUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get soundUseDefault;

  /// No description provided for @soundMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get soundMute;

  /// No description provided for @soundUnmute.
  ///
  /// In en, this message translates to:
  /// **'Turn sound on'**
  String get soundUnmute;

  /// No description provided for @soundPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get soundPreview;

  /// No description provided for @soundStopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get soundStopPreview;

  /// No description provided for @soundVolume.
  ///
  /// In en, this message translates to:
  /// **'Sound volume'**
  String get soundVolume;

  /// No description provided for @soundVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'App notification volume'**
  String get soundVolumeLabel;

  /// No description provided for @soundZeroVolumeWarning.
  ///
  /// In en, this message translates to:
  /// **'Volume is 0%. Notifications remain visible.'**
  String get soundZeroVolumeWarning;

  /// No description provided for @soundCustomRequirements.
  ///
  /// In en, this message translates to:
  /// **'Choose one MP3 file no larger than {maxMebibytes} MiB.'**
  String soundCustomRequirements(int maxMebibytes);

  /// No description provided for @soundRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair sound'**
  String get soundRepair;

  /// No description provided for @messageCustomSoundChanged.
  ///
  /// In en, this message translates to:
  /// **'Notification sound changed.'**
  String get messageCustomSoundChanged;

  /// No description provided for @messageSoundMuted.
  ///
  /// In en, this message translates to:
  /// **'Sound muted. Operating-system notifications stay visible.'**
  String get messageSoundMuted;

  /// No description provided for @messageSoundUnmuted.
  ///
  /// In en, this message translates to:
  /// **'Sound turned on.'**
  String get messageSoundUnmuted;

  /// No description provided for @messageSoundPreviewStarted.
  ///
  /// In en, this message translates to:
  /// **'Previewing notification sound.'**
  String get messageSoundPreviewStarted;

  /// No description provided for @messageSoundPreviewStopped.
  ///
  /// In en, this message translates to:
  /// **'Sound preview stopped.'**
  String get messageSoundPreviewStopped;

  /// No description provided for @messageDefaultSoundRestored.
  ///
  /// In en, this message translates to:
  /// **'Default sound restored.'**
  String get messageDefaultSoundRestored;

  /// No description provided for @messageVolumeChanged.
  ///
  /// In en, this message translates to:
  /// **'Notification volume set to {volume}%.'**
  String messageVolumeChanged(int volume);

  /// No description provided for @todoTodayEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todoTodayEyebrow;

  /// No description provided for @todoTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todoTodayTitle;

  /// No description provided for @todoTodayInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Today Todo input'**
  String get todoTodayInputLabel;

  /// No description provided for @todoTodayPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write a Todo'**
  String get todoTodayPlaceholder;

  /// No description provided for @todoActionAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get todoActionAddTime;

  /// No description provided for @todoActionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get todoActionAdd;

  /// No description provided for @todoActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get todoActionEdit;

  /// No description provided for @todoActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get todoActionDelete;

  /// No description provided for @todoActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get todoActionSave;

  /// No description provided for @todoActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get todoActionCancel;

  /// No description provided for @todoActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete {title}'**
  String todoActionComplete(String title);

  /// No description provided for @todoActionReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen {title}'**
  String todoActionReopen(String title);

  /// No description provided for @todoActionReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder {title}'**
  String todoActionReorder(String title);

  /// No description provided for @todoListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Todos yet.'**
  String get todoListEmpty;

  /// No description provided for @todoListEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Todo title'**
  String get todoListEditTitle;

  /// No description provided for @todoListEditDate.
  ///
  /// In en, this message translates to:
  /// **'Edit Todo date'**
  String get todoListEditDate;

  /// No description provided for @todoListEditTime.
  ///
  /// In en, this message translates to:
  /// **'Edit Todo time'**
  String get todoListEditTime;

  /// No description provided for @todoGroupIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get todoGroupIncomplete;

  /// No description provided for @todoGroupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get todoGroupCompleted;

  /// No description provided for @todoValidationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a Todo.'**
  String get todoValidationTitleRequired;

  /// No description provided for @todoValidationTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Todos must be {max} characters or fewer.'**
  String todoValidationTitleTooLong(int max);

  /// No description provided for @todoValidationTitleCounter.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String todoValidationTitleCounter(int count, int max);

  /// No description provided for @todoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No Todos} =1{1 Todo} other{{count} Todos}}'**
  String todoCount(int count);

  /// No description provided for @todoCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No completed Todos} =1{1 completed Todo} other{{count} completed Todos}}'**
  String todoCompletedCount(int count);

  /// No description provided for @messageTodoAdded.
  ///
  /// In en, this message translates to:
  /// **'Todo added.'**
  String get messageTodoAdded;

  /// No description provided for @messageTodoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Todo updated.'**
  String get messageTodoUpdated;

  /// No description provided for @messageTodoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Todo completed.'**
  String get messageTodoCompleted;

  /// No description provided for @messageTodoReopened.
  ///
  /// In en, this message translates to:
  /// **'Todo reopened.'**
  String get messageTodoReopened;

  /// No description provided for @messageTodoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Todo deleted.'**
  String get messageTodoDeleted;

  /// No description provided for @messageTodoActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The Todo action could not be completed.'**
  String get messageTodoActionFailed;

  /// No description provided for @timePickerPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get timePickerPlaceholder;

  /// No description provided for @timePickerDirectLabel.
  ///
  /// In en, this message translates to:
  /// **'Direct input'**
  String get timePickerDirectLabel;

  /// No description provided for @timePickerDirectInput.
  ///
  /// In en, this message translates to:
  /// **'Direct input for {label}'**
  String timePickerDirectInput(String label);

  /// No description provided for @timePickerEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get timePickerEditing;

  /// No description provided for @timePickerHourGroup.
  ///
  /// In en, this message translates to:
  /// **'Select hour'**
  String get timePickerHourGroup;

  /// No description provided for @timePickerMinuteGroup.
  ///
  /// In en, this message translates to:
  /// **'Select minute'**
  String get timePickerMinuteGroup;

  /// No description provided for @timePickerHourOption.
  ///
  /// In en, this message translates to:
  /// **'{hour}:00'**
  String timePickerHourOption(String hour);

  /// No description provided for @timePickerMinuteOption.
  ///
  /// In en, this message translates to:
  /// **'{minute} min'**
  String timePickerMinuteOption(String minute);

  /// No description provided for @timePickerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get timePickerClear;

  /// No description provided for @timePickerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get timePickerClose;

  /// No description provided for @timePickerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a time from 00:00 to 23:59 in HH:mm format.'**
  String get timePickerInvalid;

  /// No description provided for @calendarEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarEyebrow;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Todo Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarMonthEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarMonthEyebrow;

  /// No description provided for @calendarSelectedEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Selected date'**
  String get calendarSelectedEyebrow;

  /// No description provided for @calendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarGridLabel.
  ///
  /// In en, this message translates to:
  /// **'Todo calendar for {month}'**
  String calendarGridLabel(String month);

  /// No description provided for @calendarSelectedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected date: {date}'**
  String calendarSelectedDateLabel(String date);

  /// No description provided for @calendarNoTodo.
  ///
  /// In en, this message translates to:
  /// **'No Todos'**
  String get calendarNoTodo;

  /// No description provided for @calendarWeekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get calendarWeekdaySunday;

  /// No description provided for @calendarWeekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get calendarWeekdayMonday;

  /// No description provided for @calendarWeekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get calendarWeekdayTuesday;

  /// No description provided for @calendarWeekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get calendarWeekdayWednesday;

  /// No description provided for @calendarWeekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get calendarWeekdayThursday;

  /// No description provided for @calendarWeekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get calendarWeekdayFriday;

  /// No description provided for @calendarWeekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get calendarWeekdaySaturday;

  /// No description provided for @calendarDayTodoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No Todos} =1{1 Todo} other{{count} Todos}}'**
  String calendarDayTodoCount(int count);

  /// No description provided for @backupEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get backupEyebrow;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get backupTitle;

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Export Preferences and Todos to a Portable Backup, or replace local data from one.'**
  String get backupDescription;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get backupExport;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get backupImport;

  /// No description provided for @backupPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Portable Backup preview'**
  String get backupPreviewTitle;

  /// No description provided for @backupImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Portable Backup'**
  String get backupImportConfirmTitle;

  /// No description provided for @backupImportConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'Current Preferences and Todos will be fully replaced by this Portable Backup.'**
  String get backupImportConfirmDescription;

  /// No description provided for @backupConfirmImport.
  ///
  /// In en, this message translates to:
  /// **'Replace all local data'**
  String get backupConfirmImport;

  /// No description provided for @backupCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get backupCancel;

  /// No description provided for @backupPlainTextWarning.
  ///
  /// In en, this message translates to:
  /// **'Portable Backup is readable plain JSON and has no password protection.'**
  String get backupPlainTextWarning;

  /// No description provided for @backupRhythmStopWarning.
  ///
  /// In en, this message translates to:
  /// **'Confirming import stops current focus/rest delivery even if data replacement later fails.'**
  String get backupRhythmStopWarning;

  /// No description provided for @backupSummaryTodos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No Todos} =1{1 Todo} other{{count} Todos}}'**
  String backupSummaryTodos(int count);

  /// No description provided for @backupSummaryCompletedTodos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No completed Todos} =1{1 completed Todo} other{{count} completed Todos}}'**
  String backupSummaryCompletedTodos(int count);

  /// No description provided for @backupSummaryTerms.
  ///
  /// In en, this message translates to:
  /// **'Focus {focus} min / Rest {rest} min'**
  String backupSummaryTerms(int focus, int rest);

  /// No description provided for @backupSummaryWindow.
  ///
  /// In en, this message translates to:
  /// **'Focus window: {dailyStart}-{dailyEnd}'**
  String backupSummaryWindow(String dailyStart, String dailyEnd);

  /// No description provided for @backupSummaryLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language: {language}'**
  String backupSummaryLanguage(String language);

  /// No description provided for @backupSummaryTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme: {theme}'**
  String backupSummaryTheme(String theme);

  /// No description provided for @backupSummaryAutoStartEnabled.
  ///
  /// In en, this message translates to:
  /// **'Windows automatic startup: enabled'**
  String get backupSummaryAutoStartEnabled;

  /// No description provided for @backupSummaryAutoStartDisabled.
  ///
  /// In en, this message translates to:
  /// **'Windows automatic startup: disabled'**
  String get backupSummaryAutoStartDisabled;

  /// No description provided for @backupSummaryExportedAt.
  ///
  /// In en, this message translates to:
  /// **'Exported: {exportedAt}'**
  String backupSummaryExportedAt(String exportedAt);

  /// No description provided for @backupSummaryDateRange.
  ///
  /// In en, this message translates to:
  /// **'Todo dates: {startDate} – {endDate}'**
  String backupSummaryDateRange(String startDate, String endDate);

  /// No description provided for @backupSummaryNoDateRange.
  ///
  /// In en, this message translates to:
  /// **'Todo dates: none'**
  String get backupSummaryNoDateRange;

  /// No description provided for @backupSummaryCustomSoundSanitized.
  ///
  /// In en, this message translates to:
  /// **'Custom Notification Sound will be replaced with the bundled default.'**
  String get backupSummaryCustomSoundSanitized;

  /// No description provided for @messageBackupExported.
  ///
  /// In en, this message translates to:
  /// **'Portable Backup exported.'**
  String get messageBackupExported;

  /// No description provided for @messageBackupImported.
  ///
  /// In en, this message translates to:
  /// **'Portable Backup imported and all local data was replaced.'**
  String get messageBackupImported;

  /// No description provided for @databaseRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Database recovery'**
  String get databaseRecoveryTitle;

  /// No description provided for @databaseRecoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Clock Rhythm could not open the database. The original database has been preserved.'**
  String get databaseRecoveryDescription;

  /// No description provided for @databaseRecoveryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry opening database'**
  String get databaseRecoveryRetry;

  /// No description provided for @databaseRecoveryImport.
  ///
  /// In en, this message translates to:
  /// **'Import Portable Backup'**
  String get databaseRecoveryImport;

  /// No description provided for @databaseRecoveryReset.
  ///
  /// In en, this message translates to:
  /// **'Reset database'**
  String get databaseRecoveryReset;

  /// No description provided for @databaseRecoveryResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset local database'**
  String get databaseRecoveryResetTitle;

  /// No description provided for @databaseRecoveryResetDescription.
  ///
  /// In en, this message translates to:
  /// **'A recovery copy will be created before a new empty database replaces the current one. This cannot be undone in Clock Rhythm.'**
  String get databaseRecoveryResetDescription;

  /// No description provided for @databaseRecoveryConfirmReset.
  ///
  /// In en, this message translates to:
  /// **'Create recovery copy and reset'**
  String get databaseRecoveryConfirmReset;

  /// No description provided for @permissionPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus/rest delivery permissions'**
  String get permissionPanelTitle;

  /// No description provided for @permissionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionNotificationTitle;

  /// No description provided for @permissionExactAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms'**
  String get permissionExactAlarmTitle;

  /// No description provided for @permissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get permissionGranted;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get permissionRequired;

  /// No description provided for @permissionOpenNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get permissionOpenNotificationSettings;

  /// No description provided for @permissionOpenExactAlarmSettings.
  ///
  /// In en, this message translates to:
  /// **'Open exact-alarm settings'**
  String get permissionOpenExactAlarmSettings;

  /// No description provided for @permissionDeliveryRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus/rest delivery needs attention'**
  String get permissionDeliveryRecoveryTitle;

  /// No description provided for @permissionDeliveryRecoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Delivery stopped after a permission or system-state change. Review settings, then start again.'**
  String get permissionDeliveryRecoveryDescription;

  /// No description provided for @themeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeEyebrow;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep the design structure and change the color palette.'**
  String get themeDescription;

  /// No description provided for @themeCurrentName.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get themeCurrentName;

  /// No description provided for @themeTokyoNightName.
  ///
  /// In en, this message translates to:
  /// **'Tokyo Night'**
  String get themeTokyoNightName;

  /// No description provided for @themeOneDarkProName.
  ///
  /// In en, this message translates to:
  /// **'One Dark Pro'**
  String get themeOneDarkProName;

  /// No description provided for @themeCatppuccinMochaName.
  ///
  /// In en, this message translates to:
  /// **'Catppuccin Mocha'**
  String get themeCatppuccinMochaName;

  /// No description provided for @themeNordName.
  ///
  /// In en, this message translates to:
  /// **'Nord'**
  String get themeNordName;

  /// No description provided for @themeDraculaName.
  ///
  /// In en, this message translates to:
  /// **'Dracula'**
  String get themeDraculaName;

  /// No description provided for @themeGruvboxName.
  ///
  /// In en, this message translates to:
  /// **'Gruvbox'**
  String get themeGruvboxName;

  /// No description provided for @themeNeonDuskName.
  ///
  /// In en, this message translates to:
  /// **'Neon Dusk'**
  String get themeNeonDuskName;

  /// No description provided for @themeNightOwlName.
  ///
  /// In en, this message translates to:
  /// **'Night Owl'**
  String get themeNightOwlName;

  /// No description provided for @themeSynthwave84Name.
  ///
  /// In en, this message translates to:
  /// **'Synthwave 84'**
  String get themeSynthwave84Name;

  /// No description provided for @themeAyuMirageDarkName.
  ///
  /// In en, this message translates to:
  /// **'Ayu Mirage Dark'**
  String get themeAyuMirageDarkName;

  /// No description provided for @themeSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get themeSelected;

  /// No description provided for @themeSelect.
  ///
  /// In en, this message translates to:
  /// **'Select theme'**
  String get themeSelect;

  /// No description provided for @messageThemeChanged.
  ///
  /// In en, this message translates to:
  /// **'Theme changed.'**
  String get messageThemeChanged;

  /// No description provided for @routeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'This destination cannot be opened'**
  String get routeErrorTitle;

  /// No description provided for @routeBackToClock.
  ///
  /// In en, this message translates to:
  /// **'Back to Clock'**
  String get routeBackToClock;

  /// No description provided for @trayOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Clock Rhythm'**
  String get trayOpen;

  /// No description provided for @trayPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get trayPause;

  /// No description provided for @trayResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get trayResume;

  /// No description provided for @trayStopForToday.
  ///
  /// In en, this message translates to:
  /// **'Stop for Today'**
  String get trayStopForToday;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit Clock Rhythm'**
  String get trayQuit;

  /// No description provided for @announcementRhythmRunning.
  ///
  /// In en, this message translates to:
  /// **'Focus window started.'**
  String get announcementRhythmRunning;

  /// No description provided for @announcementRhythmPaused.
  ///
  /// In en, this message translates to:
  /// **'Focus window paused.'**
  String get announcementRhythmPaused;

  /// No description provided for @announcementRhythmResumed.
  ///
  /// In en, this message translates to:
  /// **'Focus window resumed.'**
  String get announcementRhythmResumed;

  /// No description provided for @announcementRhythmStoppedForToday.
  ///
  /// In en, this message translates to:
  /// **'The current focus window ended.'**
  String get announcementRhythmStoppedForToday;

  /// No description provided for @announcementPreferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get announcementPreferencesSaved;

  /// No description provided for @announcementLanguageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed.'**
  String get announcementLanguageChanged;

  /// No description provided for @announcementThemeChanged.
  ///
  /// In en, this message translates to:
  /// **'Theme changed.'**
  String get announcementThemeChanged;

  /// No description provided for @announcementTodoAdded.
  ///
  /// In en, this message translates to:
  /// **'Todo added.'**
  String get announcementTodoAdded;

  /// No description provided for @announcementTodoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Todo updated.'**
  String get announcementTodoUpdated;

  /// No description provided for @announcementTodoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Todo completed.'**
  String get announcementTodoCompleted;

  /// No description provided for @announcementTodoReopened.
  ///
  /// In en, this message translates to:
  /// **'Todo reopened.'**
  String get announcementTodoReopened;

  /// No description provided for @announcementTodoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Todo deleted.'**
  String get announcementTodoDeleted;

  /// No description provided for @announcementBackupExported.
  ///
  /// In en, this message translates to:
  /// **'Portable Backup exported.'**
  String get announcementBackupExported;

  /// No description provided for @announcementBackupImported.
  ///
  /// In en, this message translates to:
  /// **'Portable Backup imported. Local data was replaced.'**
  String get announcementBackupImported;

  /// No description provided for @announcementError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Review the message on screen.'**
  String get announcementError;

  /// No description provided for @accessibilityDigitalClockLabel.
  ///
  /// In en, this message translates to:
  /// **'Current time: {time}'**
  String accessibilityDigitalClockLabel(String time);

  /// No description provided for @accessibilitySelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get accessibilitySelected;

  /// No description provided for @accessibilityCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get accessibilityCompleted;

  /// No description provided for @accessibilityIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get accessibilityIncomplete;

  /// No description provided for @accessibilityError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get accessibilityError;

  /// No description provided for @notificationFocusEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for a rest'**
  String get notificationFocusEndedTitle;

  /// No description provided for @notificationFocusEndedBody.
  ///
  /// In en, this message translates to:
  /// **'The Focus Interval has ended.'**
  String get notificationFocusEndedBody;

  /// No description provided for @notificationRestEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to focus again'**
  String get notificationRestEndedTitle;

  /// No description provided for @notificationRestEndedBody.
  ///
  /// In en, this message translates to:
  /// **'The Rest Interval has ended.'**
  String get notificationRestEndedBody;

  /// No description provided for @failureUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get failureUnknown;

  /// No description provided for @failureRouteNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested destination does not exist.'**
  String get failureRouteNotFound;

  /// No description provided for @failureRouteInvalidCalendarDate.
  ///
  /// In en, this message translates to:
  /// **'The calendar date in this link is invalid.'**
  String get failureRouteInvalidCalendarDate;

  /// No description provided for @failurePreferencesSave.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be saved. Your unsaved changes are still available.'**
  String get failurePreferencesSave;

  /// No description provided for @failureTodoLimitReached.
  ///
  /// In en, this message translates to:
  /// **'This installation has reached its Todo limit.'**
  String get failureTodoLimitReached;

  /// No description provided for @failureTodoAction.
  ///
  /// In en, this message translates to:
  /// **'The Todo action could not be completed.'**
  String get failureTodoAction;

  /// No description provided for @failureCustomSoundInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid MP3 file.'**
  String get failureCustomSoundInvalidFile;

  /// No description provided for @failureCustomSoundTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The selected MP3 file is too large.'**
  String get failureCustomSoundTooLarge;

  /// No description provided for @failureCustomSoundDecode.
  ///
  /// In en, this message translates to:
  /// **'The selected MP3 file could not be decoded.'**
  String get failureCustomSoundDecode;

  /// No description provided for @failureCustomSoundPlayback.
  ///
  /// In en, this message translates to:
  /// **'The custom sound could not be played. The bundled sound was used for this event.'**
  String get failureCustomSoundPlayback;

  /// No description provided for @failureAutoStartReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Windows automatic startup could not be updated. Review the repair action.'**
  String get failureAutoStartReconciliation;

  /// No description provided for @failureBackupFileRead.
  ///
  /// In en, this message translates to:
  /// **'The Portable Backup file could not be read.'**
  String get failureBackupFileRead;

  /// No description provided for @failureBackupFileWrite.
  ///
  /// In en, this message translates to:
  /// **'The Portable Backup file could not be written.'**
  String get failureBackupFileWrite;

  /// No description provided for @failureBackupFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The Portable Backup file is too large.'**
  String get failureBackupFileTooLarge;

  /// No description provided for @failureBackupInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not valid JSON.'**
  String get failureBackupInvalidJson;

  /// No description provided for @failureBackupAppNameMismatch.
  ///
  /// In en, this message translates to:
  /// **'This file is not a Clock Rhythm Portable Backup.'**
  String get failureBackupAppNameMismatch;

  /// No description provided for @failureBackupUnsupportedSchemaVersion.
  ///
  /// In en, this message translates to:
  /// **'This Portable Backup version is not supported.'**
  String get failureBackupUnsupportedSchemaVersion;

  /// No description provided for @failureBackupInvalidExportedAt.
  ///
  /// In en, this message translates to:
  /// **'The Portable Backup export time is invalid.'**
  String get failureBackupInvalidExportedAt;

  /// No description provided for @failureBackupMissingRequiredData.
  ///
  /// In en, this message translates to:
  /// **'The Portable Backup is missing required data.'**
  String get failureBackupMissingRequiredData;

  /// No description provided for @failureBackupInvalidPreferences.
  ///
  /// In en, this message translates to:
  /// **'The Portable Backup contains invalid Preferences.'**
  String get failureBackupInvalidPreferences;

  /// No description provided for @failureBackupTooManyTodos.
  ///
  /// In en, this message translates to:
  /// **'The Portable Backup contains too many Todos.'**
  String get failureBackupTooManyTodos;

  /// No description provided for @failureBackupReplacement.
  ///
  /// In en, this message translates to:
  /// **'Local data could not be replaced. Existing durable data was preserved, and focus/rest delivery remains Idle.'**
  String get failureBackupReplacement;

  /// No description provided for @failureBackupExport.
  ///
  /// In en, this message translates to:
  /// **'The Portable Backup could not be exported.'**
  String get failureBackupExport;

  /// No description provided for @failureDatabaseOpen.
  ///
  /// In en, this message translates to:
  /// **'The database could not be opened. The original database was preserved.'**
  String get failureDatabaseOpen;

  /// No description provided for @failureDatabaseMigration.
  ///
  /// In en, this message translates to:
  /// **'The database could not be updated. The original database was preserved.'**
  String get failureDatabaseMigration;

  /// No description provided for @failureDatabaseCorrupted.
  ///
  /// In en, this message translates to:
  /// **'The database appears to be damaged. The original database was preserved.'**
  String get failureDatabaseCorrupted;

  /// No description provided for @failureDatabaseRecoveryCopy.
  ///
  /// In en, this message translates to:
  /// **'A recovery copy could not be created, so the database was not reset.'**
  String get failureDatabaseRecoveryCopy;

  /// No description provided for @failureNotificationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to start focus/rest delivery.'**
  String get failureNotificationPermissionRequired;

  /// No description provided for @failureExactAlarmPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Exact-alarm access is required to start focus/rest delivery.'**
  String get failureExactAlarmPermissionRequired;

  /// No description provided for @failureNotificationAndExactAlarmPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission and exact-alarm access are required to start focus/rest delivery.'**
  String get failureNotificationAndExactAlarmPermissionRequired;

  /// No description provided for @failureDeliveryPermissionLost.
  ///
  /// In en, this message translates to:
  /// **'Focus/rest delivery stopped because a required permission is no longer available.'**
  String get failureDeliveryPermissionLost;

  /// No description provided for @failureDeliveryRecoveryRequired.
  ///
  /// In en, this message translates to:
  /// **'Focus/rest delivery needs recovery. Review settings and start again.'**
  String get failureDeliveryRecoveryRequired;

  /// No description provided for @failureBackupTodoIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Todo {index} in the backup has an invalid ID.'**
  String failureBackupTodoIdInvalid(int index);

  /// No description provided for @failureBackupTodoIdDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Todo {index} in the backup has a duplicate ID.'**
  String failureBackupTodoIdDuplicate(int index);

  /// No description provided for @failureBackupTodoTitleInvalid.
  ///
  /// In en, this message translates to:
  /// **'Todo {index} in the backup has an invalid title.'**
  String failureBackupTodoTitleInvalid(int index);

  /// No description provided for @failureBackupTodoDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Todo {index} in the backup has an invalid Gregorian date.'**
  String failureBackupTodoDateInvalid(int index);

  /// No description provided for @failureBackupTodoTimeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Todo {index} in the backup does not use a valid HH:mm time.'**
  String failureBackupTodoTimeInvalid(int index);

  /// No description provided for @failureBackupTodoCompletionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Todo {index} in the backup has an invalid completion value.'**
  String failureBackupTodoCompletionInvalid(int index);

  /// No description provided for @failureBackupTodoTimestampsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Todo {index} in the backup has invalid timestamps.'**
  String failureBackupTodoTimestampsInvalid(int index);

  /// No description provided for @failureBackupTodoDisplayOrderInvalid.
  ///
  /// In en, this message translates to:
  /// **'Todo {index} in the backup has an invalid display order.'**
  String failureBackupTodoDisplayOrderInvalid(int index);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
