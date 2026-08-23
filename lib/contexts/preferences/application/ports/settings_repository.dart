import '../../domain/user_preferences.dart';

abstract interface class SettingsRepository {
  Future<UserPreferences> load();

  Future<void> save(UserPreferences preferences);
}
