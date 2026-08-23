import 'dart:collection';

import '../../../contexts/preferences/public_model.dart' show UserPreferences;
import '../../../contexts/todo/public_model.dart' show Todo;

final class BackupFileContent {
  BackupFileContent(Iterable<int> bytes)
    : bytes = UnmodifiableListView<int>(List<int>.of(bytes, growable: false));

  final List<int> bytes;
}

abstract interface class BackupFilePort {
  Future<BackupFileContent?> pickImport({required int maximumBytes});

  Future<bool> saveExport({
    required String suggestedFileName,
    required List<int> bytes,
  });
}

final class PortableBackupData {
  PortableBackupData({
    required this.exportedAt,
    required this.preferences,
    required Iterable<Todo> todos,
    required this.customSoundWasSanitized,
  }) : todos = UnmodifiableListView<Todo>(
         List<Todo>.of(todos, growable: false),
       );

  final DateTime exportedAt;
  final UserPreferences preferences;
  final List<Todo> todos;
  final bool customSoundWasSanitized;
}

abstract interface class PortableBackupCodec {
  int get maximumFileBytes;

  PortableBackupData decode(List<int> bytes);

  List<int> encode(PortableBackupData data);
}

abstract interface class BackupClock {
  DateTime now();
}

final class BackupReplacementResult {
  const BackupReplacementResult({required this.autoStartRepairRequired});

  final bool autoStartRepairRequired;
}

abstract interface class BackupReplacementPort {
  Future<BackupReplacementResult> replaceAll({
    required UserPreferences preferences,
    required List<Todo> todos,
  });
}

abstract interface class RhythmSafetyPort {
  Future<void> stopForImport();
}

abstract interface class DataImportRefreshPort {
  Future<void> refreshAfterImport();
}
