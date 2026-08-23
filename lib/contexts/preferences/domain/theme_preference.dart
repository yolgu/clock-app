enum ThemePreference {
  current('current'),
  tokyoNight('tokyo-night'),
  oneDarkPro('one-dark-pro'),
  catppuccinMocha('catppuccin-mocha'),
  nord('nord'),
  draculaOfficial('dracula-official'),
  gruvbox('gruvbox'),
  monokaiPro('monokai-pro'),
  nightOwl('night-owl'),
  synthwave84('synthwave-84'),
  ayuMirageDark('ayu-mirage-dark');

  const ThemePreference(this.id);

  final String id;

  static ThemePreference parse(String id) {
    for (final ThemePreference theme in values) {
      if (theme.id == id) {
        return theme;
      }
    }
    throw FormatException('Unsupported theme preference: $id');
  }
}
