import 'dart:async';

import '../../../contexts/preferences/public.dart'
    show PreferencesRepairNeed, PreferencesRepairStatePort;

final class PlatformPreferencesRepairRegistry
    implements PreferencesRepairStatePort {
  final Set<PreferencesRepairNeed> _current = <PreferencesRepairNeed>{};
  final StreamController<Set<PreferencesRepairNeed>> _changes =
      StreamController<Set<PreferencesRepairNeed>>.broadcast(sync: true);
  bool _disposed = false;

  @override
  Set<PreferencesRepairNeed> get current =>
      Set<PreferencesRepairNeed>.unmodifiable(_current);

  @override
  Stream<Set<PreferencesRepairNeed>> watch() {
    _requireActive();
    return Stream<Set<PreferencesRepairNeed>>.multi((
      MultiStreamController<Set<PreferencesRepairNeed>> controller,
    ) {
      final StreamSubscription<Set<PreferencesRepairNeed>> subscription =
          _changes.stream.listen(
            controller.addSync,
            onDone: controller.closeSync,
          );
      controller.onCancel = subscription.cancel;
      controller.addSync(current);
    });
  }

  @override
  void report(PreferencesRepairNeed need) {
    _requireActive();
    if (_current.add(need)) {
      _publish();
    }
  }

  @override
  void recordCommandResult({
    required Set<PreferencesRepairNeed> attempted,
    required Set<PreferencesRepairNeed> reported,
  }) {
    _requireActive();
    final Set<PreferencesRepairNeed> before = Set<PreferencesRepairNeed>.of(
      _current,
    );
    _current
      ..removeAll(attempted)
      ..addAll(reported);
    if (!_sameNeeds(before, _current)) {
      _publish();
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _changes.close();
  }

  void _publish() {
    _changes.add(current);
  }

  bool _sameNeeds(
    Set<PreferencesRepairNeed> left,
    Set<PreferencesRepairNeed> right,
  ) {
    return left.length == right.length && left.containsAll(right);
  }

  void _requireActive() {
    if (_disposed) {
      throw StateError('PlatformPreferencesRepairRegistry is disposed.');
    }
  }
}
