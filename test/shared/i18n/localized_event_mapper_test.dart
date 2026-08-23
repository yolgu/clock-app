import 'dart:ui';

import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps every event key unique and localized', () {
    final Set<String> stableKeys = LocalizedEventKey.values
        .map((LocalizedEventKey key) => key.stableKey)
        .toSet();
    final LocalizedEventMapper english = LocalizedEventMapper(
      lookupAppLocalizations(const Locale('en')),
    );
    final LocalizedEventMapper korean = LocalizedEventMapper(
      lookupAppLocalizations(const Locale('ko')),
    );

    expect(stableKeys.length, LocalizedEventKey.values.length);
    for (final LocalizedEventKey key in LocalizedEventKey.values) {
      expect(english.message(key), isNotEmpty, reason: key.stableKey);
      expect(korean.message(key), isNotEmpty, reason: key.stableKey);
    }
  });

  test('localizes tray commands and one-time accessibility announcements', () {
    final LocalizedEventMapper korean = LocalizedEventMapper(
      lookupAppLocalizations(const Locale('ko')),
    );
    final LocalizedEventMapper english = LocalizedEventMapper(
      lookupAppLocalizations(const Locale('en')),
    );

    expect(korean.message(LocalizedEventKey.trayOpen), '열기');
    expect(english.message(LocalizedEventKey.trayQuit), 'Quit Clock Rhythm');
    expect(
      korean.message(LocalizedEventKey.announcementRhythmRunning),
      '집중 시간대를 시작했습니다.',
    );
    expect(
      english.message(LocalizedEventKey.announcementBackupImported),
      'Portable Backup imported. Local data was replaced.',
    );
  });

  test('builds localized native notification payload strings', () {
    final LocalizedEventMapper korean = LocalizedEventMapper(
      lookupAppLocalizations(const Locale('ko')),
    );
    final LocalizedEventMapper english = LocalizedEventMapper(
      lookupAppLocalizations(const Locale('en')),
    );

    expect(
      korean.notificationPayload(RhythmNotificationEvent.focusEnded),
      const LocalizedNotificationPayload(
        title: '휴식 시간입니다',
        body: '집중 시간이 끝났습니다.',
      ),
    );
    expect(
      english.notificationPayload(RhythmNotificationEvent.restEnded),
      const LocalizedNotificationPayload(
        title: 'Time to focus again',
        body: 'The Rest Interval has ended.',
      ),
    );
  });
}
