import 'package:clock_rhythm/contexts/rhythm/application/delivery_recovery.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/android/android_delivery_dto.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/android/android_delivery_recovery_adapter.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/android/android_rhythm_channel.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidDeliveryRecoveryAdapter', () {
    test('keeps a native inactive intent Idle without configuration', () async {
      final FakeRecoveryChannel channel = FakeRecoveryChannel();
      channel.responses[AndroidRhythmChannelMethod.auditRecovery] =
          <String, Object?>{
            'lifecycleReason': 'foreground',
            'disposition': 'inactive',
            'recoveryReason': null,
            'observedAtEpochMillis': DateTime(
              2026,
              8,
              23,
              6,
            ).millisecondsSinceEpoch,
            'revision': 0,
            'configuration': null,
          };
      final AndroidDeliveryRecoveryAdapter adapter =
          AndroidDeliveryRecoveryAdapter(
            loadPlanContext: () async => _planContext(),
            channel: channel,
          );

      final DeliveryRecoveryStatus status = await adapter.auditForeground();

      expect(status.disposition, DeliveryRecoveryDisposition.inactive);
      expect(status.configuration, isNull);
      expect(status.reason, isNull);
    });

    test(
      'restores Running only from an audited current registration',
      () async {
        final FakeRecoveryChannel channel = FakeRecoveryChannel();
        channel.responses[AndroidRhythmChannelMethod.auditRecovery] = _auditMap(
          disposition: 'running',
          revision: 7,
        );
        final AndroidDeliveryRecoveryAdapter adapter =
            AndroidDeliveryRecoveryAdapter(
              loadPlanContext: () async => _planContext(),
              channel: channel,
            );

        final DeliveryRecoveryStatus status = await adapter.auditForeground();

        expect(status.canRestoreRunning, isTrue);
        expect(status.requiresExplicitRecovery, isFalse);
        expect(status.configuration, RhythmConfiguration.defaults());
        expect(
          channel.calls.single.method,
          AndroidRhythmChannelMethod.auditRecovery,
        );
      },
    );

    test('exposes permission loss as an explicit recovery state', () async {
      final FakeRecoveryChannel channel = FakeRecoveryChannel();
      channel.responses[AndroidRhythmChannelMethod.auditRecovery] = _auditMap(
        disposition: 'needsUserRecovery',
        recoveryReason: 'permissionLost',
        revision: 12,
      );
      final AndroidDeliveryRecoveryAdapter adapter =
          AndroidDeliveryRecoveryAdapter(
            loadPlanContext: () async => _planContext(),
            channel: channel,
          );

      final DeliveryRecoveryStatus status = await adapter.auditForeground();

      expect(status.requiresExplicitRecovery, isTrue);
      expect(status.reason, DeliveryRecoveryReason.permissionLost);
    });

    test('user recovery advances the revision from a fresh audit', () async {
      final FakeRecoveryChannel channel = FakeRecoveryChannel();
      channel.responses[AndroidRhythmChannelMethod.auditRecovery] = _auditMap(
        disposition: 'needsUserRecovery',
        recoveryReason: 'registrationMissing',
        revision: 20,
      );
      channel.responses[AndroidRhythmChannelMethod.recoverExplicitly] =
          _auditMap(disposition: 'running', revision: 21);
      final AndroidDeliveryRecoveryAdapter adapter =
          AndroidDeliveryRecoveryAdapter(
            loadPlanContext: () async => _planContext(),
            channel: channel,
          );

      final DeliveryRecoveryStatus recovered = await adapter
          .recoverExplicitly();

      expect(recovered.canRestoreRunning, isTrue);
      expect(
        channel.calls.map((RecoveryChannelCall call) => call.method),
        <String>[
          AndroidRhythmChannelMethod.auditRecovery,
          AndroidRhythmChannelMethod.recoverExplicitly,
        ],
      );
      final AndroidRhythmDeliveryPlan replacement =
          AndroidRhythmDeliveryPlan.fromChannelMap(
            channel.calls.last.arguments! as Map<Object?, Object?>,
          );
      expect(replacement.revision, 21);
      expect(
        replacement.occurrences.first.occursAt,
        DateTime(2026, 8, 23, 6, 50),
      );
    });

    test('rejects a user recovery response without a reason', () async {
      final FakeRecoveryChannel channel = FakeRecoveryChannel();
      channel.responses[AndroidRhythmChannelMethod.auditRecovery] = _auditMap(
        disposition: 'needsUserRecovery',
        revision: 30,
      );
      final AndroidDeliveryRecoveryAdapter adapter =
          AndroidDeliveryRecoveryAdapter(
            loadPlanContext: () async => _planContext(),
            channel: channel,
          );

      await expectLater(
        adapter.auditForeground(),
        throwsA(isA<AndroidRhythmDeliveryFailure>()),
      );
    });
  });

  test('lifecycle entrypoint replaces stale wall-clock occurrences', () async {
    final FakeRecoveryChannel channel = FakeRecoveryChannel();
    final AndroidRhythmBackgroundRequest request =
        AndroidRhythmBackgroundRequest(
          expectedRevision: 40,
          observedAt: DateTime(2026, 8, 23, 6, 5),
          context: _planContext(),
        );
    channel.responses[AndroidRhythmChannelMethod.lifecycleReady] = request
        .toChannelMap();

    await runAndroidRhythmLifecycleReconciliation(channel: channel);

    expect(
      channel.calls.map((RecoveryChannelCall call) => call.method),
      <String>[
        AndroidRhythmChannelMethod.lifecycleReady,
        AndroidRhythmChannelMethod.completeLifecycleReconcile,
      ],
    );
    final Map<Object?, Object?> completion =
        channel.calls.last.arguments! as Map<Object?, Object?>;
    expect(completion['expectedRevision'], 40);
    final AndroidRhythmDeliveryPlan replacement =
        AndroidRhythmDeliveryPlan.fromChannelMap(
          completion['plan']! as Map<Object?, Object?>,
        );
    expect(replacement.revision, 41);
    expect(
      replacement.occurrences.every(
        (AndroidRhythmOccurrence occurrence) =>
            occurrence.occursAt.isAfter(request.observedAt),
      ),
      isTrue,
    );
  });
}

final class RecoveryChannelCall {
  const RecoveryChannelCall(this.method, this.arguments);

  final String method;
  final Object? arguments;
}

final class FakeRecoveryChannel implements AndroidRhythmChannel {
  final Map<String, Object?> responses = <String, Object?>{};
  final List<RecoveryChannelCall> calls = <RecoveryChannelCall>[];

  @override
  Future<Object?> invoke(String method, [Object? arguments]) async {
    calls.add(RecoveryChannelCall(method, arguments));
    return responses[method];
  }

  @override
  void setHandler(AndroidRhythmChannelHandler? handler) {}
}

Map<String, Object?> _auditMap({
  required String disposition,
  required int revision,
  String? recoveryReason,
}) {
  return <String, Object?>{
    'lifecycleReason': 'foreground',
    'disposition': disposition,
    'recoveryReason': recoveryReason,
    'observedAtEpochMillis': DateTime(2026, 8, 23, 6).millisecondsSinceEpoch,
    'revision': revision,
    'configuration': <String, Object?>{
      'focusMinutes': 50,
      'restMinutes': 10,
      'dailyStart': '05:00',
      'dailyEnd': '18:00',
    },
  };
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
