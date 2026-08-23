import 'dart:convert';

import 'package:clock_rhythm/app/infrastructure/device_state/shared_preferences_draft_store.dart';
import 'package:clock_rhythm/contexts/preferences/domain/rhythm_settings_draft.dart';
import 'package:clock_rhythm/contexts/preferences/domain/user_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesDraftStore', () {
    test('persists the snapshot as versioned JSON across instances', () async {
      final MemorySharedPreferencesAsync preferences =
          MemorySharedPreferencesAsync();
      final RhythmSettingsDraft expected =
          RhythmSettingsDraft.fromPreferences(UserPreferences.defaults())
              .changeFocusMinutes(25)
              .changeRestMinutes(5)
              .changeDailyRhythm(start: '08:30', end: '17:45')
              .changeAutoStart(true);

      await SharedPreferencesDraftStore(
        preferences: preferences,
      ).save(expected);
      final RhythmSettingsDraft? restored = await SharedPreferencesDraftStore(
        preferences: preferences,
      ).load();

      expect(restored, expected);
      expect(preferences.values, hasLength(1));
      final Object encoded = preferences.values.values.single;
      expect(encoded, isA<String>());
      expect(jsonDecode(encoded as String), <String, Object>{
        'schemaVersion': 1,
        'kind': 'rhythm-settings-draft',
        'snapshot': <String, Object>{
          'focusMinutes': 25,
          'restMinutes': 5,
          'dailyStart': '08:30',
          'dailyEnd': '17:45',
          'autoStartEnabled': true,
        },
      });
    });

    test('keeps beta and production drafts in separate namespaces', () async {
      final MemorySharedPreferencesAsync preferences =
          MemorySharedPreferencesAsync();
      final SharedPreferencesDraftStore beta = SharedPreferencesDraftStore(
        preferences: preferences,
        storageNamespace: 'dev.wndls.clockrhythm.beta',
      );
      final SharedPreferencesDraftStore production =
          SharedPreferencesDraftStore(
            preferences: preferences,
            storageNamespace: 'dev.wndls.clockrhythm',
          );
      final RhythmSettingsDraft betaDraft = RhythmSettingsDraft.fromPreferences(
        UserPreferences.defaults(),
      ).changeFocusMinutes(25);
      final RhythmSettingsDraft productionDraft =
          RhythmSettingsDraft.fromPreferences(
            UserPreferences.defaults(),
          ).changeFocusMinutes(50);

      await beta.save(betaDraft);
      await production.save(productionDraft);

      expect(await beta.load(), betaDraft);
      expect(await production.load(), productionDraft);
      expect(preferences.values, hasLength(2));
    });

    test('returns null without writing when no draft exists', () async {
      final MemorySharedPreferencesAsync preferences =
          MemorySharedPreferencesAsync();

      final RhythmSettingsDraft? restored = await SharedPreferencesDraftStore(
        preferences: preferences,
      ).load();

      expect(restored, isNull);
      expect(preferences.removedKeys, isEmpty);
    });

    test('clear removes the device-only draft document', () async {
      final MemorySharedPreferencesAsync preferences =
          MemorySharedPreferencesAsync();
      final SharedPreferencesDraftStore store = SharedPreferencesDraftStore(
        preferences: preferences,
      );
      await store.save(
        RhythmSettingsDraft.fromPreferences(UserPreferences.defaults()),
      );

      await store.clear();

      expect(await store.load(), isNull);
      expect(preferences.values, isEmpty);
    });

    test('removes and ignores malformed or domain-invalid JSON', () async {
      final List<String> invalidDocuments = <String>[
        '{',
        '[]',
        jsonEncode(<String, Object>{
          'schemaVersion': 2,
          'kind': 'rhythm-settings-draft',
          'snapshot': _validSnapshot(),
        }),
        jsonEncode(<String, Object>{
          'schemaVersion': 1.0,
          'kind': 'rhythm-settings-draft',
          'snapshot': _validSnapshot(),
        }),
        jsonEncode(<String, Object>{
          'schemaVersion': 1,
          'kind': 'another-value',
          'snapshot': _validSnapshot(),
        }),
        jsonEncode(<String, Object>{
          'schemaVersion': 1,
          'kind': 'rhythm-settings-draft',
          'snapshot': <String, Object>{
            ..._validSnapshot(),
            'focusMinutes': '50',
          },
        }),
        jsonEncode(<String, Object>{
          'schemaVersion': 1,
          'kind': 'rhythm-settings-draft',
          'snapshot': <String, Object>{..._validSnapshot(), 'focusMinutes': 0},
        }),
        jsonEncode(<String, Object>{
          'schemaVersion': 1,
          'kind': 'rhythm-settings-draft',
          'snapshot': <String, Object>{
            ..._validSnapshot(),
            'dailyEnd': '05:00',
          },
        }),
        jsonEncode(<String, Object>{
          'schemaVersion': 1,
          'kind': 'rhythm-settings-draft',
          'snapshot': <String, Object>{..._validSnapshot(), 'unexpected': true},
        }),
      ];

      for (final String document in invalidDocuments) {
        final MemorySharedPreferencesAsync preferences =
            MemorySharedPreferencesAsync()..seedString(document);

        final RhythmSettingsDraft? restored = await SharedPreferencesDraftStore(
          preferences: preferences,
        ).load();

        expect(restored, isNull, reason: document);
        expect(preferences.values, isEmpty, reason: document);
        expect(preferences.removedKeys, hasLength(1), reason: document);
      }
    });

    test('removes and ignores a non-string value at the draft key', () async {
      final MemorySharedPreferencesAsync preferences =
          MemorySharedPreferencesAsync()..seedValue(1);

      final RhythmSettingsDraft? restored = await SharedPreferencesDraftStore(
        preferences: preferences,
      ).load();

      expect(restored, isNull);
      expect(preferences.values, isEmpty);
      expect(preferences.removedKeys, hasLength(1));
    });

    test('ignores corrupt data even when best-effort cleanup fails', () async {
      final MemorySharedPreferencesAsync preferences =
          MemorySharedPreferencesAsync()
            ..seedString('{')
            ..removeFailure = StateError('device state is read-only');

      final RhythmSettingsDraft? restored = await SharedPreferencesDraftStore(
        preferences: preferences,
      ).load();

      expect(restored, isNull);
      expect(preferences.removeAttempts, 1);
    });

    test('propagates device read and write failures', () async {
      final MemorySharedPreferencesAsync readFailurePreferences =
          MemorySharedPreferencesAsync()
            ..readFailure = StateError('read unavailable');
      final MemorySharedPreferencesAsync writeFailurePreferences =
          MemorySharedPreferencesAsync()
            ..writeFailure = StateError('write unavailable');
      final RhythmSettingsDraft draft = RhythmSettingsDraft.fromPreferences(
        UserPreferences.defaults(),
      );

      await expectLater(
        SharedPreferencesDraftStore(preferences: readFailurePreferences).load(),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        SharedPreferencesDraftStore(
          preferences: writeFailurePreferences,
        ).save(draft),
        throwsA(isA<StateError>()),
      );
    });
  });
}

Map<String, Object> _validSnapshot() {
  return <String, Object>{
    'focusMinutes': 50,
    'restMinutes': 10,
    'dailyStart': '05:00',
    'dailyEnd': '18:00',
    'autoStartEnabled': false,
  };
}

final class MemorySharedPreferencesAsync implements SharedPreferencesAsync {
  final _MemoryPreferencesState _state = _MemoryPreferencesState();

  Map<String, Object> get values => _state.values;

  List<String> get removedKeys => _state.removedKeys;

  int get removeAttempts => _state.removeAttempts;

  set readFailure(Object? failure) {
    _state.readFailure = failure;
  }

  set writeFailure(Object? failure) {
    _state.writeFailure = failure;
  }

  set removeFailure(Object? failure) {
    _state.removeFailure = failure;
  }

  void seedString(String value) {
    seedValue(value);
  }

  void seedValue(Object value) {
    values['seed'] = value;
  }

  @override
  Future<void> clear({Set<String>? allowList}) async {
    final Iterable<String> keys = allowList ?? values.keys.toList();
    for (final String key in keys) {
      values.remove(key);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    return values.containsKey(key);
  }

  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async {
    final Iterable<MapEntry<String, Object>> entries = allowList == null
        ? values.entries
        : values.entries.where(
            (MapEntry<String, Object> entry) => allowList.contains(entry.key),
          );
    return <String, Object?>{
      for (final MapEntry<String, Object> entry in entries)
        entry.key: entry.value,
    };
  }

  @override
  Future<bool?> getBool(String key) async {
    return values[key] as bool?;
  }

  @override
  Future<double?> getDouble(String key) async {
    return values[key] as double?;
  }

  @override
  Future<int?> getInt(String key) async {
    return values[key] as int?;
  }

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async {
    return values.keys
        .where((String key) => allowList == null || allowList.contains(key))
        .toSet();
  }

  @override
  Future<String?> getString(String key) async {
    final Object? failure = _state.readFailure;
    if (failure != null) {
      throw failure;
    }
    if (values.length == 1 && !values.containsKey(key)) {
      return values.values.single as String?;
    }
    return values[key] as String?;
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    return values[key] as List<String>?;
  }

  @override
  Future<void> remove(String key) async {
    _state.removeAttempts += 1;
    final Object? failure = _state.removeFailure;
    if (failure != null) {
      throw failure;
    }
    removedKeys.add(key);
    if (values.length == 1 && !values.containsKey(key)) {
      values.clear();
      return;
    }
    values.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    values[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    values[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    final Object? failure = _state.writeFailure;
    if (failure != null) {
      throw failure;
    }
    values[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    values[key] = List<String>.unmodifiable(value);
  }
}

final class _MemoryPreferencesState {
  final Map<String, Object> values = <String, Object>{};
  final List<String> removedKeys = <String>[];
  Object? readFailure;
  Object? writeFailure;
  Object? removeFailure;
  int removeAttempts = 0;
}
