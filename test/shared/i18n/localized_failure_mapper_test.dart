import 'dart:ui';

import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps every stable failure key unique and localized', () {
    final Set<String> stableKeys = LocalizedFailureKey.values
        .map((LocalizedFailureKey key) => key.stableKey)
        .toSet();
    final AppLocalizations english = lookupAppLocalizations(const Locale('en'));
    final AppLocalizations korean = lookupAppLocalizations(const Locale('ko'));
    final LocalizedFailureMapper englishMapper = LocalizedFailureMapper(
      english,
    );
    final LocalizedFailureMapper koreanMapper = LocalizedFailureMapper(korean);

    expect(stableKeys.length, LocalizedFailureKey.values.length);
    for (final LocalizedFailureKey key in LocalizedFailureKey.values) {
      expect(englishMapper.message(key), isNotEmpty, reason: key.stableKey);
      expect(koreanMapper.message(key), isNotEmpty, reason: key.stableKey);
    }
  });

  test('keeps every indexed backup failure key unique', () {
    final Set<String> stableKeys = IndexedBackupFailureKey.values
        .map((IndexedBackupFailureKey key) => key.stableKey)
        .toSet();

    expect(stableKeys.length, IndexedBackupFailureKey.values.length);
  });

  test('localizes representative database and permission failures', () {
    final LocalizedFailureMapper korean = LocalizedFailureMapper(
      lookupAppLocalizations(const Locale('ko')),
    );
    final LocalizedFailureMapper english = LocalizedFailureMapper(
      lookupAppLocalizations(const Locale('en')),
    );

    expect(
      korean.message(LocalizedFailureKey.databaseMigration),
      '데이터베이스를 업데이트하지 못했습니다. 기존 데이터베이스는 보존되었습니다.',
    );
    expect(
      english.message(LocalizedFailureKey.notificationPermissionRequired),
      'Notification permission is required to start focus/rest delivery.',
    );
  });

  test('localizes indexed backup failures without exposing Todo titles', () {
    final LocalizedFailureMapper korean = LocalizedFailureMapper(
      lookupAppLocalizations(const Locale('ko')),
    );
    final LocalizedFailureMapper english = LocalizedFailureMapper(
      lookupAppLocalizations(const Locale('en')),
    );

    expect(
      korean.indexedBackupMessage(
        IndexedBackupFailureKey.todoTimeInvalid,
        zeroBasedIndex: 2,
      ),
      '백업의 3번째 Todo 시간이 올바른 HH:mm 형식이 아닙니다.',
    );
    expect(
      english.indexedBackupMessage(
        IndexedBackupFailureKey.todoTitleInvalid,
        zeroBasedIndex: 0,
      ),
      'Todo 1 in the backup has an invalid title.',
    );
    expect(
      () => english.indexedBackupMessage(
        IndexedBackupFailureKey.todoIdInvalid,
        zeroBasedIndex: -1,
      ),
      throwsRangeError,
    );
  });
}
