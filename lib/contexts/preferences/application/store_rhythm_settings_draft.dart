import '../domain/rhythm_settings_draft.dart';
import '../domain/user_preferences.dart';
import 'ports/draft_store.dart';
import 'ports/settings_repository.dart';

final class StoreRhythmSettingsDraft {
  const StoreRhythmSettingsDraft(this._draftStore);

  final DraftStore _draftStore;

  Future<void> execute(RhythmSettingsDraft draft) {
    return _draftStore.save(draft);
  }
}

final class DiscardRhythmSettingsDraft {
  const DiscardRhythmSettingsDraft({
    required this._settingsRepository,
    required this._draftStore,
  });

  final SettingsRepository _settingsRepository;
  final DraftStore _draftStore;

  Future<RhythmSettingsDraft> execute() async {
    final UserPreferences durable = await _settingsRepository.load();
    final RhythmSettingsDraft clean = RhythmSettingsDraft.fromPreferences(
      durable,
    );
    await _draftStore.save(clean);
    return clean;
  }
}
