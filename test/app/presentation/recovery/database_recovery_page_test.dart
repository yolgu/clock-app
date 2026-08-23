import 'dart:async';

import 'package:clock_rhythm/app/presentation/recovery/database_recovery_contract.dart';
import 'package:clock_rhythm/app/presentation/recovery/database_recovery_page.dart';
import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/todo/public_model.dart' show Todo;
import 'package:clock_rhythm/features/data_transfer/public.dart';
import 'package:clock_rhythm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('backup import blocks other recovery mutations until it ends', (
    WidgetTester tester,
  ) async {
    final Completer<PreparedBackupImport?> importCompletion =
        Completer<PreparedBackupImport?>();
    final _RecoveryActions actions = _RecoveryActions();
    await tester.pumpWidget(
      _testApp(
        actions: actions,
        prepareImport: () => importCompletion.future,
        confirmImport: (PreparedBackupImport prepared) async {},
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('recovery-import-backup')),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey<String>('retry-database-open')),
          )
          .onPressed,
      isNull,
    );

    importCompletion.completeError(StateError('injected import failure'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('database-recovery-failure')),
      findsOneWidget,
    );
  });

  testWidgets('backup import requires preview confirmation before mutation', (
    WidgetTester tester,
  ) async {
    final _RecoveryActions actions = _RecoveryActions();
    int confirmCalls = 0;
    final PreparedBackupImport prepared =
        PreparedBackupImport.fromValidatedData(
          data: PortableBackupData(
            exportedAt: DateTime.utc(2026, 8, 23),
            preferences: UserPreferences.defaults(),
            todos: const <Todo>[],
            customSoundWasSanitized: false,
          ),
          currentAutoStartEnabled: false,
        );
    await tester.pumpWidget(
      _testApp(
        actions: actions,
        prepareImport: () async => prepared,
        confirmImport: (PreparedBackupImport prepared) async {
          confirmCalls += 1;
        },
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('recovery-import-backup')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('backup-import-preview-dialog')),
      findsOneWidget,
    );
    expect(confirmCalls, 0);

    await tester.tap(
      find.byKey(const ValueKey<String>('cancel-backup-import')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('backup-import-preview-dialog')),
      findsNothing,
    );
    expect(confirmCalls, 0);
  });

  testWidgets('failed recovery import remains previewed and can be retried', (
    WidgetTester tester,
  ) async {
    int confirmCalls = 0;
    final PreparedBackupImport prepared =
        PreparedBackupImport.fromValidatedData(
          data: PortableBackupData(
            exportedAt: DateTime.utc(2026, 8, 23),
            preferences: UserPreferences.defaults(),
            todos: const <Todo>[],
            customSoundWasSanitized: false,
          ),
          currentAutoStartEnabled: false,
        );
    await tester.pumpWidget(
      _testApp(
        actions: _RecoveryActions(),
        prepareImport: () async => prepared,
        confirmImport: (PreparedBackupImport prepared) async {
          confirmCalls += 1;
          if (confirmCalls == 1) {
            throw const BackupFailure(key: BackupFailureKey.replacement);
          }
        },
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('recovery-import-backup')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('confirm-backup-import')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('backup-confirm-failure')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey<String>('confirm-backup-import')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('confirm-backup-import')),
    );
    await tester.pumpAndSettle();

    expect(confirmCalls, 2);
    expect(
      find.byKey(const ValueKey<String>('backup-import-preview-dialog')),
      findsNothing,
    );
  });

  testWidgets('reset requires two explicit confirmations', (
    WidgetTester tester,
  ) async {
    final _RecoveryActions actions = _RecoveryActions();
    await tester.pumpWidget(
      _testApp(
        actions: actions,
        prepareImport: () async => null,
        confirmImport: (PreparedBackupImport prepared) async {},
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('reset-database')));
    await tester.pumpAndSettle();
    expect(actions.resetCalls, 0);

    await tester.tap(find.byKey(const ValueKey<String>('arm-database-reset')));
    await tester.pump();
    expect(actions.resetCalls, 0);

    await tester.tap(
      find.byKey(const ValueKey<String>('confirm-database-reset')),
    );
    await tester.pumpAndSettle();

    expect(actions.resetCalls, 1);
  });
}

Widget _testApp({
  required DatabaseRecoveryActions actions,
  required Future<PreparedBackupImport?> Function() prepareImport,
  required Future<void> Function(PreparedBackupImport prepared) confirmImport,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: DatabaseRecoveryPage(
      reason: DatabaseRecoveryReason.openOrIntegrity,
      actions: actions,
      onRecovered: () {},
      prepareImport: prepareImport,
      confirmImport: confirmImport,
    ),
  );
}

final class _RecoveryActions implements DatabaseRecoveryActions {
  int retryCalls = 0;
  int resetCalls = 0;

  @override
  Future<bool> retryOpen() async {
    retryCalls += 1;
    return false;
  }

  @override
  Future<bool> resetAfterRecoveryCopy() async {
    resetCalls += 1;
    return false;
  }
}
