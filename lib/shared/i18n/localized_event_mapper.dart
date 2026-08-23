import '../../l10n/generated/app_localizations.dart';

enum LocalizedEventKey {
  trayOpen('tray.open'),
  trayPause('tray.pause'),
  trayResume('tray.resume'),
  trayStopForToday('tray.stopForToday'),
  trayQuit('tray.quit'),
  announcementRhythmRunning('accessibility.rhythm.running'),
  announcementRhythmPaused('accessibility.rhythm.paused'),
  announcementRhythmResumed('accessibility.rhythm.resumed'),
  announcementRhythmStoppedForToday('accessibility.rhythm.stoppedForToday'),
  announcementPreferencesSaved('accessibility.preferences.saved'),
  announcementLanguageChanged('accessibility.language.changed'),
  announcementThemeChanged('accessibility.theme.changed'),
  announcementTodoAdded('accessibility.todo.added'),
  announcementTodoUpdated('accessibility.todo.updated'),
  announcementTodoCompleted('accessibility.todo.completed'),
  announcementTodoReopened('accessibility.todo.reopened'),
  announcementTodoDeleted('accessibility.todo.deleted'),
  announcementBackupExported('accessibility.backup.exported'),
  announcementBackupImported('accessibility.backup.imported'),
  announcementError('accessibility.error');

  const LocalizedEventKey(this.stableKey);

  final String stableKey;
}

enum RhythmNotificationEvent { focusEnded, restEnded }

final class LocalizedNotificationPayload {
  const LocalizedNotificationPayload({required this.title, required this.body});

  final String title;
  final String body;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LocalizedNotificationPayload &&
            title == other.title &&
            body == other.body;
  }

  @override
  int get hashCode => Object.hash(title, body);
}

final class LocalizedEventMapper {
  const LocalizedEventMapper(this._localizations);

  final AppLocalizations _localizations;

  String message(LocalizedEventKey key) {
    return switch (key) {
      LocalizedEventKey.trayOpen => _localizations.trayOpen,
      LocalizedEventKey.trayPause => _localizations.trayPause,
      LocalizedEventKey.trayResume => _localizations.trayResume,
      LocalizedEventKey.trayStopForToday => _localizations.trayStopForToday,
      LocalizedEventKey.trayQuit => _localizations.trayQuit,
      LocalizedEventKey.announcementRhythmRunning =>
        _localizations.announcementRhythmRunning,
      LocalizedEventKey.announcementRhythmPaused =>
        _localizations.announcementRhythmPaused,
      LocalizedEventKey.announcementRhythmResumed =>
        _localizations.announcementRhythmResumed,
      LocalizedEventKey.announcementRhythmStoppedForToday =>
        _localizations.announcementRhythmStoppedForToday,
      LocalizedEventKey.announcementPreferencesSaved =>
        _localizations.announcementPreferencesSaved,
      LocalizedEventKey.announcementLanguageChanged =>
        _localizations.announcementLanguageChanged,
      LocalizedEventKey.announcementThemeChanged =>
        _localizations.announcementThemeChanged,
      LocalizedEventKey.announcementTodoAdded =>
        _localizations.announcementTodoAdded,
      LocalizedEventKey.announcementTodoUpdated =>
        _localizations.announcementTodoUpdated,
      LocalizedEventKey.announcementTodoCompleted =>
        _localizations.announcementTodoCompleted,
      LocalizedEventKey.announcementTodoReopened =>
        _localizations.announcementTodoReopened,
      LocalizedEventKey.announcementTodoDeleted =>
        _localizations.announcementTodoDeleted,
      LocalizedEventKey.announcementBackupExported =>
        _localizations.announcementBackupExported,
      LocalizedEventKey.announcementBackupImported =>
        _localizations.announcementBackupImported,
      LocalizedEventKey.announcementError => _localizations.announcementError,
    };
  }

  LocalizedNotificationPayload notificationPayload(
    RhythmNotificationEvent event,
  ) {
    return switch (event) {
      RhythmNotificationEvent.focusEnded => LocalizedNotificationPayload(
        title: _localizations.notificationFocusEndedTitle,
        body: _localizations.notificationFocusEndedBody,
      ),
      RhythmNotificationEvent.restEnded => LocalizedNotificationPayload(
        title: _localizations.notificationRestEndedTitle,
        body: _localizations.notificationRestEndedBody,
      ),
    };
  }
}
