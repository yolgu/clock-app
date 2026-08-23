import '../../../../contexts/preferences/public_model.dart'
    show UserPreferences;
import '../../../../contexts/todo/public_model.dart' show Todo;

final class BackupV1DocumentDto {
  BackupV1DocumentDto({
    required this.exportedAt,
    required this.preferences,
    required List<Todo> todos,
    required this.customSoundWasSanitized,
  }) : todos = List<Todo>.unmodifiable(todos);

  final DateTime exportedAt;
  final UserPreferences preferences;
  final List<Todo> todos;
  final bool customSoundWasSanitized;
}
