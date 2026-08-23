import 'package:shared_preferences/shared_preferences.dart';

import '../../../contexts/rhythm/public.dart' show LegacyCoexistenceWarning;

final class SharedPreferencesLegacyCoexistenceWarning
    implements LegacyCoexistenceWarning {
  SharedPreferencesLegacyCoexistenceWarning({
    required String storageNamespace,
    SharedPreferencesAsync? preferences,
  }) : _storageKey =
           '$storageNamespace.migration.legacy_coexistence_acknowledged',
       _preferences = preferences ?? SharedPreferencesAsync();

  final String _storageKey;
  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> shouldWarnBeforeStart() async {
    try {
      return !(await _preferences.getBool(_storageKey) ?? false);
    } on Object {
      return true;
    }
  }

  @override
  Future<void> acknowledge() async {
    try {
      await _preferences.setBool(_storageKey, true);
    } on Object {
      // This device-only marker is best effort; a failed write repeats the warning.
    }
  }
}
