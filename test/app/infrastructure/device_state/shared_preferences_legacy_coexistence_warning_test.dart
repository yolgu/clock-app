import 'package:clock_rhythm/app/infrastructure/device_state/shared_preferences_legacy_coexistence_warning.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('acknowledgement is durable and isolated by flavor namespace', () async {
    final _MemorySharedPreferencesAsync preferences =
        _MemorySharedPreferencesAsync();
    final SharedPreferencesLegacyCoexistenceWarning beta =
        SharedPreferencesLegacyCoexistenceWarning(
          storageNamespace: 'dev.wndls.clockrhythm.beta',
          preferences: preferences,
        );
    final SharedPreferencesLegacyCoexistenceWarning production =
        SharedPreferencesLegacyCoexistenceWarning(
          storageNamespace: 'dev.wndls.clockrhythm',
          preferences: preferences,
        );

    expect(await beta.shouldWarnBeforeStart(), isTrue);
    expect(await production.shouldWarnBeforeStart(), isTrue);

    await beta.acknowledge();

    expect(await beta.shouldWarnBeforeStart(), isFalse);
    expect(await production.shouldWarnBeforeStart(), isTrue);
  });
}

final class _MemorySharedPreferencesAsync implements SharedPreferencesAsync {
  final Map<String, Object> values = <String, Object>{};

  @override
  Future<void> clear({Set<String>? allowList}) async {
    values.removeWhere(
      (String key, Object value) =>
          allowList == null || allowList.contains(key),
    );
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
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<List<String>?> getStringList(String key) async {
    return values[key] as List<String>?;
  }

  @override
  Future<void> remove(String key) async {
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
    values[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    values[key] = List<String>.unmodifiable(value);
  }
}
