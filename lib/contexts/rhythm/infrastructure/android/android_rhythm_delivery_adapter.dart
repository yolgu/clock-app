import '../../application/ports/rhythm_delivery_port.dart';
import '../../domain/rhythm_event.dart';
import 'android_delivery_dto.dart';
import 'android_rhythm_channel.dart';

typedef AndroidRhythmPlanContextLoader =
    Future<AndroidRhythmPlanContext> Function();
typedef AndroidRhythmRouteActivation = Future<void> Function(String route);

abstract interface class AndroidRhythmDeliveryPort
    implements RhythmDeliveryPort {
  Future<AndroidRhythmDeliveryStatus> status();

  Future<void> replacePresentation(
    AndroidRhythmNotificationPresentation presentation,
  );

  Future<void> reconcilePlan(AndroidRhythmDeliveryPlan plan);

  Future<void> reconcileAt(DateTime observedAt);

  void dispose();
}

final class AndroidRhythmDeliveryAdapter implements AndroidRhythmDeliveryPort {
  factory AndroidRhythmDeliveryAdapter({
    required AndroidRhythmPlanContextLoader loadPlanContext,
    required AndroidRhythmRouteActivation activateRoute,
    AndroidRhythmChannel? channel,
    AndroidRhythmDeliveryPlanFactory planFactory =
        const AndroidRhythmDeliveryPlanFactory(),
  }) {
    return AndroidRhythmDeliveryAdapter._(
      loadPlanContext: loadPlanContext,
      activateRoute: activateRoute,
      channel: channel ?? MethodChannelAndroidRhythmChannel(),
      planFactory: planFactory,
    );
  }

  AndroidRhythmDeliveryAdapter._({
    required this._loadPlanContext,
    required this._activateRoute,
    required this._channel,
    required this._planFactory,
  }) {
    _channel.setHandler(_handleNativeCall);
  }

  final AndroidRhythmPlanContextLoader _loadPlanContext;
  final AndroidRhythmRouteActivation _activateRoute;
  final AndroidRhythmChannel _channel;
  final AndroidRhythmDeliveryPlanFactory _planFactory;
  Future<void> _operationTail = Future<void>.value();
  bool _disposed = false;

  @override
  Future<void> cancelScheduledEvent() {
    return _serialized<void>(() async {
      await _channel.invoke(AndroidRhythmChannelMethod.cancel);
    });
  }

  @override
  Future<void> schedule(RhythmEvent event) {
    return _serialized<void>(() async {
      final AndroidRhythmDeliveryStatus current = await _loadStatus();
      final AndroidRhythmPlanContext context = await _loadPlanContext();
      final AndroidRhythmDeliveryPlan plan = _planFactory.forScheduledEvent(
        currentEvent: event,
        context: context,
        revision: _nextRevision(current.revision),
      );
      if (!plan.hasMinimumPrecomputedQueue) {
        throw const AndroidRhythmDeliveryFailure(
          code: AndroidRhythmDeliveryFailureCode.invalidPayload,
          message: 'An Android Rhythm plan requires three occurrences.',
        );
      }
      await _channel.invoke(
        AndroidRhythmChannelMethod.schedule,
        plan.toChannelMap(),
      );
    });
  }

  @override
  Future<AndroidRhythmDeliveryStatus> status() {
    return _serialized<AndroidRhythmDeliveryStatus>(_loadStatus);
  }

  @override
  Future<void> replacePresentation(
    AndroidRhythmNotificationPresentation presentation,
  ) {
    return _serialized<void>(() async {
      final AndroidRhythmDeliveryStatus current = await _loadStatus();
      _requireAutomaticMutationAllowed(current);
      final AndroidRhythmDeliveryPlan? activePlan = current.activePlan;
      if (activePlan == null) {
        if (current.isActive) {
          throw const AndroidRhythmDeliveryFailure(
            code: AndroidRhythmDeliveryFailureCode.stateUnavailable,
            message:
                'Android Rhythm delivery needs reconciliation before '
                'payload replacement.',
          );
        }
        return;
      }
      final AndroidRhythmDeliveryPlan replacement = activePlan
          .replacePresentation(
            presentation: presentation,
            revision: _nextRevision(current.revision),
          );
      await _channel.invoke(
        AndroidRhythmChannelMethod.replacePayload,
        replacement.toChannelMap(),
      );
    });
  }

  @override
  Future<void> reconcilePlan(AndroidRhythmDeliveryPlan plan) {
    return _serialized<void>(() async {
      final AndroidRhythmDeliveryStatus current = await _loadStatus();
      _requireAutomaticMutationAllowed(current);
      if (!current.isActive) {
        throw const AndroidRhythmDeliveryFailure(
          code: AndroidRhythmDeliveryFailureCode.stateUnavailable,
          message: 'Inactive Android Rhythm delivery cannot be reconciled.',
        );
      }
      if (!plan.hasMinimumPrecomputedQueue) {
        throw const AndroidRhythmDeliveryFailure(
          code: AndroidRhythmDeliveryFailureCode.invalidPayload,
          message:
              'A reconciled Android Rhythm plan requires three occurrences.',
        );
      }
      await _channel.invoke(
        AndroidRhythmChannelMethod.reconcile,
        plan.toChannelMap(),
      );
    });
  }

  @override
  Future<void> reconcileAt(DateTime observedAt) {
    return _serialized<void>(() async {
      final AndroidRhythmDeliveryStatus current = await _loadStatus();
      _requireAutomaticMutationAllowed(current);
      if (!current.isActive) {
        throw const AndroidRhythmDeliveryFailure(
          code: AndroidRhythmDeliveryFailureCode.stateUnavailable,
          message: 'Inactive Android Rhythm delivery cannot be reconciled.',
        );
      }
      final AndroidRhythmPlanContext context = await _loadPlanContext();
      final AndroidRhythmDeliveryPlan replacement = _planFactory
          .forReconciliation(
            observedAt: observedAt,
            context: context,
            currentRevision: current.revision,
          );
      await _channel.invoke(
        AndroidRhythmChannelMethod.reconcile,
        replacement.toChannelMap(),
      );
    });
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _channel.setHandler(null);
  }

  Future<AndroidRhythmDeliveryStatus> _loadStatus() async {
    final Object? response = await _channel.invoke(
      AndroidRhythmChannelMethod.status,
    );
    return AndroidRhythmDeliveryStatus.fromChannelMap(
      requireAndroidRhythmChannelMap(
        response,
        AndroidRhythmChannelMethod.status,
      ),
    );
  }

  void _requireAutomaticMutationAllowed(AndroidRhythmDeliveryStatus current) {
    if (current.needsRecovery) {
      throw const AndroidRhythmDeliveryFailure(
        code: AndroidRhythmDeliveryFailureCode.stateUnavailable,
        message:
            'Android Rhythm delivery requires an explicit Recovery or Start.',
      );
    }
  }

  Future<Object?> _handleNativeCall(String method, Object? arguments) async {
    if (method != AndroidRhythmChannelMethod.activateClock) {
      throw AndroidRhythmDeliveryFailure(
        code: AndroidRhythmDeliveryFailureCode.invalidPayload,
        message: 'Unsupported native Android Rhythm call: $method',
      );
    }
    final Map<Object?, Object?> map = requireAndroidRhythmChannelMap(
      arguments,
      method,
    );
    final Object? routeValue = map['route'];
    if (routeValue is! String || routeValue != '/clock') {
      throw const AndroidRhythmDeliveryFailure(
        code: AndroidRhythmDeliveryFailureCode.invalidPayload,
        message: 'Android Rhythm activation must target /clock.',
      );
    }
    await _activateRoute(routeValue);
    return null;
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    if (_disposed) {
      return Future<T>.error(
        const AndroidRhythmDeliveryFailure(
          code: AndroidRhythmDeliveryFailureCode.channelUnavailable,
          message: 'Android Rhythm delivery adapter is disposed.',
        ),
      );
    }
    final Future<void> previous = _operationTail;
    final Future<T> result = previous.then<T>((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}

int _nextRevision(int currentRevision) {
  if (currentRevision >= 0x7FFFFFFFFFFFFFFF) {
    throw const AndroidRhythmDeliveryFailure(
      code: AndroidRhythmDeliveryFailureCode.stateUnavailable,
      message: 'Android Rhythm delivery revision is exhausted.',
    );
  }
  return currentRevision + 1;
}
