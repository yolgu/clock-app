import 'package:clock_rhythm/contexts/rhythm/application/ports/rhythm_start_capability.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_event.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/android/android_background_entrypoint.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/android/android_delivery_capability_adapter.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/android/android_delivery_dto.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/android/android_rhythm_channel.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/android/android_rhythm_delivery_adapter.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidRhythmDeliveryAdapter', () {
    test(
      'serializes a current plus two future plan after native status',
      () async {
        final FakeAndroidRhythmChannel channel = FakeAndroidRhythmChannel();
        channel.responses[AndroidRhythmChannelMethod.status] =
            _inactiveStatusMap(revision: 4);
        final List<String> activatedRoutes = <String>[];
        final AndroidRhythmDeliveryAdapter adapter =
            AndroidRhythmDeliveryAdapter(
              loadPlanContext: () async => _planContext(),
              activateRoute: (String route) async => activatedRoutes.add(route),
              channel: channel,
            );

        await adapter.schedule(_currentEvent());

        expect(channel.calls.map((ChannelCall call) => call.method), <String>[
          AndroidRhythmChannelMethod.status,
          AndroidRhythmChannelMethod.schedule,
        ]);
        final AndroidRhythmDeliveryPlan plan =
            AndroidRhythmDeliveryPlan.fromChannelMap(
              channel.calls.last.arguments! as Map<Object?, Object?>,
            );
        expect(plan.revision, 5);
        expect(plan.occurrences, hasLength(3));

        await channel.emit(
          AndroidRhythmChannelMethod.activateClock,
          <String, Object?>{'route': '/clock'},
        );
        expect(activatedRoutes, <String>['/clock']);
        adapter.dispose();
      },
    );

    test(
      'payload replacement keeps the native occurrence queue unchanged',
      () async {
        final FakeAndroidRhythmChannel channel = FakeAndroidRhythmChannel();
        const AndroidRhythmDeliveryPlanFactory factory =
            AndroidRhythmDeliveryPlanFactory();
        final AndroidRhythmDeliveryPlan activePlan = factory.forScheduledEvent(
          currentEvent: _currentEvent(),
          context: _planContext(),
          revision: 8,
        );
        channel.responses[AndroidRhythmChannelMethod.status] = _activeStatusMap(
          activePlan,
        );
        final AndroidRhythmDeliveryAdapter adapter =
            AndroidRhythmDeliveryAdapter(
              loadPlanContext: () async => _planContext(),
              activateRoute: (String _) async {},
              channel: channel,
            );

        await adapter.replacePresentation(_mutedKoreanPresentation());

        final AndroidRhythmDeliveryPlan replacement =
            AndroidRhythmDeliveryPlan.fromChannelMap(
              channel.calls.last.arguments! as Map<Object?, Object?>,
            );
        expect(
          channel.calls.last.method,
          AndroidRhythmChannelMethod.replacePayload,
        );
        expect(replacement.revision, 9);
        expect(
          replacement.occurrences.map(
            (AndroidRhythmOccurrence occurrence) => occurrence.occurrenceId,
          ),
          activePlan.occurrences.map(
            (AndroidRhythmOccurrence occurrence) => occurrence.occurrenceId,
          ),
        );
        expect(
          replacement.occurrences.every(
            (AndroidRhythmOccurrence value) => value.muted,
          ),
          isTrue,
        );
        adapter.dispose();
      },
    );

    test(
      'fails payload replacement explicitly for queue recovery state',
      () async {
        final FakeAndroidRhythmChannel channel = FakeAndroidRhythmChannel();
        channel.responses[AndroidRhythmChannelMethod.status] =
            <String, Object?>{
              'revision': 18,
              'isActive': true,
              'needsRecovery': true,
              'activePlan': null,
            };
        final AndroidRhythmDeliveryAdapter adapter =
            AndroidRhythmDeliveryAdapter(
              loadPlanContext: () async => _planContext(),
              activateRoute: (String _) async {},
              channel: channel,
            );

        await expectLater(
          adapter.replacePresentation(_mutedKoreanPresentation()),
          throwsA(
            isA<AndroidRhythmDeliveryFailure>().having(
              (AndroidRhythmDeliveryFailure failure) => failure.code,
              'code',
              AndroidRhythmDeliveryFailureCode.stateUnavailable,
            ),
          ),
        );
        adapter.dispose();
      },
    );

    test(
      'blocks automatic payload and schedule reconciliation during user recovery',
      () async {
        final FakeAndroidRhythmChannel channel = FakeAndroidRhythmChannel();
        const AndroidRhythmDeliveryPlanFactory factory =
            AndroidRhythmDeliveryPlanFactory();
        final AndroidRhythmDeliveryPlan activePlan = factory.forScheduledEvent(
          currentEvent: _currentEvent(),
          context: _planContext(),
          revision: 19,
        );
        channel.responses[AndroidRhythmChannelMethod.status] =
            <String, Object?>{
              ..._activeStatusMap(activePlan),
              'needsRecovery': true,
              'recoveryReason': 'permissionLost',
            };
        final AndroidRhythmDeliveryAdapter adapter =
            AndroidRhythmDeliveryAdapter(
              loadPlanContext: () async => _planContext(),
              activateRoute: (String _) async {},
              channel: channel,
            );

        await expectLater(
          adapter.replacePresentation(_mutedKoreanPresentation()),
          throwsA(isA<AndroidRhythmDeliveryFailure>()),
        );
        await expectLater(
          adapter.reconcileAt(DateTime(2026, 8, 23, 6, 5)),
          throwsA(isA<AndroidRhythmDeliveryFailure>()),
        );

        expect(
          channel.calls.every(
            (ChannelCall call) =>
                call.method == AndroidRhythmChannelMethod.status,
          ),
          isTrue,
        );
        adapter.dispose();
      },
    );

    test(
      'reconciles an active session from the shared Dart schedule',
      () async {
        final FakeAndroidRhythmChannel channel = FakeAndroidRhythmChannel();
        const AndroidRhythmDeliveryPlanFactory factory =
            AndroidRhythmDeliveryPlanFactory();
        final AndroidRhythmDeliveryPlan activePlan = factory.forScheduledEvent(
          currentEvent: _currentEvent(),
          context: _planContext(),
          revision: 24,
        );
        channel.responses[AndroidRhythmChannelMethod.status] = _activeStatusMap(
          activePlan,
        );
        final AndroidRhythmDeliveryAdapter adapter =
            AndroidRhythmDeliveryAdapter(
              loadPlanContext: () async => _planContext(),
              activateRoute: (String _) async {},
              channel: channel,
            );

        await adapter.reconcileAt(DateTime(2026, 8, 23, 6, 5));

        expect(channel.calls.last.method, AndroidRhythmChannelMethod.reconcile);
        final AndroidRhythmDeliveryPlan replacement =
            AndroidRhythmDeliveryPlan.fromChannelMap(
              channel.calls.last.arguments! as Map<Object?, Object?>,
            );
        expect(replacement.revision, 25);
        expect(
          replacement.occurrences.first.occursAt,
          DateTime(2026, 8, 23, 6, 50),
        );
        adapter.dispose();
      },
    );
  });

  group('AndroidDeliveryCapabilityAdapter', () {
    test(
      'maps the combined denied capability without committing delivery',
      () async {
        final FakeAndroidRhythmChannel channel = FakeAndroidRhythmChannel();
        channel.responses[AndroidRhythmChannelMethod.requestStartCapability] =
            <String, Object?>{
              'sdkInt': 36,
              'notificationGranted': false,
              'exactAlarmGranted': false,
              'failure': 'notificationAndExactAlarmPermission',
            };
        final AndroidDeliveryCapabilityAdapter adapter =
            AndroidDeliveryCapabilityAdapter(channel: channel);

        final RhythmStartCapabilityResult result = await adapter
            .requestForExplicitStart();

        expect(
          result.failure,
          RhythmStartFailure.notificationAndExactAlarmPermission,
        );
        expect(
          channel.calls.single.method,
          AndroidRhythmChannelMethod.requestStartCapability,
        );
      },
    );

    test('loads capability status independently from delivery state', () async {
      final FakeAndroidRhythmChannel channel = FakeAndroidRhythmChannel();
      channel.responses[AndroidRhythmChannelMethod.capabilityStatus] =
          <String, Object?>{
            'sdkInt': 31,
            'notificationGranted': true,
            'exactAlarmGranted': false,
            'failure': 'exactAlarmPermission',
          };
      final AndroidDeliveryCapabilityAdapter adapter =
          AndroidDeliveryCapabilityAdapter(channel: channel);

      final AndroidDeliveryCapabilityStatus status = await adapter.status();

      expect(status.failure, RhythmStartFailure.exactAlarmPermission);
      expect(
        channel.calls.single.method,
        AndroidRhythmChannelMethod.capabilityStatus,
      );
    });
  });

  test('background entrypoint returns a revisioned refill plan', () async {
    final FakeAndroidRhythmChannel channel = FakeAndroidRhythmChannel();
    final AndroidRhythmBackgroundRequest request =
        AndroidRhythmBackgroundRequest(
          expectedRevision: 12,
          observedAt: DateTime(2026, 8, 23, 6, 5),
          context: _planContext(),
        );
    channel.responses[AndroidRhythmChannelMethod.backgroundReady] = request
        .toChannelMap();

    await runAndroidRhythmBackgroundRefill(channel: channel);

    expect(channel.calls.map((ChannelCall call) => call.method), <String>[
      AndroidRhythmChannelMethod.backgroundReady,
      AndroidRhythmChannelMethod.completeBackgroundRefill,
    ]);
    final Map<Object?, Object?> completion =
        channel.calls.last.arguments! as Map<Object?, Object?>;
    expect(completion['expectedRevision'], 12);
    final AndroidRhythmDeliveryPlan replacement =
        AndroidRhythmDeliveryPlan.fromChannelMap(
          completion['plan']! as Map<Object?, Object?>,
        );
    expect(replacement.revision, 13);
    expect(
      replacement.occurrences.first.occursAt.isAfter(request.observedAt),
      isTrue,
    );
  });
}

final class ChannelCall {
  const ChannelCall(this.method, this.arguments);

  final String method;
  final Object? arguments;
}

final class FakeAndroidRhythmChannel implements AndroidRhythmChannel {
  final Map<String, Object?> responses = <String, Object?>{};
  final List<ChannelCall> calls = <ChannelCall>[];
  AndroidRhythmChannelHandler? _handler;

  @override
  Future<Object?> invoke(String method, [Object? arguments]) async {
    calls.add(ChannelCall(method, arguments));
    return responses[method];
  }

  @override
  void setHandler(AndroidRhythmChannelHandler? handler) {
    _handler = handler;
  }

  Future<Object?> emit(String method, Object? arguments) {
    final AndroidRhythmChannelHandler? handler = _handler;
    if (handler == null) {
      throw StateError('No native call handler is registered.');
    }
    return handler(method, arguments);
  }
}

AndroidRhythmPlanContext _planContext() {
  return AndroidRhythmPlanContext(
    configuration: RhythmConfiguration.defaults(),
    presentation: const AndroidRhythmNotificationPresentation(
      focusEnded: LocalizedNotificationPayload(
        title: 'Focus ended',
        body: 'Take a rest.',
      ),
      restEnded: LocalizedNotificationPayload(
        title: 'Rest ended',
        body: 'Return to focus.',
      ),
      muted: false,
    ),
  );
}

AndroidRhythmNotificationPresentation _mutedKoreanPresentation() {
  return const AndroidRhythmNotificationPresentation(
    focusEnded: LocalizedNotificationPayload(
      title: '집중 종료',
      body: '휴식할 시간입니다.',
    ),
    restEnded: LocalizedNotificationPayload(
      title: '휴식 종료',
      body: '다시 집중할 시간입니다.',
    ),
    muted: true,
  );
}

RhythmEvent _currentEvent() {
  return RhythmEvent(
    kind: RhythmEventKind.focusEnds,
    occursAt: DateTime(2026, 8, 23, 5, 50),
    windowStartsAt: DateTime(2026, 8, 23, 5),
  );
}

Map<String, Object?> _inactiveStatusMap({required int revision}) {
  return <String, Object?>{
    'revision': revision,
    'isActive': false,
    'needsRecovery': false,
    'activePlan': null,
  };
}

Map<String, Object?> _activeStatusMap(AndroidRhythmDeliveryPlan plan) {
  return <String, Object?>{
    'revision': plan.revision,
    'isActive': true,
    'needsRecovery': false,
    'activePlan': plan.toChannelMap(),
  };
}
