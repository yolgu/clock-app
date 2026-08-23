import 'dart:convert';

import 'package:clock_rhythm/app/infrastructure/device_state/device_sound_locator_store.dart';
import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesDeviceSoundLocatorStore', () {
    test('round-trips selected and muted custom locators', () async {
      final MemorySharedPreferencesAsync preferences =
          MemorySharedPreferencesAsync();
      final UserPreferences selectedCustom = UserPreferences.defaults()
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'selected.mp3',
              privateSource: 'sound-v3/selected.mp3',
            ),
          );
      final UserPreferences mutedCustom = UserPreferences.defaults()
          .changeNotificationSound(
            NotificationSoundPreference.custom(
              fileName: 'muted.mp3',
              privateSource: 'sound-v2/muted.mp3',
            ),
          )
          .toggleMute(UnmuteSoundBehavior.restorePreviousSelection);
      final DeviceSoundLocatorState expected = DeviceSoundLocatorState(
        selectedCustom: DeviceSoundLocatorState.fromPreferences(
          selectedCustom,
        ).selectedCustom,
        mutedFromCustom: DeviceSoundLocatorState.fromPreferences(
          mutedCustom,
        ).mutedFromCustom,
      );

      await SharedPreferencesDeviceSoundLocatorStore(
        preferences,
      ).save(expected);
      final DeviceSoundLocatorState restored =
          await SharedPreferencesDeviceSoundLocatorStore(preferences).load();

      expect(restored, expected);
      final Object? document = jsonDecode(
        preferences.values.values.single as String,
      );
      expect(document, <String, Object?>{
        'schemaVersion': 1,
        'kind': 'device-sound-locators',
        'selectedCustom': <String, Object?>{
          'fileName': 'selected.mp3',
          'privateSource': 'sound-v3/selected.mp3',
        },
        'mutedFromCustom': <String, Object?>{
          'fileName': 'muted.mp3',
          'privateSource': 'sound-v2/muted.mp3',
        },
      });
    });

    test('keeps beta and production media locators isolated', () async {
      final MemorySharedPreferencesAsync preferences =
          MemorySharedPreferencesAsync();
      final SharedPreferencesDeviceSoundLocatorStore beta =
          SharedPreferencesDeviceSoundLocatorStore.namespaced(
            storageNamespace: 'dev.wndls.clockrhythm.beta',
            preferences: preferences,
          );
      final SharedPreferencesDeviceSoundLocatorStore production =
          SharedPreferencesDeviceSoundLocatorStore.namespaced(
            storageNamespace: 'dev.wndls.clockrhythm',
            preferences: preferences,
          );
      final DeviceSoundLocatorState betaState =
          DeviceSoundLocatorState.fromPreferences(
            UserPreferences.defaults().changeNotificationSound(
              NotificationSoundPreference.custom(
                fileName: 'beta.mp3',
                privateSource: 'beta/sound.mp3',
              ),
            ),
          );
      final DeviceSoundLocatorState productionState =
          DeviceSoundLocatorState.fromPreferences(
            UserPreferences.defaults().changeNotificationSound(
              NotificationSoundPreference.custom(
                fileName: 'production.mp3',
                privateSource: 'production/sound.mp3',
              ),
            ),
          );

      await beta.save(betaState);
      await production.save(productionState);

      expect(await beta.load(), betaState);
      expect(await production.load(), productionState);
      expect(preferences.values, hasLength(2));
    });

    test('empty state removes the replaceable locator document', () async {
      final MemorySharedPreferencesAsync preferences =
          MemorySharedPreferencesAsync()..seedValue('stale');

      await SharedPreferencesDeviceSoundLocatorStore(
        preferences,
      ).save(DeviceSoundLocatorState.empty);

      expect(preferences.values, isEmpty);
      expect(preferences.removeAttempts, 1);
    });

    test('invalid locator documents are removed and ignored', () async {
      final List<Object> invalidDocuments = <Object>[
        '{',
        jsonEncode(<String, Object?>{
          'schemaVersion': 2,
          'kind': 'device-sound-locators',
          'selectedCustom': null,
          'mutedFromCustom': null,
        }),
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'kind': 'device-sound-locators',
          'selectedCustom': <String, Object?>{
            'fileName': 'not-an-mp3.wav',
            'privateSource': 'private/sound.wav',
          },
          'mutedFromCustom': null,
        }),
        42,
      ];

      for (final Object document in invalidDocuments) {
        final MemorySharedPreferencesAsync preferences =
            MemorySharedPreferencesAsync()..seedValue(document);

        final DeviceSoundLocatorState restored =
            await SharedPreferencesDeviceSoundLocatorStore(preferences).load();

        expect(restored, DeviceSoundLocatorState.empty, reason: '$document');
        expect(preferences.values, isEmpty, reason: '$document');
      }
    });

    test('device storage failures remain visible to the caller', () async {
      final MemorySharedPreferencesAsync readFailurePreferences =
          MemorySharedPreferencesAsync()
            ..readFailure = StateError('device read failed');
      final MemorySharedPreferencesAsync writeFailurePreferences =
          MemorySharedPreferencesAsync()
            ..writeFailure = StateError('device write failed');
      final DeviceSoundLocatorState customState =
          DeviceSoundLocatorState.fromPreferences(
            UserPreferences.defaults().changeNotificationSound(
              NotificationSoundPreference.custom(
                fileName: 'selected.mp3',
                privateSource: 'sound-v3/selected.mp3',
              ),
            ),
          );

      await expectLater(
        SharedPreferencesDeviceSoundLocatorStore(readFailurePreferences).load(),
        throwsStateError,
      );
      await expectLater(
        SharedPreferencesDeviceSoundLocatorStore(
          writeFailurePreferences,
        ).save(customState),
        throwsStateError,
      );
    });
  });
}

final class MemorySharedPreferencesAsync implements SharedPreferencesAsync {
  final _MemoryPreferencesState _state = _MemoryPreferencesState();

  Map<String, Object> get values => _state.values;

  set readFailure(Object? failure) {
    _state.readFailure = failure;
  }

  set writeFailure(Object? failure) {
    _state.writeFailure = failure;
  }

  int get removeAttempts => _state.removeAttempts;

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
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async {
    return <String, Object?>{
      for (final MapEntry<String, Object> entry in values.entries)
        if (allowList == null || allowList.contains(entry.key))
          entry.key: entry.value,
    };
  }

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<double?> getDouble(String key) async => values[key] as double?;

  @override
  Future<int?> getInt(String key) async => values[key] as int?;

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
  Object? readFailure;
  Object? writeFailure;
  int removeAttempts = 0;
}
