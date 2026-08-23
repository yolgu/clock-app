import '../../../../contexts/preferences/public_model.dart';
import '../../../../contexts/todo/public_model.dart';
import '../../application/backup_failure.dart';
import 'backup_v1_dto.dart';

typedef _SoundValidationResult = ({
  NotificationSoundPreference sound,
  bool customWasSanitized,
});

abstract final class BackupV1Validator {
  static const String appName = 'Clock Rhythm';
  static const int schemaVersion = 1;
  static const int maximumTodos = Todo.maximumInstallationCount;
  static final RegExp _instantPattern = RegExp(
    r'^(?<date>\d{4}-\d{2}-\d{2})T'
    r'(?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2})'
    r'(?:\.\d{1,6})?'
    r'(?:[zZ]|[+-](?:[01]\d|2[0-3]):[0-5]\d)$',
  );

  static BackupV1DocumentDto validate(Object? decoded) {
    final Map<String, Object?> envelope = _object(
      decoded,
      BackupFailureKey.missingRequiredData,
    );
    if (_string(envelope, 'appName', BackupFailureKey.appNameMismatch) !=
        appName) {
      _fail(BackupFailureKey.appNameMismatch);
    }
    final Object? version = envelope['schemaVersion'];
    if (version is! int || version != schemaVersion) {
      _fail(BackupFailureKey.unsupportedSchemaVersion);
    }
    final DateTime exportedAt = _instant(
      _string(envelope, 'exportedAt', BackupFailureKey.invalidExportedAt),
      BackupFailureKey.invalidExportedAt,
    );
    final Map<String, Object?> preferencesMap = _object(
      _required(envelope, 'preferences'),
      BackupFailureKey.invalidPreferences,
    );
    final ({UserPreferences preferences, bool customWasSanitized})
    preferencesResult = _preferences(preferencesMap);
    final List<Object?> todoValues = _array(
      _required(envelope, 'todos'),
      BackupFailureKey.missingRequiredData,
    );
    if (todoValues.length > maximumTodos) {
      _fail(BackupFailureKey.tooManyTodos);
    }
    final Set<String> identifiers = <String>{};
    final List<Todo> todos = <Todo>[];
    for (int index = 0; index < todoValues.length; index += 1) {
      todos.add(_todo(todoValues[index], index, identifiers));
    }
    return BackupV1DocumentDto(
      exportedAt: exportedAt,
      preferences: preferencesResult.preferences,
      todos: todos,
      customSoundWasSanitized: preferencesResult.customWasSanitized,
    );
  }

  static ({UserPreferences preferences, bool customWasSanitized}) _preferences(
    Map<String, Object?> values,
  ) {
    try {
      final int focusMinutes = _integer(
        values,
        'focusMinutes',
        BackupFailureKey.invalidPreferences,
      );
      final int restMinutes = _integer(
        values,
        'restMinutes',
        BackupFailureKey.invalidPreferences,
      );
      final String dailyStart = _string(
        values,
        'dailyStart',
        BackupFailureKey.invalidPreferences,
      );
      final String dailyEnd = _string(
        values,
        'dailyEnd',
        BackupFailureKey.invalidPreferences,
      );
      final bool autoStartEnabled = _boolean(
        values,
        'autoStartEnabled',
        BackupFailureKey.invalidPreferences,
      );
      final LanguagePreference language = values.containsKey('language')
          ? LanguagePreference.parse(
              _string(values, 'language', BackupFailureKey.invalidPreferences),
            )
          : LanguagePreference.korean;
      final ThemePreference theme = values.containsKey('theme')
          ? ThemePreference.parse(
              _string(values, 'theme', BackupFailureKey.invalidPreferences),
            )
          : ThemePreference.current;
      final bool initialSetupCompleted =
          values.containsKey('initialSetupCompleted')
          ? _boolean(
              values,
              'initialSetupCompleted',
              BackupFailureKey.invalidPreferences,
            )
          : false;
      final _SoundValidationResult soundResult = _notificationSound(values);
      final UserPreferences preferences = UserPreferences.restore(
        UserPreferencesSnapshot(
          focusMinutes: focusMinutes,
          restMinutes: restMinutes,
          dailyStart: dailyStart,
          dailyEnd: dailyEnd,
          autoStartEnabled: autoStartEnabled,
          notificationSound: soundResult.sound.snapshot(),
          language: language,
          theme: theme,
          initialSetupCompleted: initialSetupCompleted,
        ),
      );
      return (
        preferences: preferences,
        customWasSanitized: soundResult.customWasSanitized,
      );
    } on BackupFailure {
      rethrow;
    } on Object {
      _fail(BackupFailureKey.invalidPreferences);
    }
  }

  static _SoundValidationResult _notificationSound(
    Map<String, Object?> preferences,
  ) {
    if (!preferences.containsKey('notificationSound')) {
      return (
        sound: NotificationSoundPreference.bundledDefault(),
        customWasSanitized: false,
      );
    }
    final Map<String, Object?> values = _object(
      preferences['notificationSound'],
      BackupFailureKey.invalidPreferences,
    );
    final NotificationSoundMode mode = NotificationSoundMode.parse(
      _string(values, 'mode', BackupFailureKey.invalidPreferences),
    );
    final double volume = values.containsKey('volume')
        ? _number(values, 'volume', BackupFailureKey.invalidPreferences)
        : 1;
    return switch (mode) {
      NotificationSoundMode.bundledDefault => _defaultSound(values, volume),
      NotificationSoundMode.custom => _customSound(values, volume),
      NotificationSoundMode.muted => _mutedSound(values, volume),
    };
  }

  static _SoundValidationResult _defaultSound(
    Map<String, Object?> values,
    double volume,
  ) {
    _requireNullIfPresent(values, 'customFileName');
    _requireNullIfPresent(values, 'customSource');
    _requireNullIfPresent(values, 'mutedFrom');
    return (
      sound: NotificationSoundPreference.bundledDefault(volume: volume),
      customWasSanitized: false,
    );
  }

  static _SoundValidationResult _customSound(
    Map<String, Object?> values,
    double volume,
  ) {
    NotificationSoundPreference.custom(
      fileName: _string(
        values,
        'customFileName',
        BackupFailureKey.invalidPreferences,
      ),
      privateSource: _string(
        values,
        'customSource',
        BackupFailureKey.invalidPreferences,
      ),
      volume: volume,
    );
    _requireNullIfPresent(values, 'mutedFrom');
    return (
      sound: NotificationSoundPreference.bundledDefault(volume: volume),
      customWasSanitized: true,
    );
  }

  static _SoundValidationResult _mutedSound(
    Map<String, Object?> values,
    double volume,
  ) {
    _requireNullIfPresent(values, 'customFileName');
    _requireNullIfPresent(values, 'customSource');
    AudibleNotificationSoundSelection? mutedFrom;
    bool sanitized = false;
    if (values.containsKey('mutedFrom') && values['mutedFrom'] != null) {
      final Map<String, Object?> previous = _object(
        values['mutedFrom'],
        BackupFailureKey.invalidPreferences,
      );
      final NotificationSoundMode previousMode = NotificationSoundMode.parse(
        _string(previous, 'mode', BackupFailureKey.invalidPreferences),
      );
      switch (previousMode) {
        case NotificationSoundMode.bundledDefault:
          _requireNullIfPresent(previous, 'customFileName');
          _requireNullIfPresent(previous, 'customSource');
          mutedFrom = AudibleNotificationSoundSelection.bundledDefault();
        case NotificationSoundMode.custom:
          AudibleNotificationSoundSelection.custom(
            fileName: _string(
              previous,
              'customFileName',
              BackupFailureKey.invalidPreferences,
            ),
            privateSource: _string(
              previous,
              'customSource',
              BackupFailureKey.invalidPreferences,
            ),
          );
          mutedFrom = AudibleNotificationSoundSelection.bundledDefault();
          sanitized = true;
        case NotificationSoundMode.muted:
          _fail(BackupFailureKey.invalidPreferences);
      }
    }
    final NotificationSoundPreference sound =
        NotificationSoundPreference.restore(
          NotificationSoundSnapshot(
            mode: NotificationSoundMode.muted,
            customFileName: null,
            privateSource: null,
            volume: volume,
            mutedFrom: mutedFrom,
          ),
        );
    return (sound: sound, customWasSanitized: sanitized);
  }

  static Todo _todo(Object? value, int index, Set<String> identifiers) {
    final Map<String, Object?> values = _object(
      value,
      BackupFailureKey.missingRequiredData,
      index,
    );
    final String id = _indexedString(
      values,
      'id',
      BackupFailureKey.todoIdInvalid,
      index,
    );
    try {
      TodoId.parse(id);
    } on Object {
      _fail(BackupFailureKey.todoIdInvalid, index);
    }
    if (!identifiers.add(id)) {
      _fail(BackupFailureKey.todoIdDuplicate, index);
    }
    final String title = _indexedString(
      values,
      'title',
      BackupFailureKey.todoTitleInvalid,
      index,
    );
    try {
      TodoTitle.parse(title);
    } on Object {
      _fail(BackupFailureKey.todoTitleInvalid, index);
    }
    final String date = _indexedString(
      values,
      'date',
      BackupFailureKey.todoDateInvalid,
      index,
    );
    try {
      LocalCalendarDate.parse(date);
    } on Object {
      _fail(BackupFailureKey.todoDateInvalid, index);
    }
    final String? time = _optionalIndexedString(
      values,
      'time',
      BackupFailureKey.todoTimeInvalid,
      index,
    );
    try {
      TodoTime.optional(time);
    } on Object {
      _fail(BackupFailureKey.todoTimeInvalid, index);
    }
    final Object? completedValue = values['completed'];
    if (!values.containsKey('completed') || completedValue is! bool) {
      _fail(BackupFailureKey.todoCompletionInvalid, index);
    }
    final int? displayOrder = values.containsKey('displayOrder')
        ? _indexedInteger(
            values,
            'displayOrder',
            BackupFailureKey.todoDisplayOrderInvalid,
            index,
          )
        : null;
    if (displayOrder != null && displayOrder < 0) {
      _fail(BackupFailureKey.todoDisplayOrderInvalid, index);
    }
    final String createdAt = _indexedString(
      values,
      'createdAt',
      BackupFailureKey.todoTimestampsInvalid,
      index,
    );
    final String updatedAt = _indexedString(
      values,
      'updatedAt',
      BackupFailureKey.todoTimestampsInvalid,
      index,
    );
    try {
      return Todo.restore(
        TodoRestoreSnapshot(
          id: id,
          title: title,
          date: date,
          time: time,
          completed: completedValue,
          displayOrder: displayOrder,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    } on Object {
      _fail(BackupFailureKey.todoTimestampsInvalid, index);
    }
  }

  static DateTime _instant(String text, BackupFailureKey key) {
    final RegExpMatch? match = _instantPattern.firstMatch(text);
    if (match == null) {
      _fail(key);
    }
    try {
      LocalCalendarDate.parse(match.namedGroup('date')!);
    } on Object {
      _fail(key);
    }
    final int hour = int.parse(match.namedGroup('hour')!);
    final int minute = int.parse(match.namedGroup('minute')!);
    final int second = int.parse(match.namedGroup('second')!);
    if (hour > 23 || minute > 59 || second > 59) {
      _fail(key);
    }
    final DateTime? value = DateTime.tryParse(text);
    if (value == null || !value.isUtc) {
      _fail(key);
    }
    return value.toUtc();
  }

  static Object? _required(Map<String, Object?> values, String key) {
    if (!values.containsKey(key)) {
      _fail(BackupFailureKey.missingRequiredData);
    }
    return values[key];
  }

  static Map<String, Object?> _object(
    Object? value,
    BackupFailureKey key, [
    int? index,
  ]) {
    if (value is! Map<Object?, Object?>) {
      _fail(key, index);
    }
    final Map<String, Object?> result = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      if (entry.key is! String) {
        _fail(key, index);
      }
      result[entry.key! as String] = entry.value;
    }
    return result;
  }

  static List<Object?> _array(Object? value, BackupFailureKey key) {
    if (value is! List<Object?>) {
      _fail(key);
    }
    return value;
  }

  static String _string(
    Map<String, Object?> values,
    String field,
    BackupFailureKey key,
  ) {
    final Object? value = values[field];
    if (!values.containsKey(field) || value is! String) {
      _fail(key);
    }
    return value;
  }

  static String _indexedString(
    Map<String, Object?> values,
    String field,
    BackupFailureKey key,
    int index,
  ) {
    final Object? value = values[field];
    if (!values.containsKey(field) || value is! String) {
      _fail(key, index);
    }
    return value;
  }

  static String? _optionalIndexedString(
    Map<String, Object?> values,
    String field,
    BackupFailureKey key,
    int index,
  ) {
    if (!values.containsKey(field) || values[field] == null) {
      return null;
    }
    final Object? value = values[field];
    if (value is! String) {
      _fail(key, index);
    }
    return value;
  }

  static int _integer(
    Map<String, Object?> values,
    String field,
    BackupFailureKey key,
  ) {
    final Object? value = values[field];
    if (!values.containsKey(field) || value is! int) {
      _fail(key);
    }
    return value;
  }

  static int _indexedInteger(
    Map<String, Object?> values,
    String field,
    BackupFailureKey key,
    int index,
  ) {
    final Object? value = values[field];
    if (!values.containsKey(field) || value is! int) {
      _fail(key, index);
    }
    return value;
  }

  static double _number(
    Map<String, Object?> values,
    String field,
    BackupFailureKey key,
  ) {
    final Object? value = values[field];
    if (!values.containsKey(field) || value is! num || !value.isFinite) {
      _fail(key);
    }
    return value.toDouble();
  }

  static bool _boolean(
    Map<String, Object?> values,
    String field,
    BackupFailureKey key,
  ) {
    final Object? value = values[field];
    if (!values.containsKey(field) || value is! bool) {
      _fail(key);
    }
    return value;
  }

  static void _requireNullIfPresent(Map<String, Object?> values, String field) {
    if (values.containsKey(field) && values[field] != null) {
      _fail(BackupFailureKey.invalidPreferences);
    }
  }

  static Never _fail(BackupFailureKey key, [int? index]) {
    throw BackupFailure(key: key, zeroBasedTodoIndex: index);
  }
}
