import 'dart:async';
import 'dart:typed_data';

import 'package:clock_rhythm/app/infrastructure/file_picker_backup_file_adapter.dart';
import 'package:clock_rhythm/features/data_transfer/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cancel returns null without reading', () async {
    final FakeBackupFilePickerGateway gateway = FakeBackupFilePickerGateway();

    final BackupFileContent? content = await FilePickerBackupFileAdapter(
      gateway: gateway,
    ).pickImport(maximumBytes: 32);

    expect(content, isNull);
  });

  test('metadata limit rejects before opening the stream', () async {
    final FakePickedBackupFile file = FakePickedBackupFile(
      declaredLength: 33,
      chunks: <List<int>>[
        <int>[1],
      ],
    );
    final FakeBackupFilePickerGateway gateway = FakeBackupFilePickerGateway()
      ..picked = file;

    await expectLater(
      FilePickerBackupFileAdapter(
        gateway: gateway,
      ).pickImport(maximumBytes: 32),
      _backupFailure(BackupFailureKey.fileTooLarge),
    );
    expect(file.openCount, 0);
  });

  test(
    'stream limit rejects deceptive metadata without full allocation',
    () async {
      final FakePickedBackupFile file = FakePickedBackupFile(
        declaredLength: 2,
        chunks: <List<int>>[
          List<int>.filled(24, 1),
          List<int>.filled(16, 2),
          List<int>.filled(1024, 3),
        ],
      );
      final FakeBackupFilePickerGateway gateway = FakeBackupFilePickerGateway()
        ..picked = file;

      await expectLater(
        FilePickerBackupFileAdapter(
          gateway: gateway,
        ).pickImport(maximumBytes: 32),
        _backupFailure(BackupFailureKey.fileTooLarge),
      );
      expect(file.emittedChunkCount, 2);
    },
  );

  test('reads a valid selection incrementally', () async {
    final FakeBackupFilePickerGateway gateway = FakeBackupFilePickerGateway()
      ..picked = FakePickedBackupFile(
        declaredLength: 4,
        chunks: <List<int>>[
          <int>[1, 2],
          <int>[3, 4],
        ],
      );

    final BackupFileContent? content = await FilePickerBackupFileAdapter(
      gateway: gateway,
    ).pickImport(maximumBytes: 4);

    expect(content?.bytes, <int>[1, 2, 3, 4]);
  });

  test('maps picker and stream errors to fileRead', () async {
    final FakeBackupFilePickerGateway pickerFailure =
        FakeBackupFilePickerGateway()
          ..pickFailure = StateError('picker unavailable');
    final FakeBackupFilePickerGateway streamFailure =
        FakeBackupFilePickerGateway()
          ..picked = FakePickedBackupFile(
            declaredLength: 1,
            chunks: const <List<int>>[],
            streamFailure: StateError('read unavailable'),
          );

    await expectLater(
      FilePickerBackupFileAdapter(
        gateway: pickerFailure,
      ).pickImport(maximumBytes: 32),
      _backupFailure(BackupFailureKey.fileRead),
    );
    await expectLater(
      FilePickerBackupFileAdapter(
        gateway: streamFailure,
      ).pickImport(maximumBytes: 32),
      _backupFailure(BackupFailureKey.fileRead),
    );
  });

  test('export distinguishes cancel, success, and write failure', () async {
    final FakeBackupFilePickerGateway gateway = FakeBackupFilePickerGateway();
    final FilePickerBackupFileAdapter adapter = FilePickerBackupFileAdapter(
      gateway: gateway,
    );

    expect(
      await adapter.saveExport(
        suggestedFileName: 'backup.json',
        bytes: <int>[1, 2],
      ),
      isFalse,
    );
    gateway.saveResult = true;
    expect(
      await adapter.saveExport(
        suggestedFileName: 'backup.json',
        bytes: <int>[1, 2],
      ),
      isTrue,
    );
    expect(gateway.savedBytes, <int>[1, 2]);
    gateway.saveFailure = StateError('write unavailable');
    await expectLater(
      adapter.saveExport(suggestedFileName: 'backup.json', bytes: <int>[1, 2]),
      _backupFailure(BackupFailureKey.fileWrite),
    );
  });
}

Matcher _backupFailure(BackupFailureKey key) {
  return throwsA(
    isA<BackupFailure>().having(
      (BackupFailure failure) => failure.key,
      'key',
      key,
    ),
  );
}

final class FakeBackupFilePickerGateway implements BackupFilePickerGateway {
  PickedBackupFile? picked;
  Object? pickFailure;
  Object? saveFailure;
  bool saveResult = false;
  Uint8List? savedBytes;

  @override
  Future<PickedBackupFile?> pickJson() async {
    final Object? failure = pickFailure;
    if (failure != null) {
      throw failure;
    }
    return picked;
  }

  @override
  Future<bool> saveJson({
    required String suggestedFileName,
    required Uint8List bytes,
  }) async {
    final Object? failure = saveFailure;
    if (failure != null) {
      throw failure;
    }
    savedBytes = bytes;
    return saveResult;
  }
}

final class FakePickedBackupFile implements PickedBackupFile {
  FakePickedBackupFile({
    required this.declaredLength,
    required this.chunks,
    this.streamFailure,
  });

  final int declaredLength;
  final List<List<int>> chunks;
  final Object? streamFailure;
  int openCount = 0;
  int emittedChunkCount = 0;

  @override
  Future<int> length() async => declaredLength;

  @override
  Stream<List<int>> openRead() async* {
    openCount += 1;
    final Object? failure = streamFailure;
    if (failure != null) {
      throw failure;
    }
    for (final List<int> chunk in chunks) {
      emittedChunkCount += 1;
      yield chunk;
    }
  }
}
