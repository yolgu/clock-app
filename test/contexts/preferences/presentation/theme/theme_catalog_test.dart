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
