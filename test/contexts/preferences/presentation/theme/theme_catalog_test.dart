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

  test('displays the original Clock Rhythm theme names in stored-ID order', () {
    expect(
      ThemeCatalog.definitions.map(
        (ThemeDefinition theme) => theme.displayName,
      ),
      <String>[
        'Graphite',
        'Midnight',
        'Slate',
        'Dusk',
        'Glacier',
        'Orchid',
        'Ember',
        'Aurora',
        'Moss',
        'Sunset',
        'Mono',
      ],
    );
  });

  test('defines every palette from the original Clock Rhythm swatches', () {
    final Map<String, List<String>> expected = <String, List<String>>{
      'current': <String>[
        '#999ffc',
        '#79d6aa',
        '#e9e9ec',
        '#141518',
        '#f86e6f',
      ],
      'tokyo-night': <String>[
        '#58b4e8',
        '#c9b1f7',
        '#e3eaf8',
        '#0c1426',
        '#f86e6f',
      ],
      'one-dark-pro': <String>[
        '#7daceb',
        '#e3b868',
        '#e5eaf0',
        '#0f161d',
        '#f86e6f',
      ],
      'catppuccin-mocha': <String>[
        '#b599e1',
        '#efa7c2',
        '#e9e7f6',
        '#151224',
        '#f86e6f',
      ],
      'nord': <String>['#62b9c4', '#a3c3e5', '#e1ebf2', '#101f28', '#f86e6f'],
      'dracula-official': <String>[
        '#dd89c2',
        '#c0b3fe',
        '#efe5f4',
        '#1c0e22',
        '#f86e6f',
      ],
      'gruvbox': <String>[
        '#db9b40',
        '#adcc86',
        '#eee8e4',
        '#1a130d',
        '#f86f62',
      ],
      'monokai-pro': <String>[
        '#4dc19b',
        '#c0b4fb',
        '#e0ecec',
        '#061818',
        '#f86e6f',
      ],
      'night-owl': <String>[
        '#8fb86e',
        '#d8bc7b',
        '#e5ebe6',
        '#0f1711',
        '#f86e6f',
      ],
      'synthwave-84': <String>[
        '#e5935f',
        '#f2a2d0',
        '#f2e5f1',
        '#200c1f',
        '#f76d77',
      ],
      'ayu-mirage-dark': <String>[
        '#dedede',
        '#9e9e9e',
        '#e9e9e9',
        '#151515',
        '#f86e6f',
      ],
    };
    final Map<String, List<String>> actual = <String, List<String>>{
      for (final ThemeDefinition theme in ThemeCatalog.definitions)
        theme.id.id: theme.dark.sourceSwatches
            .map((ColorToken token) => token.hex)
            .toList(growable: false),
    };

    expect(actual, expected);
  });

  test('transcribes the light seeds of the Clock Rhythm design system', () {
    const Map<String, List<String>> expected = <String, List<String>>{
      'current': <String>[
        '#f1f2f7',
        '#fdfdff',
        '#1e1e20',
        '#4e4da7',
        '#10845b',
        '#bc363e',
      ],
      'tokyo-night': <String>[
        '#eff2fb',
        '#fdfdff',
        '#191e28',
        '#01628b',
        '#7a61a4',
        '#bc363e',
      ],
      'one-dark-pro': <String>[
        '#edf3fb',
        '#fcfeff',
        '#1b1e23',
        '#2d5b97',
        '#916800',
        '#bc363e',
      ],
      'catppuccin-mocha': <String>[
        '#f3f1fa',
        '#fdfdff',
        '#1e1c27',
        '#674a8e',
        '#9b5773',
        '#bc363e',
      ],
      'nord': <String>[
        '#ebf4fa',
        '#fcfeff',
        '#181f24',
        '#056771',
        '#547394',
        '#bc363e',
      ],
      'dracula-official': <String>[
        '#f6f0f8',
        '#fefdff',
        '#221b26',
        '#883872',
        '#7263ab',
        '#bc363e',
      ],
      'gruvbox': <String>[
        '#f8f1ea',
        '#fffdfb',
        '#211d1a',
        '#7c5007',
        '#5e7b34',
        '#bc3730',
      ],
      'monokai-pro': <String>[
        '#eaf5f5',
        '#fbfefe',
        '#172020',
        '#096b51',
        '#7164a8',
        '#bc363e',
      ],
      'night-owl': <String>[
        '#edf5ef',
        '#fbfefc',
        '#1b1f1c',
        '#416818',
        '#886c26',
        '#bc363e',
      ],
      'synthwave-84': <String>[
        '#f7f0f6',
        '#fffcff',
        '#241b23',
        '#8d4303',
        '#9e5280',
        '#bb3546',
      ],
      'ayu-mirage-dark': <String>[
        '#f2f2f2',
        '#fdfdfd',
        '#1e1e1e',
        '#5b5b5b',
        '#707070',
        '#bc363e',
      ],
    };
    final Map<String, List<String>> actual = <String, List<String>>{
      for (final ThemeDefinition theme in ThemeCatalog.definitions)
        theme.id.id: <ColorToken>[
          theme.light.background,
          theme.light.surface,
          theme.light.text,
          theme.light.accentPrimary,
          theme.light.accentSecondary,
          theme.light.danger,
        ].map((ColorToken token) => token.hex).toList(growable: false),
    };

    expect(actual, expected);
  });

  test('keeps the hex and color of every token in agreement', () {
    for (final ThemeDefinition theme in ThemeCatalog.definitions) {
      for (final ThemeSeeds seeds in <ThemeSeeds>[theme.dark, theme.light]) {
        for (final ColorToken token in <ColorToken>[
          seeds.background,
          ...seeds.sourceSwatches,
        ]) {
          final String argb = token.color.toARGB32().toRadixString(16);
          expect('#${argb.substring(2)}', token.hex, reason: theme.displayName);
        }
      }
    }
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
    expect(
      File('THIRD_PARTY_NOTICES.md').readAsStringSync(),
      contains('redistributes no third-party theme names or palette swatches'),
    );
  });
}
