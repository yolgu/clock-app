import '../domain/user_preferences.dart';
import 'ports/settings_repository.dart';

final class GetPreferences {
  const GetPreferences(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  Future<UserPreferences> execute() {
    return _settingsRepository.load();
  }
}
