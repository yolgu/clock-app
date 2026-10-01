import 'package:flutter/material.dart';

import '../../domain/theme_preference.dart';

final class ColorToken {
  const ColorToken(this.hex, this.color);

  final String hex;
  final Color color;
}

final class ThemeDefinition {
  const ThemeDefinition({
    required this.id,
    required this.displayName,
    required this.background,
    required this.surface,
    required this.text,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.danger,
  });

  final ThemePreference id;
  final String displayName;
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

abstract final class ThemeCatalog {
  static const List<ThemeDefinition> definitions = <ThemeDefinition>[
    ThemeDefinition(
      id: ThemePreference.current,
      displayName: 'Clock Rhythm',
      // Apple dark appearance: system grouped backgrounds, label white,
      // system blue (button tone), system green and system red.
      background: ColorToken('#000000', Color(0xFF000000)),
      surface: ColorToken('#1c1c1e', Color(0xFF1C1C1E)),
      text: ColorToken('#f5f5f7', Color(0xFFF5F5F7)),
      accentPrimary: ColorToken('#0071e3', Color(0xFF0071E3)),
      accentSecondary: ColorToken('#30d158', Color(0xFF30D158)),
      danger: ColorToken('#ff453a', Color(0xFFFF453A)),
    ),
    ThemeDefinition(
      id: ThemePreference.tokyoNight,
      displayName: 'Tokyo Night',
      background: ColorToken('#070b16', Color(0xFF070B16)),
      surface: ColorToken('#101322', Color(0xFF101322)),
      text: ColorToken('#c0caf5', Color(0xFFC0CAF5)),
      accentPrimary: ColorToken('#7dcfff', Color(0xFF7DCFFF)),
      accentSecondary: ColorToken('#bb9af7', Color(0xFFBB9AF7)),
      danger: ColorToken('#f7768e', Color(0xFFF7768E)),
    ),
    ThemeDefinition(
      id: ThemePreference.oneDarkPro,
      displayName: 'One Dark Pro',
      background: ColorToken('#171a21', Color(0xFF171A21)),
      surface: ColorToken('#1e222a', Color(0xFF1E222A)),
      text: ColorToken('#abb2bf', Color(0xFFABB2BF)),
      accentPrimary: ColorToken('#61afef', Color(0xFF61AFEF)),
      accentSecondary: ColorToken('#c678dd', Color(0xFFC678DD)),
      danger: ColorToken('#e06c75', Color(0xFFE06C75)),
    ),
    ThemeDefinition(
      id: ThemePreference.catppuccinMocha,
      displayName: 'Catppuccin Mocha',
      background: ColorToken('#11111b', Color(0xFF11111B)),
      surface: ColorToken('#1e1e2e', Color(0xFF1E1E2E)),
      text: ColorToken('#cdd6f4', Color(0xFFCDD6F4)),
      accentPrimary: ColorToken('#89dceb', Color(0xFF89DCEB)),
      accentSecondary: ColorToken('#cba6f7', Color(0xFFCBA6F7)),
      danger: ColorToken('#f38ba8', Color(0xFFF38BA8)),
    ),
    ThemeDefinition(
      id: ThemePreference.nord,
      displayName: 'Nord',
      background: ColorToken('#242933', Color(0xFF242933)),
      surface: ColorToken('#2e3440', Color(0xFF2E3440)),
      text: ColorToken('#eceff4', Color(0xFFECEFF4)),
      accentPrimary: ColorToken('#88c0d0', Color(0xFF88C0D0)),
      accentSecondary: ColorToken('#81a1c1', Color(0xFF81A1C1)),
      danger: ColorToken('#bf616a', Color(0xFFBF616A)),
    ),
    ThemeDefinition(
      id: ThemePreference.draculaOfficial,
      displayName: 'Dracula',
      background: ColorToken('#191a23', Color(0xFF191A23)),
      surface: ColorToken('#282a36', Color(0xFF282A36)),
      text: ColorToken('#f8f8f2', Color(0xFFF8F8F2)),
      accentPrimary: ColorToken('#8be9fd', Color(0xFF8BE9FD)),
      accentSecondary: ColorToken('#bd93f9', Color(0xFFBD93F9)),
      danger: ColorToken('#ff79c6', Color(0xFFFF79C6)),
    ),
    ThemeDefinition(
      id: ThemePreference.gruvbox,
      displayName: 'Gruvbox',
      background: ColorToken('#1d2021', Color(0xFF1D2021)),
      surface: ColorToken('#282828', Color(0xFF282828)),
      text: ColorToken('#ebdbb2', Color(0xFFEBDBB2)),
      accentPrimary: ColorToken('#fabd2f', Color(0xFFFABD2F)),
      accentSecondary: ColorToken('#fe8019', Color(0xFFFE8019)),
      danger: ColorToken('#fb4934', Color(0xFFFB4934)),
    ),
    ThemeDefinition(
      id: ThemePreference.monokaiPro,
      displayName: 'Neon Dusk',
      background: ColorToken('#11131f', Color(0xFF11131F)),
      surface: ColorToken('#1b1d2b', Color(0xFF1B1D2B)),
      text: ColorToken('#f2f4ff', Color(0xFFF2F4FF)),
      accentPrimary: ColorToken('#4de8c2', Color(0xFF4DE8C2)),
      accentSecondary: ColorToken('#b39dff', Color(0xFFB39DFF)),
      danger: ColorToken('#ff6b8a', Color(0xFFFF6B8A)),
    ),
    ThemeDefinition(
      id: ThemePreference.nightOwl,
      displayName: 'Night Owl',
      background: ColorToken('#01111f', Color(0xFF01111F)),
      surface: ColorToken('#011627', Color(0xFF011627)),
      text: ColorToken('#d6deeb', Color(0xFFD6DEEB)),
      accentPrimary: ColorToken('#82aaff', Color(0xFF82AAFF)),
      accentSecondary: ColorToken('#c792ea', Color(0xFFC792EA)),
      danger: ColorToken('#ef5350', Color(0xFFEF5350)),
    ),
    ThemeDefinition(
      id: ThemePreference.synthwave84,
      displayName: "SynthWave '84",
      background: ColorToken('#100719', Color(0xFF100719)),
      surface: ColorToken('#241b2f', Color(0xFF241B2F)),
      text: ColorToken('#fede5d', Color(0xFFFEDE5D)),
      accentPrimary: ColorToken('#36f9f6', Color(0xFF36F9F6)),
      accentSecondary: ColorToken('#ff7edb', Color(0xFFFF7EDB)),
      danger: ColorToken('#fe4450', Color(0xFFFE4450)),
    ),
    ThemeDefinition(
      id: ThemePreference.ayuMirageDark,
      displayName: 'Ayu Mirage Dark',
      background: ColorToken('#171b24', Color(0xFF171B24)),
      surface: ColorToken('#1f2430', Color(0xFF1F2430)),
      text: ColorToken('#cbccc6', Color(0xFFCBCCC6)),
      accentPrimary: ColorToken('#73d0ff', Color(0xFF73D0FF)),
      accentSecondary: ColorToken('#dfbfff', Color(0xFFDFBFFF)),
      danger: ColorToken('#f28779', Color(0xFFF28779)),
    ),
  ];

  static ThemeDefinition resolve(ThemePreference preference) {
    return definitions[preference.index];
  }
}
