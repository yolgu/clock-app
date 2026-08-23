import 'package:drift/drift.dart';

import '../../../../contexts/preferences/public_model.dart';
import '../../device_state/device_sound_locator_store.dart';
import '../clock_rhythm_database.dart';

abstract final class PreferenceRecordMapper {
  static UserPreferences restore(
    PreferenceRecord record, {
    required DeviceSoundLocatorState deviceSoundLocators,
  }) {
    if (record.singletonId != 1) {
      throw const FormatException(
        'Preferences singleton identifier is invalid.',
      );
    }
    final NotificationSoundMode mode = NotificationSoundMode.parse(
      record.soundMode,
    );
    _validateSoundColumns(record, mode);
    final NotificationSoundSnapshot sound = _restoreSound(
      record,
      mode,
      deviceSoundLocators,
    );
    return UserPreferences.restore(
      UserPreferencesSnapshot(
        focusMinutes: record.focusMinutes,
        restMinutes: record.restMinutes,
        dailyStart: record.dailyStart,
        dailyEnd: record.dailyEnd,
        autoStartEnabled: record.autoStartEnabled,
        notificationSound: sound,
        language: LanguagePreference.parse(record.language),
        theme: ThemePreference.parse(record.theme),
        initialSetupCompleted: record.initialSetupCompleted,
      ),
    );
  }

  static PreferenceRecordsCompanion toCompanion(UserPreferences preferences) {
    final UserPreferencesSnapshot snapshot = preferences.snapshot();
    final NotificationSoundSnapshot sound = snapshot.notificationSound;
    return PreferenceRecordsCompanion.insert(
      singletonId: const Value<int>(1),
      focusMinutes: snapshot.focusMinutes,
      restMinutes: snapshot.restMinutes,
      dailyStart: snapshot.dailyStart,
      dailyEnd: snapshot.dailyEnd,
      autoStartEnabled: snapshot.autoStartEnabled,
      soundMode: sound.mode.id,
      customFileName: Value<String?>(sound.customFileName),
      soundVolume: sound.volume,
      mutedFromMode: Value<String?>(sound.mutedFrom?.mode.id),
      mutedFromFileName: Value<String?>(sound.mutedFrom?.customFileName),
      language: snapshot.language.id,
      theme: snapshot.theme.id,
      initialSetupCompleted: snapshot.initialSetupCompleted,
    );
  }

  static bool requiresDeviceSoundLocators(PreferenceRecord record) {
    return record.soundMode == NotificationSoundMode.custom.id ||
        record.mutedFromMode == NotificationSoundMode.custom.id;
  }

  static NotificationSoundSnapshot _restoreSound(
    PreferenceRecord record,
    NotificationSoundMode mode,
    DeviceSoundLocatorState deviceSoundLocators,
  ) {
    if (mode == NotificationSoundMode.custom) {
      final DeviceSoundLocator? selected = _matchingLocator(
        record.customFileName!,
        deviceSoundLocators.selectedCustom,
      );
      if (selected == null) {
        return NotificationSoundSnapshot(
          mode: NotificationSoundMode.bundledDefault,
          customFileName: null,
          privateSource: null,
          volume: record.soundVolume,
          mutedFrom: null,
        );
      }
      return NotificationSoundSnapshot(
        mode: mode,
        customFileName: selected.fileName,
        privateSource: selected.privateSource,
        volume: record.soundVolume,
        mutedFrom: null,
      );
    }
    return NotificationSoundSnapshot(
      mode: mode,
      customFileName: null,
      privateSource: null,
      volume: record.soundVolume,
      mutedFrom: mode == NotificationSoundMode.muted
          ? _restoreMutedFrom(record, deviceSoundLocators)
          : null,
    );
  }

  static AudibleNotificationSoundSelection? _restoreMutedFrom(
    PreferenceRecord record,
    DeviceSoundLocatorState deviceSoundLocators,
  ) {
    final String? modeId = record.mutedFromMode;
    if (modeId == null) {
      if (record.mutedFromFileName != null) {
        throw const FormatException(
          'Muted sound restore columns are incomplete.',
        );
      }
      return null;
    }
    final NotificationSoundMode mode = NotificationSoundMode.parse(modeId);
    return switch (mode) {
      NotificationSoundMode.bundledDefault =>
        AudibleNotificationSoundSelection.bundledDefault(),
      NotificationSoundMode.custom => _restoreMutedCustom(
        record,
        deviceSoundLocators,
      ),
      NotificationSoundMode.muted => throw const FormatException(
        'Muted sound cannot restore another muted sound.',
      ),
    };
  }

  static AudibleNotificationSoundSelection _restoreMutedCustom(
    PreferenceRecord record,
    DeviceSoundLocatorState deviceSoundLocators,
  ) {
    final DeviceSoundLocator? locator = _matchingLocator(
      record.mutedFromFileName!,
      deviceSoundLocators.mutedFromCustom,
    );
    if (locator == null) {
      return AudibleNotificationSoundSelection.bundledDefault();
    }
    return AudibleNotificationSoundSelection.custom(
      fileName: locator.fileName,
      privateSource: locator.privateSource,
    );
  }

  static DeviceSoundLocator? _matchingLocator(
    String fileName,
    DeviceSoundLocator? locator,
  ) {
    return locator?.fileName == fileName ? locator : null;
  }

  static void _validateSoundColumns(
    PreferenceRecord record,
    NotificationSoundMode mode,
  ) {
    final bool hasCustom = record.customFileName != null;
    final bool hasMuted =
        record.mutedFromMode != null || record.mutedFromFileName != null;
    switch (mode) {
      case NotificationSoundMode.bundledDefault:
        if (hasCustom || hasMuted) {
          throw const FormatException(
            'Default sound row has incompatible data.',
          );
        }
      case NotificationSoundMode.custom:
        if (record.customFileName == null || hasMuted) {
          throw const FormatException('Custom sound row is incomplete.');
        }
      case NotificationSoundMode.muted:
        if (hasCustom) {
          throw const FormatException(
            'Muted sound row has audible source data.',
          );
        }
        _validateMutedRestoreColumns(record);
    }
  }

  static void _validateMutedRestoreColumns(PreferenceRecord record) {
    final String? modeId = record.mutedFromMode;
    if (modeId == null) {
      if (record.mutedFromFileName != null) {
        throw const FormatException(
          'Muted sound restore columns are incomplete.',
        );
      }
      return;
    }
    final NotificationSoundMode mode = NotificationSoundMode.parse(modeId);
    switch (mode) {
      case NotificationSoundMode.bundledDefault:
        if (record.mutedFromFileName != null) {
          throw const FormatException(
            'Default muted restore has incompatible data.',
          );
        }
      case NotificationSoundMode.custom:
        if (record.mutedFromFileName == null) {
          throw const FormatException('Custom muted restore is incomplete.');
        }
      case NotificationSoundMode.muted:
        throw const FormatException(
          'Muted sound cannot restore another muted sound.',
        );
    }
  }
}
