import 'package:flutter/material.dart';

import '../../domain/theme_preference.dart';

final class ColorToken {
  const ColorToken(this.hex, this.color);

  final String hex;
  final Color color;
}

/// The six source colors a palette is painted from in one appearance mode;
/// every other role is mixed from them by that mode's recipe.
final class ThemeSeeds {
  const ThemeSeeds({
    required this.background,
    required this.surface,
    required this.text,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.danger,
  });

  final ColorToken background;
  final ColorToken surface;
  final ColorToken text;
  final ColorToken accentPrimary;
  final ColorToken accentSecondary;
  final ColorToken danger;

  List<ColorToken> get sourceSwatches => <ColorToken>[
    accentPrimary,
    accentSecondary,
    text,
    surface,
    danger,
  ];
}

/// A palette with its seeds for each appearance mode. Both modes keep the
/// palette's hues and differ only in their lightness ladder.
final class ThemeDefinition {
  const ThemeDefinition({
    required this.id,
    required this.displayName,
    required this.dark,
    required this.light,
  });

  final ThemePreference id;
  final String displayName;
  final ThemeSeeds dark;
  final ThemeSeeds light;

  ThemeSeeds seedsFor(Brightness brightness) {
    return switch (brightness) {
      Brightness.dark => dark,
      Brightness.light => light,
    };
  }
}

/// Original Clock Rhythm palettes, as the Clock Rhythm design system defines
/// them. Every palette shares one OKLCH lightness ladder per mode and
/// differs only in hue and chroma, so the family reads as one system and
/// contrast holds in every palette and mode. Stored IDs stay the
/// schema-version-1 backup values; only names and colors changed.
abstract final class ThemeCatalog {
  static const List<ThemeDefinition> definitions = <ThemeDefinition>[
    ThemeDefinition(
      id: ThemePreference.current,
      displayName: 'Graphite',
      dark: ThemeSeeds(
        background: ColorToken('#0a0b0e', Color(0xFF0A0B0E)),
        surface: ColorToken('#141518', Color(0xFF141518)),
        text: ColorToken('#e9e9ec', Color(0xFFE9E9EC)),
        accentPrimary: ColorToken('#999ffc', Color(0xFF999FFC)),
        accentSecondary: ColorToken('#79d6aa', Color(0xFF79D6AA)),
        danger: ColorToken('#f86e6f', Color(0xFFF86E6F)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#f1f2f7', Color(0xFFF1F2F7)),
        surface: ColorToken('#fdfdff', Color(0xFFFDFDFF)),
        text: ColorToken('#1e1e20', Color(0xFF1E1E20)),
        accentPrimary: ColorToken('#4e4da7', Color(0xFF4E4DA7)),
        accentSecondary: ColorToken('#10845b', Color(0xFF10845B)),
        danger: ColorToken('#bc363e', Color(0xFFBC363E)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.tokyoNight,
      displayName: 'Midnight',
      dark: ThemeSeeds(
        background: ColorToken('#050a19', Color(0xFF050A19)),
        surface: ColorToken('#0c1426', Color(0xFF0C1426)),
        text: ColorToken('#e3eaf8', Color(0xFFE3EAF8)),
        accentPrimary: ColorToken('#58b4e8', Color(0xFF58B4E8)),
        accentSecondary: ColorToken('#c9b1f7', Color(0xFFC9B1F7)),
        danger: ColorToken('#f86e6f', Color(0xFFF86E6F)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#eff2fb', Color(0xFFEFF2FB)),
        surface: ColorToken('#fdfdff', Color(0xFFFDFDFF)),
        text: ColorToken('#191e28', Color(0xFF191E28)),
        accentPrimary: ColorToken('#01628b', Color(0xFF01628B)),
        accentSecondary: ColorToken('#7a61a4', Color(0xFF7A61A4)),
        danger: ColorToken('#bc363e', Color(0xFFBC363E)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.oneDarkPro,
      displayName: 'Slate',
      dark: ThemeSeeds(
        background: ColorToken('#070c12', Color(0xFF070C12)),
        surface: ColorToken('#0f161d', Color(0xFF0F161D)),
        text: ColorToken('#e5eaf0', Color(0xFFE5EAF0)),
        accentPrimary: ColorToken('#7daceb', Color(0xFF7DACEB)),
        accentSecondary: ColorToken('#e3b868', Color(0xFFE3B868)),
        danger: ColorToken('#f86e6f', Color(0xFFF86E6F)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#edf3fb', Color(0xFFEDF3FB)),
        surface: ColorToken('#fcfeff', Color(0xFFFCFEFF)),
        text: ColorToken('#1b1e23', Color(0xFF1B1E23)),
        accentPrimary: ColorToken('#2d5b97', Color(0xFF2D5B97)),
        accentSecondary: ColorToken('#916800', Color(0xFF916800)),
        danger: ColorToken('#bc363e', Color(0xFFBC363E)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.catppuccinMocha,
      displayName: 'Dusk',
      dark: ThemeSeeds(
        background: ColorToken('#0c0817', Color(0xFF0C0817)),
        surface: ColorToken('#151224', Color(0xFF151224)),
        text: ColorToken('#e9e7f6', Color(0xFFE9E7F6)),
        accentPrimary: ColorToken('#b599e1', Color(0xFFB599E1)),
        accentSecondary: ColorToken('#efa7c2', Color(0xFFEFA7C2)),
        danger: ColorToken('#f86e6f', Color(0xFFF86E6F)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#f3f1fa', Color(0xFFF3F1FA)),
        surface: ColorToken('#fdfdff', Color(0xFFFDFDFF)),
        text: ColorToken('#1e1c27', Color(0xFF1E1C27)),
        accentPrimary: ColorToken('#674a8e', Color(0xFF674A8E)),
        accentSecondary: ColorToken('#9b5773', Color(0xFF9B5773)),
        danger: ColorToken('#bc363e', Color(0xFFBC363E)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.nord,
      displayName: 'Glacier',
      dark: ThemeSeeds(
        background: ColorToken('#08141c', Color(0xFF08141C)),
        surface: ColorToken('#101f28', Color(0xFF101F28)),
        text: ColorToken('#e1ebf2', Color(0xFFE1EBF2)),
        accentPrimary: ColorToken('#62b9c4', Color(0xFF62B9C4)),
        accentSecondary: ColorToken('#a3c3e5', Color(0xFFA3C3E5)),
        danger: ColorToken('#f86e6f', Color(0xFFF86E6F)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#ebf4fa', Color(0xFFEBF4FA)),
        surface: ColorToken('#fcfeff', Color(0xFFFCFEFF)),
        text: ColorToken('#181f24', Color(0xFF181F24)),
        accentPrimary: ColorToken('#056771', Color(0xFF056771)),
        accentSecondary: ColorToken('#547394', Color(0xFF547394)),
        danger: ColorToken('#bc363e', Color(0xFFBC363E)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.draculaOfficial,
      displayName: 'Orchid',
      dark: ThemeSeeds(
        background: ColorToken('#110616', Color(0xFF110616)),
        surface: ColorToken('#1c0e22', Color(0xFF1C0E22)),
        text: ColorToken('#efe5f4', Color(0xFFEFE5F4)),
        accentPrimary: ColorToken('#dd89c2', Color(0xFFDD89C2)),
        accentSecondary: ColorToken('#c0b3fe', Color(0xFFC0B3FE)),
        danger: ColorToken('#f86e6f', Color(0xFFF86E6F)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#f6f0f8', Color(0xFFF6F0F8)),
        surface: ColorToken('#fefdff', Color(0xFFFEFDFF)),
        text: ColorToken('#221b26', Color(0xFF221B26)),
        accentPrimary: ColorToken('#883872', Color(0xFF883872)),
        accentSecondary: ColorToken('#7263ab', Color(0xFF7263AB)),
        danger: ColorToken('#bc363e', Color(0xFFBC363E)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.gruvbox,
      displayName: 'Ember',
      dark: ThemeSeeds(
        background: ColorToken('#0f0a06', Color(0xFF0F0A06)),
        surface: ColorToken('#1a130d', Color(0xFF1A130D)),
        text: ColorToken('#eee8e4', Color(0xFFEEE8E4)),
        accentPrimary: ColorToken('#db9b40', Color(0xFFDB9B40)),
        accentSecondary: ColorToken('#adcc86', Color(0xFFADCC86)),
        danger: ColorToken('#f86f62', Color(0xFFF86F62)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#f8f1ea', Color(0xFFF8F1EA)),
        surface: ColorToken('#fffdfb', Color(0xFFFFFDFB)),
        text: ColorToken('#211d1a', Color(0xFF211D1A)),
        accentPrimary: ColorToken('#7c5007', Color(0xFF7C5007)),
        accentSecondary: ColorToken('#5e7b34', Color(0xFF5E7B34)),
        danger: ColorToken('#bc3730', Color(0xFFBC3730)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.monokaiPro,
      displayName: 'Aurora',
      dark: ThemeSeeds(
        background: ColorToken('#010e0e', Color(0xFF010E0E)),
        surface: ColorToken('#061818', Color(0xFF061818)),
        text: ColorToken('#e0ecec', Color(0xFFE0ECEC)),
        accentPrimary: ColorToken('#4dc19b', Color(0xFF4DC19B)),
        accentSecondary: ColorToken('#c0b4fb', Color(0xFFC0B4FB)),
        danger: ColorToken('#f86e6f', Color(0xFFF86E6F)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#eaf5f5', Color(0xFFEAF5F5)),
        surface: ColorToken('#fbfefe', Color(0xFFFBFEFE)),
        text: ColorToken('#172020', Color(0xFF172020)),
        accentPrimary: ColorToken('#096b51', Color(0xFF096B51)),
        accentSecondary: ColorToken('#7164a8', Color(0xFF7164A8)),
        danger: ColorToken('#bc363e', Color(0xFFBC363E)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.nightOwl,
      displayName: 'Moss',
      dark: ThemeSeeds(
        background: ColorToken('#060d08', Color(0xFF060D08)),
        surface: ColorToken('#0f1711', Color(0xFF0F1711)),
        text: ColorToken('#e5ebe6', Color(0xFFE5EBE6)),
        accentPrimary: ColorToken('#8fb86e', Color(0xFF8FB86E)),
        accentSecondary: ColorToken('#d8bc7b', Color(0xFFD8BC7B)),
        danger: ColorToken('#f86e6f', Color(0xFFF86E6F)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#edf5ef', Color(0xFFEDF5EF)),
        surface: ColorToken('#fbfefc', Color(0xFFFBFEFC)),
        text: ColorToken('#1b1f1c', Color(0xFF1B1F1C)),
        accentPrimary: ColorToken('#416818', Color(0xFF416818)),
        accentSecondary: ColorToken('#886c26', Color(0xFF886C26)),
        danger: ColorToken('#bc363e', Color(0xFFBC363E)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.synthwave84,
      displayName: 'Sunset',
      dark: ThemeSeeds(
        background: ColorToken('#140513', Color(0xFF140513)),
        surface: ColorToken('#200c1f', Color(0xFF200C1F)),
        text: ColorToken('#f2e5f1', Color(0xFFF2E5F1)),
        accentPrimary: ColorToken('#e5935f', Color(0xFFE5935F)),
        accentSecondary: ColorToken('#f2a2d0', Color(0xFFF2A2D0)),
        danger: ColorToken('#f76d77', Color(0xFFF76D77)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#f7f0f6', Color(0xFFF7F0F6)),
        surface: ColorToken('#fffcff', Color(0xFFFFFCFF)),
        text: ColorToken('#241b23', Color(0xFF241B23)),
        accentPrimary: ColorToken('#8d4303', Color(0xFF8D4303)),
        accentSecondary: ColorToken('#9e5280', Color(0xFF9E5280)),
        danger: ColorToken('#bb3546', Color(0xFFBB3546)),
      ),
    ),
    ThemeDefinition(
      id: ThemePreference.ayuMirageDark,
      displayName: 'Mono',
      dark: ThemeSeeds(
        background: ColorToken('#0b0b0b', Color(0xFF0B0B0B)),
        surface: ColorToken('#151515', Color(0xFF151515)),
        text: ColorToken('#e9e9e9', Color(0xFFE9E9E9)),
        accentPrimary: ColorToken('#dedede', Color(0xFFDEDEDE)),
        accentSecondary: ColorToken('#9e9e9e', Color(0xFF9E9E9E)),
        danger: ColorToken('#f86e6f', Color(0xFFF86E6F)),
      ),
      light: ThemeSeeds(
        background: ColorToken('#f2f2f2', Color(0xFFF2F2F2)),
        surface: ColorToken('#fdfdfd', Color(0xFFFDFDFD)),
        text: ColorToken('#1e1e1e', Color(0xFF1E1E1E)),
        accentPrimary: ColorToken('#5b5b5b', Color(0xFF5B5B5B)),
        accentSecondary: ColorToken('#707070', Color(0xFF707070)),
        danger: ColorToken('#bc363e', Color(0xFFBC363E)),
      ),
    ),
  ];

  static ThemeDefinition resolve(ThemePreference preference) {
    return definitions[preference.index];
  }
}
