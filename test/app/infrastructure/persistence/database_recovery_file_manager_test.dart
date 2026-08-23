import 'dart:io';

import 'package:clock_rhythm/app/infrastructure/persistence/database_recovery_file_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'moves the database and SQLite sidecars into one recovery archive',
    () async {
      final Directory temporary = await Directory.systemTemp.createTemp(
        'clock-rhythm-recovery-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final String databasePath =
          '${temporary.path}${Platform.pathSeparator}clock_rhythm.sqlite';
      final Map<String, String> contents = <String, String>{
        databasePath: 'database',
        '$databasePath-journal': 'rollback journal',
        '$databasePath-wal': 'wal',
        '$databasePath-shm': 'shm',
      };
      for (final MapEntry<String, String> entry in contents.entries) {
        await File(entry.key).writeAsString(entry.value);
      }
      final DatabaseRecoveryFileManager manager = DatabaseRecoveryFileManager(
        now: () => DateTime.utc(2026, 8, 23, 3, 4, 5),
      );

      final DatabaseRecoveryArchive? archive = await manager.preserveForReset(
        databasePath,
      );

      expect(archive, isNotNull);
      expect(archive!.directoryPath, contains('recovery-20260823T030405000Z'));
      expect(archive.archivedFileNames, <String>[
        'clock_rhythm.sqlite',
        'clock_rhythm.sqlite-journal',
        'clock_rhythm.sqlite-wal',
        'clock_rhythm.sqlite-shm',
      ]);
      for (final MapEntry<String, String> entry in contents.entries) {
        expect(File(entry.key).existsSync(), isFalse);
        final String fileName = File(entry.key).uri.pathSegments.last;
        final File archived = File(
          '${archive.directoryPath}${Platform.pathSeparator}$fileName',
        );
        expect(await archived.readAsString(), entry.value);
      }
    },
  );

  test('does not create an archive when no database files exist', () async {
    final Directory temporary = await Directory.systemTemp.createTemp(
      'clock-rhythm-recovery-empty-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final String databasePath =
        '${temporary.path}${Platform.pathSeparator}clock_rhythm.sqlite';
    final DatabaseRecoveryFileManager manager = DatabaseRecoveryFileManager();

    final DatabaseRecoveryArchive? archive = await manager.preserveForReset(
      databasePath,
    );

    expect(archive, isNull);
    expect(temporary.listSync(), isEmpty);
  });

  test('restores the original and preserves a failed reset attempt', () async {
    final Directory temporary = await Directory.systemTemp.createTemp(
      'clock-rhythm-recovery-restore-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final String databasePath =
        '${temporary.path}${Platform.pathSeparator}clock_rhythm.sqlite';
    await File(databasePath).writeAsString('original');
    await File('$databasePath-journal').writeAsString('original journal');
    final DatabaseRecoveryFileManager manager = DatabaseRecoveryFileManager(
      now: () => DateTime.utc(2026, 8, 23, 3, 4, 5),
    );
    final DatabaseRecoveryArchive archive = (await manager.preserveForReset(
      databasePath,
    ))!;
    await File(databasePath).writeAsString('failed replacement');
    await File('$databasePath-journal').writeAsString('failed journal');

    final DatabaseRecoveryArchive? failedAttempt = await manager
        .restoreAfterFailedReset(archive);

    expect(await File(databasePath).readAsString(), 'original');
    expect(
      await File('$databasePath-journal').readAsString(),
      'original journal',
    );
    expect(failedAttempt, isNotNull);
    final File preservedFailure = File(
      '${failedAttempt!.directoryPath}${Platform.pathSeparator}clock_rhythm.sqlite',
    );
    expect(await preservedFailure.readAsString(), 'failed replacement');
    final File preservedFailedJournal = File(
      '${failedAttempt.directoryPath}${Platform.pathSeparator}clock_rhythm.sqlite-journal',
    );
    expect(await preservedFailedJournal.readAsString(), 'failed journal');
  });
}
