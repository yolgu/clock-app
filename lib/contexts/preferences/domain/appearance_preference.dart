/// Whether the app paints its palette in the dark or the light lightness
/// ladder, or follows the operating system. Stored apart from the palette
/// so a palette keeps its identity across modes; dark is the default.
enum AppearancePreference {
  system('system'),
  light('light'),
  dark('dark');

  const AppearancePreference(this.id);

  /// The mode installations and backups that predate the setting open in.
  static const AppearancePreference standard = AppearancePreference.dark;

  final String id;

  static AppearancePreference parse(String id) {
    for (final AppearancePreference appearance in values) {
      if (appearance.id == id) {
        return appearance;
      }
    }
    throw FormatException('Unsupported appearance preference: $id');
  }
}
