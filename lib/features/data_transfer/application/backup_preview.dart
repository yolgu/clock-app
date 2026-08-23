final class BackupPreview {
  const BackupPreview({
    required this.exportedAt,
    required this.todoCount,
    required this.completedTodoCount,
    required this.earliestTodoDate,
    required this.latestTodoDate,
    required this.focusMinutes,
    required this.restMinutes,
    required this.dailyStart,
    required this.dailyEnd,
    required this.languageId,
    required this.themeId,
    required this.autoStartEnabled,
    required this.autoStartWillChange,
    required this.customSoundWasSanitized,
  });

  final DateTime exportedAt;
  final int todoCount;
  final int completedTodoCount;
  final String? earliestTodoDate;
  final String? latestTodoDate;
  final int focusMinutes;
  final int restMinutes;
  final String dailyStart;
  final String dailyEnd;
  final String languageId;
  final String themeId;
  final bool autoStartEnabled;
  final bool autoStartWillChange;
  final bool customSoundWasSanitized;
}
