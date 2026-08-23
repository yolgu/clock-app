import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class DatabaseConnectionFactory {
  Future<String> resolveDatabasePath();

  Future<QueryExecutor> open(String databasePath);
}

final class FixedDatabaseConnectionFactory
    implements DatabaseConnectionFactory {
  const FixedDatabaseConnectionFactory({
    required this.path,
    required this.executor,
  });

  final String path;
  final QueryExecutor executor;

  @override
  Future<String> resolveDatabasePath() async => path;

  @override
  Future<QueryExecutor> open(String databasePath) async => executor;
}

final class PrivateDatabaseConnectionFactory
    implements DatabaseConnectionFactory {
  const PrivateDatabaseConnectionFactory({this.databaseName = 'clock_rhythm'});

  final String databaseName;

  @override
  Future<String> resolveDatabasePath() async {
    final Directory directory = await getApplicationSupportDirectory();
    return '${directory.path}${Platform.pathSeparator}$databaseName.sqlite';
  }

  @override
  Future<QueryExecutor> open(String databasePath) async {
    return driftDatabase(
      name: databaseName,
      native: DriftNativeOptions(
        databasePath: () async => databasePath,
        shareAcrossIsolates: true,
      ),
    );
  }
}
