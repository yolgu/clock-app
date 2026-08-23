import '../../../../contexts/preferences/public.dart'
    show SettingsRepository, UserPreferences;
import '../../device_state/device_sound_locator_mutation.dart';
import '../../device_state/device_sound_locator_store.dart';
import '../clock_rhythm_database.dart';
import '../mappers/preference_record_mapper.dart';

final class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(
    this._database, {
    required this.deviceSoundLocatorStore,
    DeviceSoundLocatorMutationCoordinator? deviceSoundLocatorMutation,
  }) : _deviceSoundLocatorMutation =
           deviceSoundLocatorMutation ??
           DeviceSoundLocatorMutationCoordinator(deviceSoundLocatorStore);

  final ClockRhythmDatabase _database;
  final DeviceSoundLocatorStore deviceSoundLocatorStore;
  final DeviceSoundLocatorMutationCoordinator _deviceSoundLocatorMutation;

  @override
  Future<UserPreferences> load() async {
    final List<PreferenceRecord> records = await _database
        .select(_database.preferenceRecords)
        .get();
    if (records.isEmpty) {
      return UserPreferences.defaults();
    }
    if (records.length != 1) {
      throw const FormatException(
        'Preferences must contain one singleton row.',
      );
    }
    final PreferenceRecord record = records.single;
    final DeviceSoundLocatorState deviceSoundLocators =
        PreferenceRecordMapper.requiresDeviceSoundLocators(record)
        ? await deviceSoundLocatorStore.load()
        : DeviceSoundLocatorState.empty;
    return PreferenceRecordMapper.restore(
      record,
      deviceSoundLocators: deviceSoundLocators,
    );
  }

  @override
  Future<void> save(UserPreferences preferences) {
    final DeviceSoundLocatorState deviceSoundLocators =
        DeviceSoundLocatorState.fromPreferences(preferences);
    return _deviceSoundLocatorMutation.run<void>(() {
      return _database.transaction(() async {
        await _database.delete(_database.preferenceRecords).go();
        await _database
            .into(_database.preferenceRecords)
            .insert(PreferenceRecordMapper.toCompanion(preferences));
        await deviceSoundLocatorStore.save(deviceSoundLocators);
      });
    });
  }
}
