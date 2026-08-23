import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../contexts/preferences/public_model.dart';

final class DeviceSoundLocator {
  factory DeviceSoundLocator.restore({
    required String fileName,
    required String privateSource,
  }) {
    return DeviceSoundLocator._(
      fileName: NotificationSoundPreference.validateCustomFileName(fileName),
      privateSource: NotificationSoundPreference.validatePrivateSource(
        privateSource,
      ),
    );
  }

  const DeviceSoundLocator._({
    required this.fileName,
    required this.privateSource,
  });

  final String fileName;
  final String privateSource;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeviceSoundLocator &&
            fileName == other.fileName &&
            privateSource == other.privateSource;
  }

  @override
  int get hashCode => Object.hash(fileName, privateSource);
}

final class DeviceSoundLocatorState {
  const DeviceSoundLocatorState({
    required this.selectedCustom,
    required this.mutedFromCustom,
  });

  factory DeviceSoundLocatorState.fromPreferences(UserPreferences preferences) {
    final NotificationSoundSnapshot sound = preferences.notificationSound
        .snapshot();
    final AudibleNotificationSoundSelection? mutedFrom = sound.mutedFrom;
    return DeviceSoundLocatorState(
      selectedCustom: sound.mode == NotificationSoundMode.custom
          ? DeviceSoundLocator.restore(
              fileName: sound.customFileName!,
              privateSource: sound.privateSource!,
            )
          : null,
      mutedFromCustom: mutedFrom?.mode == NotificationSoundMode.custom
          ? DeviceSoundLocator.restore(
              fileName: mutedFrom!.customFileName!,
              privateSource: mutedFrom.privateSource!,
            )
          : null,
    );
  }

  static const DeviceSoundLocatorState empty = DeviceSoundLocatorState(
    selectedCustom: null,
    mutedFromCustom: null,
  );

  final DeviceSoundLocator? selectedCustom;
  final DeviceSoundLocator? mutedFromCustom;

  bool get isEmpty => selectedCustom == null && mutedFromCustom == null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeviceSoundLocatorState &&
            selectedCustom == other.selectedCustom &&
            mutedFromCustom == other.mutedFromCustom;
  }

  @override
  int get hashCode => Object.hash(selectedCustom, mutedFromCustom);
}

abstract interface class DeviceSoundLocatorStore {
  Future<DeviceSoundLocatorState> load();

  Future<void> save(DeviceSoundLocatorState state);
}

/// Stores device-only custom media locators outside the portable product DB.
///
/// Android backup rules must exclude SharedPreferences so this replaceable
/// locator document never crosses devices. The durable DB retains only the
/// user-facing file name and sound-mode meaning.
final class SharedPreferencesDeviceSoundLocatorStore
    implements DeviceSoundLocatorStore {
  const SharedPreferencesDeviceSoundLocatorStore([
    SharedPreferencesAsync? preferences,
  ]) : this._('clock_rhythm', preferences);

  const SharedPreferencesDeviceSoundLocatorStore.namespaced({
    required String storageNamespace,
    SharedPreferencesAsync? preferences,
  }) : this._(storageNamespace, preferences);

  const SharedPreferencesDeviceSoundLocatorStore._(
    this._storageNamespace,
    this._preferences,
  );

  static const int _schemaVersion = 1;
  static const String _documentKind = 'device-sound-locators';
  static const Set<String> _documentKeys = <String>{
    'schemaVersion',
    'kind',
    'selectedCustom',
    'mutedFromCustom',
  };
  static const Set<String> _locatorKeys = <String>{'fileName', 'privateSource'};

  final SharedPreferencesAsync? _preferences;
  final String _storageNamespace;

  String get _storageKey =>
      '$_storageNamespace.device_state.notification_sound_locators';

  @override
  Future<DeviceSoundLocatorState> load() async {
    final SharedPreferencesAsync preferences =
        _preferences ?? SharedPreferencesAsync();
    final String? document;
    try {
      document = await preferences.getString(_storageKey);
    } on TypeError {
      await _removeInvalidDocument(preferences);
      return DeviceSoundLocatorState.empty;
    }
    if (document == null) {
      return DeviceSoundLocatorState.empty;
    }

    try {
      return _decode(document);
    } on FormatException {
      await _removeInvalidDocument(preferences);
      return DeviceSoundLocatorState.empty;
    } on ArgumentError {
      await _removeInvalidDocument(preferences);
      return DeviceSoundLocatorState.empty;
    }
  }

  @override
  Future<void> save(DeviceSoundLocatorState state) async {
    final SharedPreferencesAsync preferences =
        _preferences ?? SharedPreferencesAsync();
    if (state.isEmpty) {
      await preferences.remove(_storageKey);
      return;
    }
    await preferences.setString(_storageKey, _encode(state));
  }

  String _encode(DeviceSoundLocatorState state) {
    return jsonEncode(<String, Object?>{
      'schemaVersion': _schemaVersion,
      'kind': _documentKind,
      'selectedCustom': _encodeLocator(state.selectedCustom),
      'mutedFromCustom': _encodeLocator(state.mutedFromCustom),
    });
  }

  DeviceSoundLocatorState _decode(String document) {
    final Object? decoded = jsonDecode(document);
    final Object? schemaVersion = decoded is Map<String, Object?>
        ? decoded['schemaVersion']
        : null;
    if (decoded is! Map<String, Object?> ||
        !_hasExactKeys(decoded, _documentKeys) ||
        schemaVersion is! int ||
        schemaVersion != _schemaVersion ||
        decoded['kind'] != _documentKind) {
      throw const FormatException('Invalid device sound locator document.');
    }
    return DeviceSoundLocatorState(
      selectedCustom: _decodeLocator(decoded['selectedCustom']),
      mutedFromCustom: _decodeLocator(decoded['mutedFromCustom']),
    );
  }

  Map<String, Object?>? _encodeLocator(DeviceSoundLocator? locator) {
    if (locator == null) {
      return null;
    }
    return <String, Object?>{
      'fileName': locator.fileName,
      'privateSource': locator.privateSource,
    };
  }

  DeviceSoundLocator? _decodeLocator(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! Map<String, Object?> || !_hasExactKeys(value, _locatorKeys)) {
      throw const FormatException('Invalid device sound locator.');
    }
    final Object? fileName = value['fileName'];
    final Object? privateSource = value['privateSource'];
    if (fileName is! String || privateSource is! String) {
      throw const FormatException('Invalid device sound locator field type.');
    }
    return DeviceSoundLocator.restore(
      fileName: fileName,
      privateSource: privateSource,
    );
  }

  bool _hasExactKeys(Map<String, Object?> value, Set<String> expected) {
    return value.length == expected.length &&
        value.keys.every(expected.contains);
  }

  Future<void> _removeInvalidDocument(
    SharedPreferencesAsync preferences,
  ) async {
    try {
      await preferences.remove(_storageKey);
    } on Object {
      // Invalid device state is replaceable; durable sound meaning remains.
    }
  }
}
