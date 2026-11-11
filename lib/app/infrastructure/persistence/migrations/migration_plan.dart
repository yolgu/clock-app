abstract final class DatabaseSchema {
  static const int initialVersion = 1;

  /// Adds the appearance mode beside the palette; existing rows open dark.
  static const int appearanceVersion = 2;
  static const int currentVersion = appearanceVersion;
}
