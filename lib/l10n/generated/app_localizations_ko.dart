// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Clock Rhythm';

  @override
  String get navigationSemanticsLabel => '앱 화면';

  @override
  String get navigationClock => '시계';

  @override
  String get navigationCalendar => '캘린더';

  @override
  String get navigationData => '데이터';

  @override
  String get navigationTheme => '테마';

  @override
  String get actionClose => '닫기';

  @override
  String get actionCancel => '취소';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get actionOpenSettings => '설정 열기';

  @override
  String get actionDiscard => '변경 취소';

  @override
  String get actionSave => '저장';

  @override
  String get actionConfirm => '확인';

  @override
  String get actionReset => '초기화';

  @override
  String get actionImportPortableBackup => 'Portable Backup 가져오기';

  @override
  String get languageLabel => '언어';

  @override
  String get languageKoreanCode => 'KOR';

  @override
  String get languageEnglishCode => 'EN';

  @override
  String get languageKoreanName => '한국어';

  @override
  String get languageEnglishName => 'English';

  @override
  String get messageLanguageChanged => '언어 설정을 변경했습니다.';

  @override
  String get rhythmStatusTitle => '상태';

  @override
  String get rhythmStatusIdle => '대기';

  @override
  String get rhythmStatusRunning => '실행 중';

  @override
  String get rhythmStatusPaused => '일시정지';

  @override
  String get rhythmStatusStoppedForToday => '오늘 종료';

  @override
  String get rhythmSettingsTitle => '집중 시간대 설정';

  @override
  String get rhythmSettingsDisclosureTitle => '집중 시간대 및 알림 설정';

  @override
  String get rhythmSettingsDisclosureExpand => '집중 시간대 및 알림 설정 펼치기';

  @override
  String get rhythmSettingsDisclosureCollapse => '집중 시간대 및 알림 설정 접기';

  @override
  String get rhythmSettingsFocusMinutes => '집중 시간';

  @override
  String get rhythmSettingsRestMinutes => '휴식 시간';

  @override
  String get rhythmSettingsDailyStart => '집중 시간대 시작';

  @override
  String get rhythmSettingsDailyEnd => '집중 시간대 종료';

  @override
  String get rhythmSettingsAutoStart => 'Clock Rhythm 자동 시작';

  @override
  String get rhythmSettingsSave => '설정 저장';

  @override
  String get rhythmSettingsDiscard => '변경 취소';

  @override
  String get rhythmSettingsUnsaved => '저장하지 않은 변경 사항';

  @override
  String get rhythmSettingsDraftResetFailed => '설정은 저장했지만 임시 초안을 초기화하지 못했습니다.';

  @override
  String rhythmSettingsDecrease(String label) {
    return '$label 줄이기';
  }

  @override
  String rhythmSettingsIncrease(String label) {
    return '$label 늘리기';
  }

  @override
  String rhythmSettingsMinuteMeta(int min, int max) {
    return '분 · $min-$max';
  }

  @override
  String rhythmSettingsMinuteRange(int min, int max) {
    return '$min-$max분으로 입력해 주세요.';
  }

  @override
  String rhythmSettingsNextEvent(String time) {
    return '다음 알림: $time';
  }

  @override
  String get rhythmSettingsNextEventUnavailable => '시간 설정을 확인해 주세요.';

  @override
  String get rhythmSettingsOutsideDailyRhythm => '현재는 집중 시간대 밖입니다.';

  @override
  String rhythmSettingsDeepIdleWarning(int minimumMinutes) {
    return 'Android 절전 대기 중에는 $minimumMinutes분보다 짧은 간격이 지연되거나 건너뛸 수 있습니다.';
  }

  @override
  String rhythmSettingsSummary(
    int focus,
    int rest,
    String dailyStart,
    String dailyEnd,
    String sound,
  ) {
    return '집중 $focus분 · 휴식 $rest분 · $dailyStart-$dailyEnd · $sound';
  }

  @override
  String get rhythmSettingsSummaryDirty => '저장 필요';

  @override
  String get rhythmSettingsSummaryInvalid => '시간 설정 오류';

  @override
  String get rhythmSettingsSummaryMuted => '무음';

  @override
  String get rhythmSettingsSummaryZeroVolume => '볼륨 0%';

  @override
  String get rhythmSettingsSummaryOutsideDailyRhythm => '집중 시간대 밖';

  @override
  String get rhythmControlStart => '시작';

  @override
  String get rhythmControlPause => '일시정지';

  @override
  String get rhythmControlResume => '재개';

  @override
  String get rhythmControlStopForToday => '오늘 종료';

  @override
  String get legacyCoexistenceWarningTitle => 'Flutter 베타를 시작하기 전에';

  @override
  String get legacyCoexistenceWarningDescription =>
      '여기에서 시작하기 전에 Neutralino Clock Rhythm의 현재 집중/휴식 알림을 일시정지하고 앱을 종료해 주세요. 두 앱을 함께 실행하면 알림이 중복될 수 있습니다.';

  @override
  String get legacyCoexistenceWarningConfirm => '일시정지하고 종료했습니다';

  @override
  String get messagePreferencesSaved => '설정을 저장했습니다.';

  @override
  String get messagePreferencesFailed => '설정을 저장하지 못했습니다.';

  @override
  String get messageRhythmRunning => '집중 시간대가 실행 중입니다.';

  @override
  String get messageRhythmPaused => '집중 시간대를 일시정지했습니다.';

  @override
  String get messageRhythmResumed => '집중 시간대를 재개했습니다.';

  @override
  String get messageRhythmStoppedForToday => '현재 집중 시간대를 종료했습니다.';

  @override
  String get autoStartStatusEnabled => '자동 시작이 켜져 있습니다.';

  @override
  String get autoStartStatusDisabled => '자동 시작이 꺼져 있습니다.';

  @override
  String get autoStartStatusNeedsAction => '자동 시작 설정을 확인해 주세요.';

  @override
  String get autoStartStatusError => '자동 시작 상태를 확인하지 못했습니다.';

  @override
  String get autoStartRepair => '자동 시작 복구';

  @override
  String get soundEyebrow => '알림';

  @override
  String get soundTitle => '알림음';

  @override
  String get soundDefaultLabel => '기본';

  @override
  String get soundCustomFallback => '커스텀 MP3';

  @override
  String get soundMutedLabel => '무음';

  @override
  String get soundChooseMp3 => 'MP3 선택';

  @override
  String get soundUseDefault => '기본음 사용';

  @override
  String get soundMute => '무음';

  @override
  String get soundUnmute => '소리 켜기';

  @override
  String get soundPreview => '미리 듣기';

  @override
  String get soundStopPreview => '미리 듣기 끝내기';

  @override
  String get soundVolume => '알림음 볼륨';

  @override
  String get soundVolumeLabel => '앱 알림음 볼륨';

  @override
  String get soundZeroVolumeWarning => '볼륨이 0%입니다. 알림은 계속 표시됩니다.';

  @override
  String soundCustomRequirements(int maxMebibytes) {
    return '$maxMebibytes MiB 이하의 MP3 파일 하나를 선택해 주세요.';
  }

  @override
  String get soundRepair => '알림음 복구';

  @override
  String get messageCustomSoundChanged => '알림음을 변경했습니다.';

  @override
  String get messageSoundMuted => '무음으로 설정했습니다. 운영체제 알림은 계속 표시됩니다.';

  @override
  String get messageSoundUnmuted => '소리를 다시 켰습니다.';

  @override
  String get messageSoundPreviewStarted => '알림음을 미리 재생합니다.';

  @override
  String get messageSoundPreviewStopped => '알림음 미리 듣기를 끝냈습니다.';

  @override
  String get messageDefaultSoundRestored => '기본 알림음으로 되돌렸습니다.';

  @override
  String messageVolumeChanged(int volume) {
    return '알림음 볼륨을 $volume%로 설정했습니다.';
  }

  @override
  String get todoTodayEyebrow => '오늘';

  @override
  String get todoTodayTitle => '오늘 할 일';

  @override
  String get todoTodayInputLabel => '오늘 Todo 입력';

  @override
  String get todoTodayPlaceholder => '할 일을 적어 두세요';

  @override
  String get todoActionAddTime => '시간 추가';

  @override
  String get todoActionAdd => '추가';

  @override
  String get todoActionEdit => '수정';

  @override
  String get todoActionDelete => '삭제';

  @override
  String get todoActionSave => '저장';

  @override
  String get todoActionCancel => '취소';

  @override
  String todoActionComplete(String title) {
    return '$title 완료';
  }

  @override
  String todoActionReopen(String title) {
    return '$title 다시 열기';
  }

  @override
  String todoActionReorder(String title) {
    return '$title 순서 변경';
  }

  @override
  String get todoListEmpty => '아직 Todo가 없습니다.';

  @override
  String get todoListEditTitle => 'Todo 제목 수정';

  @override
  String get todoListEditDate => 'Todo 날짜 수정';

  @override
  String get todoListEditTime => 'Todo 시간 수정';

  @override
  String get todoGroupIncomplete => '미완료';

  @override
  String get todoGroupCompleted => '완료';

  @override
  String get todoValidationTitleRequired => '할 일을 입력해 주세요.';

  @override
  String todoValidationTitleTooLong(int max) {
    return '할 일은 $max자 이하로 입력해 주세요.';
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
      other: 'Todo $count개',
      one: 'Todo 1개',
      zero: 'Todo 없음',
    );
    return '$_temp0';
  }

  @override
  String todoCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '완료한 Todo $count개',
      one: '완료한 Todo 1개',
      zero: '완료한 Todo 없음',
    );
    return '$_temp0';
  }

  @override
  String get messageTodoAdded => 'Todo를 추가했습니다.';

  @override
  String get messageTodoUpdated => 'Todo를 수정했습니다.';

  @override
  String get messageTodoCompleted => 'Todo를 완료했습니다.';

  @override
  String get messageTodoReopened => 'Todo를 다시 열었습니다.';

  @override
  String get messageTodoDeleted => 'Todo를 삭제했습니다.';

  @override
  String get messageTodoActionFailed => 'Todo 작업을 완료하지 못했습니다.';

  @override
  String get timePickerPlaceholder => '시간 선택';

  @override
  String get timePickerDirectLabel => '직접 입력';

  @override
  String timePickerDirectInput(String label) {
    return '$label 직접 입력';
  }

  @override
  String get timePickerEditing => '입력 중';

  @override
  String get timePickerHourGroup => '시 선택';

  @override
  String get timePickerMinuteGroup => '분 선택';

  @override
  String timePickerHourOption(String hour) {
    return '$hour시';
  }

  @override
  String timePickerMinuteOption(String minute) {
    return '$minute분';
  }

  @override
  String get timePickerClear => '비우기';

  @override
  String get timePickerClose => '닫기';

  @override
  String get timePickerInvalid => '시간은 00:00부터 23:59까지 HH:mm 형식으로 입력해 주세요.';

  @override
  String get calendarEyebrow => '달력';

  @override
  String get calendarTitle => 'Todo 캘린더';

  @override
  String get calendarMonthEyebrow => '월';

  @override
  String get calendarSelectedEyebrow => '선택 날짜';

  @override
  String get calendarPreviousMonth => '이전 달';

  @override
  String get calendarNextMonth => '다음 달';

  @override
  String get calendarToday => '오늘';

  @override
  String calendarGridLabel(String month) {
    return '$month Todo 캘린더';
  }

  @override
  String calendarSelectedDateLabel(String date) {
    return '선택 날짜: $date';
  }

  @override
  String get calendarNoTodo => 'Todo 없음';

  @override
  String get calendarWeekdaySunday => '일';

  @override
  String get calendarWeekdayMonday => '월';

  @override
  String get calendarWeekdayTuesday => '화';

  @override
  String get calendarWeekdayWednesday => '수';

  @override
  String get calendarWeekdayThursday => '목';

  @override
  String get calendarWeekdayFriday => '금';

  @override
  String get calendarWeekdaySaturday => '토';

  @override
  String calendarDayTodoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Todo $count개',
      one: 'Todo 1개',
      zero: 'Todo 없음',
    );
    return '$_temp0';
  }

  @override
  String get backupEyebrow => '데이터';

  @override
  String get backupTitle => '데이터 관리';

  @override
  String get backupDescription =>
      'Preferences와 Todo를 Portable Backup으로 내보내거나 파일의 데이터로 전체 교체합니다.';

  @override
  String get backupExport => '내보내기';

  @override
  String get backupImport => '가져오기';

  @override
  String get backupPreviewTitle => 'Portable Backup 미리 보기';

  @override
  String get backupImportConfirmTitle => 'Portable Backup 가져오기';

  @override
  String get backupImportConfirmDescription =>
      '현재 Preferences와 Todo가 이 Portable Backup의 내용으로 전체 교체됩니다.';

  @override
  String get backupConfirmImport => '모든 로컬 데이터 교체';

  @override
  String get backupCancel => '취소';

  @override
  String get backupPlainTextWarning =>
      'Portable Backup은 암호로 보호되지 않은 읽을 수 있는 일반 JSON 파일입니다.';

  @override
  String get backupRhythmStopWarning =>
      '가져오기를 확인하면 이후 데이터 교체가 실패해도 현재 집중/휴식 알림은 중단됩니다.';

  @override
  String backupSummaryTodos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Todo $count개',
      one: 'Todo 1개',
      zero: 'Todo 없음',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryCompletedTodos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '완료한 Todo $count개',
      one: '완료한 Todo 1개',
      zero: '완료한 Todo 없음',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryTerms(int focus, int rest) {
    return '집중 $focus분 / 휴식 $rest분';
  }

  @override
  String backupSummaryWindow(String dailyStart, String dailyEnd) {
    return '집중 시간대: $dailyStart-$dailyEnd';
  }

  @override
  String backupSummaryLanguage(String language) {
    return '언어: $language';
  }

  @override
  String backupSummaryTheme(String theme) {
    return '테마: $theme';
  }

  @override
  String get backupSummaryAutoStartEnabled => 'Windows 자동 시작: 켬';

  @override
  String get backupSummaryAutoStartDisabled => 'Windows 자동 시작: 끔';

  @override
  String backupSummaryExportedAt(String exportedAt) {
    return '내보낸 시각: $exportedAt';
  }

  @override
  String backupSummaryDateRange(String startDate, String endDate) {
    return 'Todo 날짜: $startDate – $endDate';
  }

  @override
  String get backupSummaryNoDateRange => 'Todo 날짜: 없음';

  @override
  String get backupSummaryCustomSoundSanitized =>
      'Custom Notification Sound가 내장 기본음으로 교체됩니다.';

  @override
  String get messageBackupExported => 'Portable Backup을 내보냈습니다.';

  @override
  String get messageBackupImported => 'Portable Backup을 가져와 모든 로컬 데이터를 교체했습니다.';

  @override
  String get databaseRecoveryTitle => '데이터베이스 복구';

  @override
  String get databaseRecoveryDescription =>
      '데이터베이스를 열지 못했습니다. 기존 데이터베이스는 보존되었습니다.';

  @override
  String get databaseRecoveryRetry => '데이터베이스 다시 열기';

  @override
  String get databaseRecoveryImport => 'Portable Backup 가져오기';

  @override
  String get databaseRecoveryReset => '데이터베이스 초기화';

  @override
  String get databaseRecoveryResetTitle => '로컬 데이터베이스 초기화';

  @override
  String get databaseRecoveryResetDescription =>
      '현재 데이터베이스를 비어 있는 새 데이터베이스로 교체하기 전에 복구 사본을 만듭니다. Clock Rhythm에서는 되돌릴 수 없습니다.';

  @override
  String get databaseRecoveryConfirmReset => '복구 사본 생성 후 초기화';

  @override
  String get permissionPanelTitle => '집중/휴식 알림 권한';

  @override
  String get permissionNotificationTitle => '알림';

  @override
  String get permissionExactAlarmTitle => '정확한 알람';

  @override
  String get permissionGranted => '허용됨';

  @override
  String get permissionRequired => '필요함';

  @override
  String get permissionOpenNotificationSettings => '알림 설정 열기';

  @override
  String get permissionOpenExactAlarmSettings => '정확한 알람 설정 열기';

  @override
  String get permissionDeliveryRecoveryTitle => '집중/휴식 알림을 확인해 주세요';

  @override
  String get permissionDeliveryRecoveryDescription =>
      '권한 또는 시스템 상태가 바뀌어 알림이 중단되었습니다. 설정을 확인한 뒤 다시 시작해 주세요.';

  @override
  String get themeEyebrow => '테마';

  @override
  String get themeTitle => '테마';

  @override
  String get themeDescription => '디자인 구조는 유지하고 색상 팔레트만 바꿉니다.';

  @override
  String get themeCurrentName => '현재 유지';

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
  String get themeSelected => '선택됨';

  @override
  String get themeSelect => '테마 선택';

  @override
  String get messageThemeChanged => '테마를 변경했습니다.';

  @override
  String get routeErrorTitle => '이 화면을 열 수 없습니다';

  @override
  String get routeBackToClock => '시계로 돌아가기';

  @override
  String get trayOpen => '열기';

  @override
  String get trayPause => '일시정지';

  @override
  String get trayResume => '재개';

  @override
  String get trayStopForToday => '오늘 종료';

  @override
  String get trayQuit => 'Clock Rhythm 완전 종료';

  @override
  String get announcementRhythmRunning => '집중 시간대를 시작했습니다.';

  @override
  String get announcementRhythmPaused => '집중 시간대를 일시정지했습니다.';

  @override
  String get announcementRhythmResumed => '집중 시간대를 재개했습니다.';

  @override
  String get announcementRhythmStoppedForToday => '현재 집중 시간대를 종료했습니다.';

  @override
  String get announcementPreferencesSaved => '설정을 저장했습니다.';

  @override
  String get announcementLanguageChanged => '언어를 변경했습니다.';

  @override
  String get announcementThemeChanged => '테마를 변경했습니다.';

  @override
  String get announcementTodoAdded => 'Todo를 추가했습니다.';

  @override
  String get announcementTodoUpdated => 'Todo를 수정했습니다.';

  @override
  String get announcementTodoCompleted => 'Todo를 완료했습니다.';

  @override
  String get announcementTodoReopened => 'Todo를 다시 열었습니다.';

  @override
  String get announcementTodoDeleted => 'Todo를 삭제했습니다.';

  @override
  String get announcementBackupExported => 'Portable Backup을 내보냈습니다.';

  @override
  String get announcementBackupImported =>
      'Portable Backup을 가져와 로컬 데이터를 교체했습니다.';

  @override
  String get announcementError => '오류가 발생했습니다. 화면의 안내를 확인해 주세요.';

  @override
  String accessibilityDigitalClockLabel(String time) {
    return '현재 시각: $time';
  }

  @override
  String get accessibilitySelected => '선택됨';

  @override
  String get accessibilityCompleted => '완료';

  @override
  String get accessibilityIncomplete => '미완료';

  @override
  String get accessibilityError => '오류';

  @override
  String get notificationFocusEndedTitle => '휴식 시간입니다';

  @override
  String get notificationFocusEndedBody => '집중 시간이 끝났습니다.';

  @override
  String get notificationRestEndedTitle => '다시 집중할 시간입니다';

  @override
  String get notificationRestEndedBody => '휴식 시간이 끝났습니다.';

  @override
  String get failureUnknown => '예상하지 못한 오류가 발생했습니다.';

  @override
  String get failureRouteNotFound => '요청한 화면이 없습니다.';

  @override
  String get failureRouteInvalidCalendarDate => '링크의 캘린더 날짜가 올바르지 않습니다.';

  @override
  String get failurePreferencesSave => '설정을 저장하지 못했습니다. 저장하지 않은 변경 사항은 유지됩니다.';

  @override
  String get failureTodoLimitReached => '이 설치에서 만들 수 있는 Todo 수에 도달했습니다.';

  @override
  String get failureTodoAction => 'Todo 작업을 완료하지 못했습니다.';

  @override
  String get failureCustomSoundInvalidFile => '올바른 MP3 파일을 선택해 주세요.';

  @override
  String get failureCustomSoundTooLarge => '선택한 MP3 파일이 너무 큽니다.';

  @override
  String get failureCustomSoundDecode => '선택한 MP3 파일을 해석하지 못했습니다.';

  @override
  String get failureCustomSoundPlayback =>
      '커스텀 알림음을 재생하지 못해 이번 알림에는 내장 기본음을 사용했습니다.';

  @override
  String get failureAutoStartReconciliation =>
      'Windows 자동 시작을 갱신하지 못했습니다. 복구 작업을 확인해 주세요.';

  @override
  String get failureBackupFileRead => 'Portable Backup 파일을 읽지 못했습니다.';

  @override
  String get failureBackupFileWrite => 'Portable Backup 파일을 쓰지 못했습니다.';

  @override
  String get failureBackupFileTooLarge => 'Portable Backup 파일이 너무 큽니다.';

  @override
  String get failureBackupInvalidJson => '선택한 파일이 올바른 JSON이 아닙니다.';

  @override
  String get failureBackupAppNameMismatch =>
      'Clock Rhythm Portable Backup 파일이 아닙니다.';

  @override
  String get failureBackupUnsupportedSchemaVersion =>
      '지원하지 않는 Portable Backup 버전입니다.';

  @override
  String get failureBackupInvalidExportedAt =>
      'Portable Backup의 내보낸 시각이 올바르지 않습니다.';

  @override
  String get failureBackupMissingRequiredData =>
      'Portable Backup에 필수 데이터가 없습니다.';

  @override
  String get failureBackupInvalidPreferences =>
      'Portable Backup의 Preferences가 올바르지 않습니다.';

  @override
  String get failureBackupTooManyTodos => 'Portable Backup에 Todo가 너무 많습니다.';

  @override
  String get failureBackupReplacement =>
      '로컬 데이터를 교체하지 못했습니다. 기존 영구 데이터는 보존되었으며 집중/휴식 알림은 대기 상태입니다.';

  @override
  String get failureBackupExport => 'Portable Backup을 내보내지 못했습니다.';

  @override
  String get failureDatabaseOpen => '데이터베이스를 열지 못했습니다. 기존 데이터베이스는 보존되었습니다.';

  @override
  String get failureDatabaseMigration =>
      '데이터베이스를 업데이트하지 못했습니다. 기존 데이터베이스는 보존되었습니다.';

  @override
  String get failureDatabaseCorrupted =>
      '데이터베이스가 손상된 것으로 보입니다. 기존 데이터베이스는 보존되었습니다.';

  @override
  String get failureDatabaseRecoveryCopy =>
      '복구 사본을 만들지 못해 데이터베이스를 초기화하지 않았습니다.';

  @override
  String get failureNotificationPermissionRequired =>
      '집중/휴식 알림을 시작하려면 알림 권한이 필요합니다.';

  @override
  String get failureExactAlarmPermissionRequired =>
      '집중/휴식 알림을 시작하려면 정확한 알람 권한이 필요합니다.';

  @override
  String get failureNotificationAndExactAlarmPermissionRequired =>
      '집중/휴식 알림을 시작하려면 알림 권한과 정확한 알람 권한이 필요합니다.';

  @override
  String get failureDeliveryPermissionLost =>
      '필수 권한을 사용할 수 없어 집중/휴식 알림을 중단했습니다.';

  @override
  String get failureDeliveryRecoveryRequired =>
      '집중/휴식 알림을 복구해야 합니다. 설정을 확인하고 다시 시작해 주세요.';

  @override
  String failureBackupTodoIdInvalid(int index) {
    return '백업의 $index번째 Todo ID가 올바르지 않습니다.';
  }

  @override
  String failureBackupTodoIdDuplicate(int index) {
    return '백업의 $index번째 Todo ID가 중복됩니다.';
  }

  @override
  String failureBackupTodoTitleInvalid(int index) {
    return '백업의 $index번째 Todo 제목이 올바르지 않습니다.';
  }

  @override
  String failureBackupTodoDateInvalid(int index) {
    return '백업의 $index번째 Todo 날짜가 올바른 그레고리력 날짜가 아닙니다.';
  }

  @override
  String failureBackupTodoTimeInvalid(int index) {
    return '백업의 $index번째 Todo 시간이 올바른 HH:mm 형식이 아닙니다.';
  }

  @override
  String failureBackupTodoCompletionInvalid(int index) {
    return '백업의 $index번째 Todo 완료 값이 올바르지 않습니다.';
  }

  @override
  String failureBackupTodoTimestampsInvalid(int index) {
    return '백업의 $index번째 Todo 시각 정보가 올바르지 않습니다.';
  }

  @override
  String failureBackupTodoDisplayOrderInvalid(int index) {
    return '백업의 $index번째 Todo 표시 순서가 올바르지 않습니다.';
  }
}
