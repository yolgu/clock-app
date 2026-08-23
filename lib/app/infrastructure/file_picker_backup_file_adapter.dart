import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../features/data_transfer/public.dart'
    show BackupFailure, BackupFailureKey, BackupFileContent, BackupFilePort;

abstract interface class PickedBackupFile {
  Future<int> length();

  Stream<List<int>> openRead();
}

abstract interface class BackupFilePickerGateway {
  Future<PickedBackupFile?> pickJson();

  Future<bool> saveJson({
    required String suggestedFileName,
    required Uint8List bytes,
  });
}

final class FilePickerBackupFileAdapter implements BackupFilePort {
  FilePickerBackupFileAdapter({BackupFilePickerGateway? gateway})
    : _gateway = gateway ?? const PluginBackupFilePickerGateway();

  final BackupFilePickerGateway _gateway;

  @override
  Future<BackupFileContent?> pickImport({required int maximumBytes}) async {
    if (maximumBytes <= 0) {
      throw ArgumentError.value(
        maximumBytes,
        'maximumBytes',
        'must be positive',
      );
    }
    try {
      final PickedBackupFile? selected = await _gateway.pickJson();
      if (selected == null) {
        return null;
      }
      if (await selected.length() > maximumBytes) {
        throw const BackupFailure(key: BackupFailureKey.fileTooLarge);
      }
      final BytesBuilder builder = BytesBuilder(copy: false);
      int bytesRead = 0;
      await for (final List<int> chunk in selected.openRead()) {
        bytesRead += chunk.length;
        if (bytesRead > maximumBytes) {
          throw const BackupFailure(key: BackupFailureKey.fileTooLarge);
        }
        builder.add(chunk);
      }
      return BackupFileContent(builder.takeBytes());
    } on BackupFailure {
      rethrow;
    } on Object {
      throw const BackupFailure(key: BackupFailureKey.fileRead);
    }
  }

  @override
  Future<bool> saveExport({
    required String suggestedFileName,
    required List<int> bytes,
  }) async {
    try {
      return await _gateway.saveJson(
        suggestedFileName: suggestedFileName,
        bytes: Uint8List.fromList(bytes),
      );
    } on Object {
      throw const BackupFailure(key: BackupFailureKey.fileWrite);
    }
  }
}

final class PluginBackupFilePickerGateway implements BackupFilePickerGateway {
  const PluginBackupFilePickerGateway();

  @override
  Future<PickedBackupFile?> pickJson() async {
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    return file == null ? null : _PluginPickedBackupFile(file);
  }

  @override
  Future<bool> saveJson({
    required String suggestedFileName,
    required Uint8List bytes,
  }) async {
    final Uri? saved = await FilePicker.saveFile(
      fileName: suggestedFileName,
      bytes: bytes,
      mimeType: 'application/json',
    );
    return saved != null;
  }
}

final class _PluginPickedBackupFile implements PickedBackupFile {
  const _PluginPickedBackupFile(this._file);

  final PlatformFile _file;

  @override
  Future<int> length() {
    return _file.length();
  }

  @override
  Stream<List<int>> openRead() {
    return _file.readAsByteStream();
  }
}
