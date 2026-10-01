import 'dart:io';

import 'package:clock_rhythm/contexts/preferences/domain/theme_preference.dart';
import 'package:clock_rhythm/contexts/preferences/presentation/theme/theme_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves every stable backup theme identifier in order', () {
    expect(
      ThemeCatalog.definitions.map((ThemeDefinition theme) => theme.id.id),
      ThemePreference.values.map((ThemePreference theme) => theme.id),
    );
    for (final ThemePreference preference in ThemePreference.values) {
      expect(ThemeCatalog.resolve(preference).id, preference);
    }
  });

  test('maps the proprietary compatibility ID to Neon Dusk', () {
    final ThemeDefinition theme = ThemeCatalog.resolve(
      ThemePreference.monokaiPro,
    );

    expect(theme.displayName, 'Neon Dusk');
    expect(
      theme.sourceSwatches.map((ColorToken token) => token.hex),
      isNot(containsAll(<String>['#78dce8', '#ab9df2', '#ff6188'])),
    );
  });

  test('uses the Apple-inspired dark default palette', () {
    final ThemeDefinition theme = ThemeCatalog.resolve(ThemePreference.current);

    expect(theme.background.hex, '#000000');
    expect(theme.surface.hex, '#1c1c1e');
    expect(theme.text.hex, '#f5f5f7');
    expect(theme.accentPrimary.hex, '#0071e3');
    expect(theme.accentSecondary.hex, '#30d158');
    expect(theme.danger.hex, '#ff453a');
  });

  test('preserves every non-default compatibility palette', () {
    final Map<String, List<String>> expected = <String, List<String>>{
      'tokyo-night': <String>[
        '#7dcfff',
        '#bb9af7',
        '#c0caf5',
        '#101322',
        '#f7768e',
      ],
      'one-dark-pro': <String>[
        '#61afef',
        '#c678dd',
        '#abb2bf',
        '#1e222a',
        '#e06c75',
      ],
      'catppuccin-mocha': <String>[
        '#89dceb',
        '#cba6f7',
        '#cdd6f4',
        '#1e1e2e',
        '#f38ba8',
      ],
      'nord': <String>['#88c0d0', '#81a1c1', '#eceff4', '#2e3440', '#bf616a'],
      'dracula-official': <String>[
        '#8be9fd',
        '#bd93f9',
        '#f8f8f2',
        '#282a36',
        '#ff79c6',
      ],
      'gruvbox': <String>[
        '#fabd2f',
        '#fe8019',
        '#ebdbb2',
        '#282828',
        '#fb4934',
      ],
      'monokai-pro': <String>[
        '#4de8c2',
        '#b39dff',
        '#f2f4ff',
        '#1b1d2b',
        '#ff6b8a',
      ],
      'night-owl': <String>[
        '#82aaff',
        '#c792ea',
        '#d6deeb',
        '#011627',
        '#ef5350',
      ],
      'synthwave-84': <String>[
        '#36f9f6',
        '#ff7edb',
        '#fede5d',
        '#241b2f',
        '#fe4450',
      ],
      'ayu-mirage-dark': <String>[
        '#73d0ff',
        '#dfbfff',
        '#cbccc6',
        '#1f2430',
        '#f28779',
      ],
    };
    final Map<String, List<String>> actual = <String, List<String>>{
      for (final ThemeDefinition theme in ThemeCatalog.definitions.skip(1))
        theme.id.id: theme.sourceSwatches
            .map((ColorToken token) => token.hex)
            .toList(growable: false),
    };

    expect(actual, expected);
  });

  test('uses the redistributable Dracula display name', () {
    expect(
      ThemeCatalog.resolve(ThemePreference.draculaOfficial).displayName,
      'Dracula',
    );
  });

  test('asset notices record exact source hashes and provenance risk', () {
    final String assetNotice = File('ASSET_NOTICE.md').readAsStringSync();
    expect(
      assetNotice,
      contains(
        '7FD43B1FA0315FA3E68814DF757E06829BB7C39E0301049411A2D341471F3059',
      ),
    );
    expect(
      assetNotice,
      contains(
        '6387C3C02AF3C0C74ECEEE7847428072D270667DD6BFA723220C4394F5E137E3',
      ),
    );
    expect(assetNotice, contains('provenance/license'));
    expect(File('THIRD_PARTY_NOTICES.md').readAsStringSync(), contains('MIT'));
  });
}
