import 'dart:async';

import 'device_sound_locator_store.dart';

final class DeviceSoundLocatorRollbackFailure implements Exception {
  const DeviceSoundLocatorRollbackFailure({
    required this.operationFailureType,
    required this.rollbackFailureType,
  });

  final String operationFailureType;
  final String rollbackFailureType;

  @override
  String toString() {
    return 'DeviceSoundLocatorRollbackFailure('
        'operation: $operationFailureType, rollback: $rollbackFailureType)';
  }
}

/// Serializes product-data mutations that also update device-only sound state.
///
/// SQLite and the device-state store cannot share one native transaction. This
/// coordinator captures the previous device state and restores it whenever the
/// enclosing database transaction fails after the device write.
final class DeviceSoundLocatorMutationCoordinator {
  DeviceSoundLocatorMutationCoordinator(this._store);

  final DeviceSoundLocatorStore _store;
  Future<void> _pending = Future<void>.value();

  Future<T> run<T>(Future<T> Function() mutation) {
    final Completer<T> completion = Completer<T>();
    _pending = _pending.then((_) async {
      try {
        completion.complete(await _runWithCompensation(mutation));
      } on Object catch (error, stackTrace) {
        completion.completeError(error, stackTrace);
      }
    });
    return completion.future;
  }

  Future<T> _runWithCompensation<T>(Future<T> Function() mutation) async {
    final DeviceSoundLocatorState previousState = await _store.load();
    try {
      return await mutation();
    } on Object catch (operationError, operationStackTrace) {
      bool compensationRequired = true;
      try {
        final DeviceSoundLocatorState currentState = await _store.load();
        compensationRequired = currentState != previousState;
      } on Object {
        // An unreadable or changed state still requires compensation below.
      }
      if (!compensationRequired) {
        Error.throwWithStackTrace(operationError, operationStackTrace);
      }
      try {
        await _store.save(previousState);
      } on Object catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          DeviceSoundLocatorRollbackFailure(
            operationFailureType: operationError.runtimeType.toString(),
            rollbackFailureType: rollbackError.runtimeType.toString(),
          ),
          rollbackStackTrace,
        );
      }
      Error.throwWithStackTrace(operationError, operationStackTrace);
    }
  }
}
