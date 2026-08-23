import '../../contexts/rhythm/public.dart' as rhythm;
import '../../contexts/todo/public.dart' as todo;
import '../../features/data_transfer/public.dart' show BackupClock;

final class SystemClock implements rhythm.Clock, todo.Clock, BackupClock {
  SystemClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  DateTime now() => _now();
}
