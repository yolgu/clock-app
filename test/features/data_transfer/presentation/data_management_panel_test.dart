import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/todo/public_model.dart';
import 'package:clock_rhythm/features/data_transfer/public.dart';
import 'package:clock_rhythm/features/data_transfer/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'LB-036 Data management exposes backup controls without Google Tasks setup',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(actions: _RecordingDataTransferActions()),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('data-management-panel')),
        findsOneWidget,
      );
      expect(find.text('Data management'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('export-backup')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('import-backup')),
        findsOneWidget,
      );
      expect(find.textContaining('Google Tasks'), findsNothing);
      expect(find.textContaining('Client ID'), findsNothing);
      expect(find.textContaining('OAuth'), findsNothing);
      expect(find.textContaining('Manual sync'), findsNothing);
    },
  );

  testWidgets(
    'LB-037 export and import require warnings, preview, and explicit replacement confirmation',
    (WidgetTester tester) async {
      final _RecordingDataTransferActions actions =
          _RecordingDataTransferActions(prepared: _preparedImport());
      await tester.pumpWidget(_testApp(actions: actions));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('export-backup')));
      await tester.pumpAndSettle();
      final Finder exportWarning = find.byKey(
        const ValueKey<String>('export-backup-warning-dialog'),
      );
      expect(exportWarning, findsOneWidget);
      expect(actions.calls, isEmpty);

      await tester.tap(
        find.descendant(of: exportWarning, matching: find.byType(FilledButton)),
      );
      await tester.pumpAndSettle();
      expect(actions.calls, <String>['export']);
      expect(
        find.byKey(const ValueKey<String>('backup-exported-feedback')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('import-backup')));
      await tester.pumpAndSettle();
      expect(actions.calls, <String>['export', 'prepare']);
      expect(
        find.byKey(const ValueKey<String>('backup-import-preview-dialog')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Current Preferences and Todos will be fully replaced by this Portable Backup.',
        ),
        findsOneWidget,
      );
      expect(find.text('Private Todo title'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('confirm-backup-import')),
      );
      await tester.pumpAndSettle();

      expect(actions.calls, <String>[
        'export',
        'prepare',
        'confirm',
        'refresh',
      ]);
      expect(
        find.byKey(const ValueKey<String>('backup-import-preview-dialog')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('backup-imported-feedback')),
        findsOneWidget,
      );
    },
  );

  test(
    'LB-039 a successful backup replacement refreshes Todo views afterward',
    () async {
      final _RecordingDataTransferActions actions =
          _RecordingDataTransferActions(prepared: _preparedImport());
      final ProviderContainer container = _container(actions);
      addTearDown(container.dispose);
      final DataTransferViewModel viewModel = container.read(
        dataTransferViewModelProvider.notifier,
      );

      await viewModel.prepareImport();
      await viewModel.confirmImport();

      expect(actions.calls, <String>['prepare', 'confirm', 'refresh']);
      expect(
        container.read(dataTransferViewModelProvider).success,
        DataTransferSuccess.imported,
      );
      expect(
        container.read(dataTransferViewModelProvider).refreshRequired,
        isFalse,
      );
    },
  );

  testWidgets(
    'LB-166 compact Data Transfer and replacement confirmation remain usable',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final _RecordingDataTransferActions actions =
          _RecordingDataTransferActions(prepared: _preparedImport());
      await tester.pumpWidget(_testApp(actions: actions));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const PageStorageKey<String>('data-page-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('export-backup')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('import-backup')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('import-backup')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey<String>('backup-import-preview-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('cancel-backup-import')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('confirm-backup-import')),
        findsOneWidget,
      );
    },
  );

  test(
    'LB-167 Data Transfer owns export feedback independently from Todo state',
    () async {
      final _RecordingDataTransferActions actions =
          _RecordingDataTransferActions();
      final ProviderContainer container = _container(actions);
      addTearDown(container.dispose);
      final DataTransferViewModel viewModel = container.read(
        dataTransferViewModelProvider.notifier,
      );

      await viewModel.exportBackup();

      final DataTransferState state = container.read(
        dataTransferViewModelProvider,
      );
      expect(actions.calls, <String>['export']);
      expect(state.success, DataTransferSuccess.exported);
      expect(state.prepared, isNull);
      expect(state.failure, isNull);
    },
  );
}

Widget _testApp({required DataTransferActions actions}) {
  return ProviderScope(
    overrides: [dataTransferActionsProvider.overrideWithValue(actions)],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: DataPage()),
    ),
  );
}

ProviderContainer _container(DataTransferActions actions) {
  return ProviderContainer(
    overrides: [dataTransferActionsProvider.overrideWithValue(actions)],
  );
}

PreparedBackupImport _preparedImport() {
  return PreparedBackupImport.fromValidatedData(
    data: PortableBackupData(
      exportedAt: DateTime.utc(2026, 8, 23),
      preferences: UserPreferences.defaults(),
      todos: <Todo>[_todo()],
      customSoundWasSanitized: false,
    ),
    currentAutoStartEnabled: false,
  );
}

Todo _todo() {
  return Todo.restore(
    const TodoRestoreSnapshot(
      id: 'private-todo',
      title: 'Private Todo title',
      date: '2026-08-23',
      time: null,
      completed: false,
      displayOrder: 0,
      createdAt: '2026-08-23T00:00:00.000Z',
      updatedAt: '2026-08-23T00:00:00.000Z',
    ),
  );
}

final class _RecordingDataTransferActions implements DataTransferActions {
  _RecordingDataTransferActions({this.prepared});

  final PreparedBackupImport? prepared;
  final List<String> calls = <String>[];

  @override
  Future<ConfirmBackupImportResult> confirmImport(
    PreparedBackupImport prepared,
  ) async {
    calls.add('confirm');
    return const ConfirmBackupImportResult(autoStartRepairRequired: false);
  }

  @override
  Future<bool> exportBackup() async {
    calls.add('export');
    return true;
  }

  @override
  Future<PreparedBackupImport?> prepareImport() async {
    calls.add('prepare');
    return prepared;
  }

  @override
  Future<void> refreshAfterImport() async {
    calls.add('refresh');
  }
}
