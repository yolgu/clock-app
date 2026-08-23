import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../contexts/preferences/public.dart'
    show DraftStore, RhythmSettingsDraft, RhythmSettingsDraftSnapshot;

/// Stores replaceable rhythm draft state outside the durable product database.
final class SharedPreferencesDraftStore implements DraftStore {
  SharedPreferencesDraftStore({
    SharedPreferencesAsync? preferences,
    String storageNamespace = 'clock_rhythm',
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _storageKey = '$storageNamespace.preferences.rhythm_settings_draft';

  static const int _schemaVersion = 1;
  static const String _documentKind = 'rhythm-settings-draft';
  static const Set<String> _documentKeys = <String>{
    'schemaVersion',
    'kind',
    'snapshot',
  };
  static const Set<String> _snapshotKeys = <String>{
    'focusMinutes',
    'restMinutes',
    'dailyStart',
    'dailyEnd',
    'autoStartEnabled',
  };

  final SharedPreferencesAsync _preferences;
  final String _storageKey;

  @override
  Future<RhythmSettingsDraft?> load() async {
    final String? document;
    try {
      document = await _preferences.getString(_storageKey);
    } on TypeError {
      await _removeInvalidDocument();
      return null;
    }
    if (document == null) {
      return null;
    }

    try {
      return _decode(document);
    } on FormatException {
      await _removeInvalidDocument();
      return null;
    } on ArgumentError {
      await _removeInvalidDocument();
      return null;
    }
  }

  @override
  Future<void> save(RhythmSettingsDraft draft) async {
    final RhythmSettingsDraftSnapshot snapshot = draft.snapshot();
    final String document = jsonEncode(<String, Object>{
      'schemaVersion': _schemaVersion,
      'kind': _documentKind,
      'snapshot': <String, Object>{
        'focusMinutes': snapshot.focusMinutes,
        'restMinutes': snapshot.restMinutes,
        'dailyStart': snapshot.dailyStart,
        'dailyEnd': snapshot.dailyEnd,
        'autoStartEnabled': snapshot.autoStartEnabled,
      },
    });
    await _preferences.setString(_storageKey, document);
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_storageKey);
  }

  RhythmSettingsDraft _decode(String document) {
    final Object? decoded = jsonDecode(document);
    final Object? schemaVersion = decoded is Map<String, Object?>
        ? decoded['schemaVersion']
        : null;
    if (decoded is! Map<String, Object?> ||
        !_hasExactKeys(decoded, _documentKeys) ||
        schemaVersion is! int ||
        schemaVersion != _schemaVersion ||
        decoded['kind'] != _documentKind) {
      throw const FormatException('Invalid rhythm draft document');
    }

    final Object? snapshotValue = decoded['snapshot'];
    if (snapshotValue is! Map<String, Object?> ||
        !_hasExactKeys(snapshotValue, _snapshotKeys)) {
      throw const FormatException('Invalid rhythm draft snapshot');
    }

    final Object? focusMinutes = snapshotValue['focusMinutes'];
    final Object? restMinutes = snapshotValue['restMinutes'];
    final Object? dailyStart = snapshotValue['dailyStart'];
    final Object? dailyEnd = snapshotValue['dailyEnd'];
    final Object? autoStartEnabled = snapshotValue['autoStartEnabled'];
    if (focusMinutes is! int ||
        restMinutes is! int ||
        dailyStart is! String ||
        dailyEnd is! String ||
        autoStartEnabled is! bool) {
      throw const FormatException('Invalid rhythm draft field type');
    }

    return RhythmSettingsDraft.restore(
      RhythmSettingsDraftSnapshot(
        focusMinutes: focusMinutes,
        restMinutes: restMinutes,
        dailyStart: dailyStart,
        dailyEnd: dailyEnd,
        autoStartEnabled: autoStartEnabled,
      ),
    );
  }

  bool _hasExactKeys(Map<String, Object?> value, Set<String> expected) {
    return value.length == expected.length &&
        value.keys.every(expected.contains);
  }

  Future<void> _removeInvalidDocument() async {
    try {
      await _preferences.remove(_storageKey);
    } on Object {
      // Invalid draft cleanup is best effort; durable Preferences are the fallback.
    }
  }
}
