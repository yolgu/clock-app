import 'dart:io';

final class DatabaseRecoveryArchive {
  DatabaseRecoveryArchive({
    required this.originalDatabasePath,
    required this.directoryPath,
    required Iterable<String> archivedFileNames,
  }) : archivedFileNames = List<String>.unmodifiable(archivedFileNames);

  final String originalDatabasePath;
  final String directoryPath;
  final List<String> archivedFileNames;
}

final class DatabaseRecoveryArchiveFailure implements Exception {
  const DatabaseRecoveryArchiveFailure({required this.causeType});

  final String causeType;

  @override
  String toString() => 'DatabaseRecoveryArchiveFailure($causeType)';
}

final class DatabaseRecoveryFileManager {
  DatabaseRecoveryFileManager({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Future<DatabaseRecoveryArchive?> preserveForReset(String databasePath) {
    return _preserveExisting(databasePath, archiveKind: 'recovery');
  }

  Future<DatabaseRecoveryArchive?> restoreAfterFailedReset(
    DatabaseRecoveryArchive archive,
  ) async {
    final DatabaseRecoveryArchive? failedAttempt = await _preserveExisting(
      archive.originalDatabasePath,
      archiveKind: 'failed-reset',
    );
    final List<(File archived, File restored)> movedBack =
        <(File archived, File restored)>[];
    try {
      for (final String fileName in archive.archivedFileNames) {
        final File archived = File(
          '${archive.directoryPath}${Platform.pathSeparator}$fileName',
        );
        final File restored = File(
          _originalPathForFileName(archive.originalDatabasePath, fileName),
        );
        await archived.rename(restored.path);
        movedBack.add((archived, restored));
      }
    } on Object catch (error) {
      try {
        for (final (File archived, File restored) in movedBack.reversed) {
          if (restored.existsSync()) {
            await restored.rename(archived.path);
          }
        }
        if (failedAttempt != null) {
          await _restoreArchiveFiles(failedAttempt);
        }
      } on Object catch (rollbackError) {
        throw DatabaseRecoveryArchiveFailure(
          causeType: '${error.runtimeType}/${rollbackError.runtimeType}',
        );
      }
      rethrow;
    }
    return failedAttempt;
  }

  Future<DatabaseRecoveryArchive?> _preserveExisting(
    String databasePath, {
    required String archiveKind,
  }) async {
    if (databasePath.trim().isEmpty) {
      throw ArgumentError.value(
        databasePath,
        'databasePath',
        'must identify one database file',
      );
    }
    final File databaseFile = File(databasePath).absolute;
    final List<File> existingFiles = <File>[
      databaseFile,
      File('${databaseFile.path}-journal'),
      File('${databaseFile.path}-wal'),
      File('${databaseFile.path}-shm'),
    ].where((File file) => file.existsSync()).toList(growable: false);
    if (existingFiles.isEmpty) {
      return null;
    }
    final String archiveDirectoryPath = _availableArchiveDirectory(
      databaseFile.path,
      archiveKind: archiveKind,
    );
    final Directory archiveDirectory = Directory(archiveDirectoryPath);
    await archiveDirectory.create();
    final List<(File original, File archived)> moved =
        <(File original, File archived)>[];
    try {
      for (final File original in existingFiles) {
        final String name = original.uri.pathSegments.last;
        final File archived = File(
          '${archiveDirectory.path}${Platform.pathSeparator}$name',
        );
        await original.rename(archived.path);
        moved.add((original, archived));
      }
    } on Object catch (error) {
      try {
        for (final (File original, File archived) in moved.reversed) {
          if (archived.existsSync()) {
            await archived.rename(original.path);
          }
        }
      } on Object catch (rollbackError) {
        throw DatabaseRecoveryArchiveFailure(
          causeType: '${error.runtimeType}/${rollbackError.runtimeType}',
        );
      }
      rethrow;
    }
    return DatabaseRecoveryArchive(
      originalDatabasePath: databaseFile.path,
      directoryPath: archiveDirectory.path,
      archivedFileNames: <String>[
        for (final (File _, File archived) in moved)
          archived.uri.pathSegments.last,
      ],
    );
  }

  Future<void> _restoreArchiveFiles(DatabaseRecoveryArchive archive) async {
    for (final String fileName in archive.archivedFileNames) {
      final File archived = File(
        '${archive.directoryPath}${Platform.pathSeparator}$fileName',
      );
      if (!archived.existsSync()) {
        continue;
      }
      await archived.rename(
        _originalPathForFileName(archive.originalDatabasePath, fileName),
      );
    }
  }

  String _originalPathForFileName(String databasePath, String fileName) {
    final String databaseName = File(databasePath).uri.pathSegments.last;
    if (fileName == databaseName) {
      return databasePath;
    }
    if (fileName == '$databaseName-journal') {
      return '$databasePath-journal';
    }
    if (fileName == '$databaseName-wal') {
      return '$databasePath-wal';
    }
    if (fileName == '$databaseName-shm') {
      return '$databasePath-shm';
    }
    throw FormatException('Unexpected database recovery file name.', fileName);
  }

  String _availableArchiveDirectory(
    String databasePath, {
    required String archiveKind,
  }) {
    final String timestamp = _now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[^0-9A-Za-z]'),
      '',
    );
    final String base = '$databasePath.$archiveKind-$timestamp';
    String candidate = base;
    int suffix = 1;
    while (FileSystemEntity.typeSync(candidate, followLinks: false) !=
        FileSystemEntityType.notFound) {
      candidate = '$base-$suffix';
      suffix += 1;
    }
    return candidate;
  }
}
