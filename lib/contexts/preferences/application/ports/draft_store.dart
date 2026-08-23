import '../../domain/rhythm_settings_draft.dart';

abstract interface class DraftStore {
  Future<RhythmSettingsDraft?> load();

  Future<void> save(RhythmSettingsDraft draft);

  Future<void> clear();
}
