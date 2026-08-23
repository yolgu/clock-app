import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_configuration.dart';
import 'package:clock_rhythm/contexts/rhythm/domain/rhythm_event.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/android/android_delivery_dto.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidRhythmDeliveryPlanFactory', () {
    final RhythmConfiguration configuration = RhythmConfiguration.defaults();
    const AndroidRhythmNotificationPresentation presentation =
        AndroidRhythmNotificationPresentation(
          focusEnded: LocalizedNotificationPayload(
            title: 'Focus ended',
            body: 'Take a rest.',
          ),
          restEnded: LocalizedNotificationPayload(
            title: 'Rest ended',
            body: 'Return to focus.',
          ),
          muted: false,
        );
    final AndroidRhythmPlanContext context = AndroidRhythmPlanContext(
      configuration: configuration,
      presentation: presentation,
    );
    const AndroidRhythmDeliveryPlanFactory factory =
        AndroidRhythmDeliveryPlanFactory();

    test('encodes the current occurrence and at least two future ones', () {
      final RhythmEvent current = RhythmEvent(
        kind: RhythmEventKind.focusEnds,
        occursAt: DateTime(2026, 8, 23, 5, 50),
        windowStartsAt: DateTime(2026, 8, 23, 5),
      );

      final AndroidRhythmDeliveryPlan plan = factory.forScheduledEvent(
        currentEvent: current,
        context: context,
        revision: 7,
      );

      expect(plan.occurrences, hasLength(3));
      expect(
        plan.occurrences.map(
          (AndroidRhythmOccurrence occurrence) => occurrence.occursAt,
        ),
        <DateTime>[
          DateTime(2026, 8, 23, 5, 50),
          DateTime(2026, 8, 23, 6),
          DateTime(2026, 8, 23, 6, 50),
        ],
      );
      expect(
        AndroidRhythmDeliveryPlan.fromChannelMap(plan.toChannelMap()),
        plan,
      );
    });

    test('refill skips missed events and advances the revision', () {
      final AndroidRhythmBackgroundRequest request =
          AndroidRhythmBackgroundRequest(
            expectedRevision: 9,
            observedAt: DateTime(2026, 8, 23, 6, 5),
            context: context,
          );

      final AndroidRhythmDeliveryPlan plan = factory.forBackgroundRefill(
        request,
      );

      expect(plan.revision, 10);
      expect(plan.occurrences, hasLength(3));
      expect(plan.occurrences.first.occursAt, DateTime(2026, 8, 23, 6, 50));
      expect(
        plan.occurrences.every(
          (AndroidRhythmOccurrence occurrence) =>
              occurrence.occursAt.isAfter(request.observedAt),
        ),
        isTrue,
      );
    });

    test(
      'payload replacement preserves occurrence identity and timestamps',
      () {
        final RhythmEvent current = RhythmEvent(
          kind: RhythmEventKind.focusEnds,
          occursAt: DateTime(2026, 8, 23, 5, 50),
          windowStartsAt: DateTime(2026, 8, 23, 5),
        );
        final AndroidRhythmDeliveryPlan original = factory.forScheduledEvent(
          currentEvent: current,
          context: context,
          revision: 11,
        );
        const AndroidRhythmNotificationPresentation replacement =
            AndroidRhythmNotificationPresentation(
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

        final AndroidRhythmDeliveryPlan replaced = original.replacePresentation(
          presentation: replacement,
          revision: 12,
        );

        expect(replaced.revision, 12);
        expect(replaced.registrationId, isNot(original.registrationId));
        expect(
          replaced.occurrences.map(
            (AndroidRhythmOccurrence occurrence) => occurrence.occurrenceId,
          ),
          original.occurrences.map(
            (AndroidRhythmOccurrence occurrence) => occurrence.occurrenceId,
          ),
        );
        expect(
          replaced.occurrences.map(
            (AndroidRhythmOccurrence occurrence) => occurrence.occursAt,
          ),
          original.occurrences.map(
            (AndroidRhythmOccurrence occurrence) => occurrence.occursAt,
          ),
        );
        expect(replaced.occurrences.first.muted, isTrue);
        expect(replaced.occurrences.first.title, '집중 종료');
      },
    );

    test('rejects a current event from a different schedule', () {
      final RhythmEvent mismatched = RhythmEvent(
        kind: RhythmEventKind.focusEnds,
        occursAt: DateTime(2026, 8, 23, 5, 40),
        windowStartsAt: DateTime(2026, 8, 23, 5),
      );

      expect(
        () => factory.forScheduledEvent(
          currentEvent: mismatched,
          context: context,
          revision: 14,
        ),
        throwsArgumentError,
      );
    });
  });

  group('AndroidRhythmDeliveryPlan codec', () {
    test('rejects a queue that is not strictly chronological', () {
      final Map<String, Object?> malformed = <String, Object?>{
        'schemaVersion': 1,
        'revision': 1,
        'registrationId': 'rhythm:1',
        'configuration': <String, Object?>{
          'focusMinutes': 50,
          'restMinutes': 10,
          'dailyStart': '05:00',
          'dailyEnd': '18:00',
        },
        'presentation': <String, Object?>{
          'focusEnded': <String, Object?>{'title': 'F', 'body': 'B'},
          'restEnded': <String, Object?>{'title': 'R', 'body': 'B'},
          'muted': false,
        },
        'occurrences': <Object?>[
          _occurrenceMap(epochMillis: 2000),
          _occurrenceMap(epochMillis: 1000),
        ],
      };

      expect(
        () => AndroidRhythmDeliveryPlan.fromChannelMap(malformed),
        throwsFormatException,
      );
    });

    test('represents active recovery even when no queue can be exposed', () {
      final AndroidRhythmDeliveryStatus status =
          AndroidRhythmDeliveryStatus.fromChannelMap(<String, Object?>{
            'revision': 22,
            'isActive': true,
            'needsRecovery': true,
            'activePlan': null,
          });

      expect(status.isActive, isTrue);
      expect(status.needsRecovery, isTrue);
      expect(status.activePlan, isNull);
    });
  });
}

Map<String, Object?> _occurrenceMap({required int epochMillis}) {
  return <String, Object?>{
    'occurrenceId': '$epochMillis:focusEnds',
    'kind': 'focusEnds',
    'occursAtEpochMillis': epochMillis,
    'windowStartsAtEpochMillis': 0,
    'title': 'Focus ended',
    'body': 'Take a rest.',
    'muted': false,
  };
}
