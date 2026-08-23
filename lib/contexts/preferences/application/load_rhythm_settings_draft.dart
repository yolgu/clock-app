import '../domain/rhythm_settings_draft.dart';
import '../domain/user_preferences.dart';
import 'ports/draft_store.dart';
import 'ports/settings_repository.dart';

final class LoadRhythmSettingsDraft {
  const LoadRhythmSettingsDraft({
    required this._settingsRepository,
    required this._draftStore,
  });

  final SettingsRepository _settingsRepository;
  final DraftStore _draftStore;

  Future<RhythmSettingsDraft> execute() async {
    final RhythmSettingsDraft? stored = await _draftStore.load();
    if (stored != null) {
      return stored;
    }
    final UserPreferences durable = await _settingsRepository.load();
    return RhythmSettingsDraft.fromPreferences(durable);
  }
}
