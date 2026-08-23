import 'dart:convert';

import '../../../../contexts/preferences/public_model.dart';
import '../../../../contexts/todo/public_model.dart';
import '../../application/backup_failure.dart';
import '../../application/ports.dart';
import 'backup_v1_dto.dart';
import 'backup_v1_validator.dart';

final class BackupV1Codec implements PortableBackupCodec {
  const BackupV1Codec();

  static const int maximumBytes = 32 * 1024 * 1024;

  @override
  int get maximumFileBytes => maximumBytes;

  @override
  PortableBackupData decode(List<int> bytes) {
    if (bytes.length > maximumBytes) {
      throw const BackupFailure(key: BackupFailureKey.fileTooLarge);
    }
    final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const BackupFailure(key: BackupFailureKey.invalidEncoding);
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text) as Object?;
    } on FormatException {
      throw const BackupFailure(key: BackupFailureKey.invalidJson);
    }
    final BackupV1DocumentDto document = BackupV1Validator.validate(decoded);
    return PortableBackupData(
      exportedAt: document.exportedAt,
      preferences: document.preferences,
      todos: document.todos,
      customSoundWasSanitized: document.customSoundWasSanitized,
    );
  }

  @override
  List<int> encode(PortableBackupData data) {
    if (data.todos.length > BackupV1Validator.maximumTodos) {
      throw const BackupFailure(key: BackupFailureKey.tooManyTodos);
    }
    final UserPreferences portablePreferences = _portablePreferences(
      data.preferences,
    );
    final Map<String, Object?> envelope = <String, Object?>{
      'appName': BackupV1Validator.appName,
      'schemaVersion': BackupV1Validator.schemaVersion,
      'exportedAt': data.exportedAt.toUtc().toIso8601String(),
      'preferences': _preferencesMap(portablePreferences),
      'todos': data.todos
          .map((Todo todo) => _todoMap(todo.snapshot()))
          .toList(growable: false),
    };
    final List<int> bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(envelope),
    );
    if (bytes.length > maximumBytes) {
      throw const BackupFailure(key: BackupFailureKey.fileTooLarge);
    }
    return List<int>.unmodifiable(bytes);
  }

  static UserPreferences _portablePreferences(UserPreferences preferences) {
    final NotificationSoundPreference sound = preferences.notificationSound;
    final NotificationSoundPreference portableSound;
    if (sound.mode == NotificationSoundMode.custom) {
      portableSound = NotificationSoundPreference.bundledDefault(
        volume: sound.volume,
      );
    } else if (sound.mode == NotificationSoundMode.muted &&
        sound.mutedFrom?.mode == NotificationSoundMode.custom) {
      portableSound = NotificationSoundPreference.restore(
        NotificationSoundSnapshot(
          mode: NotificationSoundMode.muted,
          customFileName: null,
          privateSource: null,
          volume: sound.volume,
          mutedFrom: AudibleNotificationSoundSelection.bundledDefault(),
        ),
      );
    } else {
      portableSound = sound;
    }
    return preferences.changeNotificationSound(portableSound);
  }

  static Map<String, Object?> _preferencesMap(UserPreferences preferences) {
    final UserPreferencesSnapshot snapshot = preferences.snapshot();
    final NotificationSoundSnapshot sound = snapshot.notificationSound;
    return <String, Object?>{
      'focusMinutes': snapshot.focusMinutes,
      'restMinutes': snapshot.restMinutes,
      'dailyStart': snapshot.dailyStart,
      'dailyEnd': snapshot.dailyEnd,
      'autoStartEnabled': snapshot.autoStartEnabled,
      'notificationSound': <String, Object?>{
        'mode': sound.mode.id,
        'customFileName': sound.customFileName,
        'customSource': sound.privateSource,
        'mutedFrom': switch (sound.mutedFrom) {
          null => null,
          final AudibleNotificationSoundSelection selection =>
            <String, Object?>{
              'mode': selection.mode.id,
              'customFileName': selection.customFileName,
              'customSource': selection.privateSource,
            },
        },
        'volume': sound.volume,
      },
      'language': snapshot.language.id,
      'theme': snapshot.theme.id,
      'initialSetupCompleted': snapshot.initialSetupCompleted,
    };
  }

  static Map<String, Object?> _todoMap(TodoSnapshot snapshot) {
    return <String, Object?>{
      'id': snapshot.id,
      'title': snapshot.title,
      'date': snapshot.date,
      'time': snapshot.time,
      'completed': snapshot.completed,
      'displayOrder': snapshot.displayOrder,
      'createdAt': snapshot.createdAt,
      'updatedAt': snapshot.updatedAt,
    };
  }
}
