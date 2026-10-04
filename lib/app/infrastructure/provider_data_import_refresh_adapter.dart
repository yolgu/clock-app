import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contexts/preferences/public.dart'
    show DraftStore, RhythmSettingsDraft, SettingsRepository, UserPreferences;
import '../../contexts/preferences/public_presentation.dart'
    show preferencesInitialDataProvider, soundPreviewControllerProvider;
import '../../contexts/rhythm/public_presentation.dart'
    show rhythmViewModelProvider;
import '../../contexts/todo/public_presentation.dart'
    show todoDataControllerProvider, calendarViewModelProvider;
import '../../features/data_transfer/public.dart' show DataImportRefreshPort;

typedef ProviderContainerResolver = ProviderContainer Function();
typedef ImportedPreferencesApply =
    Future<void> Function(UserPreferences preferences);

final class ProviderDataImportRefreshAdapter implements DataImportRefreshPort {
  const ProviderDataImportRefreshAdapter({
    required this._settingsRepository,
    required this._draftStore,
    required this._container,
    required this._applyImportedPreferences,
  });

  final SettingsRepository _settingsRepository;
  final DraftStore _draftStore;
  final ProviderContainerResolver _container;
  final ImportedPreferencesApply _applyImportedPreferences;

  @override
  Future<void> refreshAfterImport() async {
    final UserPreferences imported = await _settingsRepository.load();
    await _draftStore.save(RhythmSettingsDraft.fromPreferences(imported));
    await _applyImportedPreferences(imported);
    final ProviderContainer container = _container();
    container.invalidate(preferencesInitialDataProvider);
    container.invalidate(soundPreviewControllerProvider);
    container.invalidate(todoDataControllerProvider);
    container.invalidate(calendarViewModelProvider);
    container.invalidate(rhythmViewModelProvider);
  }
}
