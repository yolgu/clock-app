import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'migrations/migration_plan.dart';

final class DatabaseInspection {
  const DatabaseInspection({
    required this.userVersion,
    required this.integrityResult,
  });

  final int userVersion;
  final String integrityResult;

  bool get isIntegrityValid => integrityResult == 'ok';
}

abstract interface class DatabaseInspector {
  Future<DatabaseInspection?> inspectExisting(String databasePath);
}

/// Inspects an existing SQLite file through a migration-disabled executor.
///
/// The executor only issues PRAGMA reads. In particular, a database created by
/// a newer app version is never handed to Drift's migration lifecycle.
final class NativeDatabaseInspector implements DatabaseInspector {
  const NativeDatabaseInspector();

  @override
  Future<DatabaseInspection?> inspectExisting(String databasePath) async {
    if (databasePath == ':memory:') {
      return null;
    }
    final File databaseFile = File(databasePath);
    if (!await databaseFile.exists()) {
      return null;
    }

    final QueryExecutor executor = NativeDatabase(
      databaseFile,
      enableMigrations: false,
      setup: (database) {
        database.execute('PRAGMA query_only = ON');
      },
    );
    try {
      await executor.ensureOpen(const _NoMigrationInspectionUser());
      final List<Map<String, Object?>> versionRows = await executor.runSelect(
        'PRAGMA user_version',
        const <Object?>[],
      );
      final Object? version = versionRows.single['user_version'];
      if (version is! int || version < 0) {
        throw const FormatException('SQLite user_version is invalid.');
      }
      final List<Map<String, Object?>> integrityRows = await executor.runSelect(
        'PRAGMA integrity_check(1)',
        const <Object?>[],
      );
      final Object? integrity = integrityRows.single.values.singleOrNull;
      if (integrity is! String) {
        throw const FormatException('SQLite integrity result is invalid.');
      }
      return DatabaseInspection(
        userVersion: version,
        integrityResult: integrity,
      );
    } finally {
      await executor.close();
    }
  }
}

final class _NoMigrationInspectionUser implements QueryExecutorUser {
  const _NoMigrationInspectionUser();

  @override
  int get schemaVersion => DatabaseSchema.currentVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
