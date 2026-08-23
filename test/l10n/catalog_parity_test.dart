import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef ArbCatalog = Map<String, Object?>;

void main() {
  late ArbCatalog englishCatalog;
  late ArbCatalog koreanCatalog;

  setUpAll(() {
    englishCatalog = _readCatalog('lib/l10n/app_en.arb');
    koreanCatalog = _readCatalog('lib/l10n/app_ko.arb');
  });

  test('keeps Korean and English message keys aligned', () {
    expect(_messageKeys(koreanCatalog), _messageKeys(englishCatalog));
  });

  test('keeps placeholder and plural-selector contracts aligned', () {
    for (final String key in _messageKeys(englishCatalog)) {
      final String englishMessage = englishCatalog[key]! as String;
      final String koreanMessage = koreanCatalog[key]! as String;

      expect(
        _placeholderNames(koreanMessage),
        _placeholderNames(englishMessage),
        reason: '$key must use the same placeholders in both locales',
      );
      expect(
        _pluralSelectors(koreanMessage),
        _pluralSelectors(englishMessage),
        reason: '$key must use the same plural selectors in both locales',
      );
    }
  });

  test('declares every template placeholder in ARB metadata', () {
    for (final String key in _messageKeys(englishCatalog)) {
      final String message = englishCatalog[key]! as String;
      final Set<String> placeholders = _placeholderNames(message);
      if (placeholders.isEmpty) {
        continue;
      }

      expect(
        _metadataPlaceholderNames(englishCatalog, key),
        placeholders,
        reason: '$key metadata must describe its complete placeholder contract',
      );
    }
  });

  test('contains the stable failure, event, and payload message contracts', () {
    expect(
      _messageKeys(englishCatalog),
      containsAll(<String>{
        'failureBackupFileTooLarge',
        'failureBackupTodoIdInvalid',
        'failureDatabaseMigration',
        'failureNotificationPermissionRequired',
        'trayOpen',
        'trayPause',
        'trayResume',
        'trayStopForToday',
        'trayQuit',
        'announcementRhythmRunning',
        'announcementBackupImported',
        'notificationFocusEndedTitle',
        'notificationFocusEndedBody',
        'notificationRestEndedTitle',
        'notificationRestEndedBody',
      }),
    );
  });

  test('uses the accepted compatibility theme display names', () {
    for (final ArbCatalog catalog in <ArbCatalog>[
      englishCatalog,
      koreanCatalog,
    ]) {
      expect(catalog['themeDraculaName'], 'Dracula');
      expect(catalog['themeNeonDuskName'], 'Neon Dusk');
      expect(
        catalog.values.whereType<String>(),
        isNot(contains('Dracula Official')),
      );
      expect(
        catalog.values.whereType<String>(),
        isNot(contains('Monokai Pro')),
      );
    }
  });

  test('preserves focus-window wording in migrated Rhythm copy', () {
    const Set<String> migratedRhythmKeys = <String>{
      'rhythmSettingsTitle',
      'rhythmSettingsDisclosureTitle',
      'rhythmSettingsDailyStart',
      'rhythmSettingsDailyEnd',
      'rhythmSettingsOutsideDailyRhythm',
      'rhythmSettingsSummaryOutsideDailyRhythm',
      'messageRhythmRunning',
      'messageRhythmPaused',
      'messageRhythmResumed',
      'messageRhythmStoppedForToday',
    };

    for (final String key in migratedRhythmKeys) {
      final String englishMessage = englishCatalog[key]! as String;
      final String koreanMessage = koreanCatalog[key]! as String;

      expect(englishMessage.toLowerCase(), isNot(contains('rhythm')));
      expect(koreanMessage, isNot(contains('리듬')));
    }
    expect(englishCatalog['rhythmSettingsDailyStart'], 'Focus window start');
    expect(koreanCatalog['rhythmSettingsDailyStart'], '집중 시간대 시작');
  });
}

ArbCatalog _readCatalog(String path) {
  final Object? decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    throw FormatException('$path must contain a JSON object');
  }
  return decoded;
}

Set<String> _messageKeys(ArbCatalog catalog) {
  return catalog.keys.where((String key) => !key.startsWith('@')).toSet();
}

Set<String> _placeholderNames(String message) {
  return RegExp(
    r'\{([A-Za-z][A-Za-z0-9_]*)(?:\s*,|\})',
  ).allMatches(message).map((RegExpMatch match) => match.group(1)!).toSet();
}

Set<String> _pluralSelectors(String message) {
  if (!RegExp(r'\{[A-Za-z][A-Za-z0-9_]*\s*,\s*plural\s*,').hasMatch(message)) {
    return <String>{};
  }
  return RegExp(
    r'(=\d+|zero|one|two|few|many|other)\s*\{',
  ).allMatches(message).map((RegExpMatch match) => match.group(1)!).toSet();
}

Set<String> _metadataPlaceholderNames(ArbCatalog catalog, String key) {
  final Object? metadataValue = catalog['@$key'];
  if (metadataValue is! Map<String, Object?>) {
    return <String>{};
  }
  final Object? placeholdersValue = metadataValue['placeholders'];
  if (placeholdersValue is! Map<String, Object?>) {
    return <String>{};
  }
  return placeholdersValue.keys.toSet();
}
