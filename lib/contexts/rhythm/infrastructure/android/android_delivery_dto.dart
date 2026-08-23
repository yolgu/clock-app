import '../../../../shared/i18n/public.dart';
import '../../domain/clock_time.dart';
import '../../domain/daily_rhythm.dart';
import '../../domain/duration_minutes.dart';
import '../../domain/rhythm_configuration.dart';
import '../../domain/rhythm_event.dart';
import '../../domain/rhythm_schedule.dart';

const int androidRhythmDeliverySchemaVersion = 1;
const int androidRhythmMinimumPrecomputedOccurrences = 3;
const int _maximumPlatformInteger = 0x7FFFFFFFFFFFFFFF;

enum AndroidRhythmDeliveryFailureCode {
  invalidPayload('invalidPayload'),
  notificationPermissionDenied('notificationPermissionDenied'),
  exactAlarmPermissionDenied('exactAlarmPermissionDenied'),
  notificationAndExactAlarmPermissionDenied(
    'notificationAndExactAlarmPermissionDenied',
  ),
  staleRevision('staleRevision'),
  stateUnavailable('stateUnavailable'),
  schedulingFailed('schedulingFailed'),
  channelUnavailable('channelUnavailable'),
  backgroundRefillFailed('backgroundRefillFailed'),
  unknown('unknown');

  const AndroidRhythmDeliveryFailureCode(this.wireName);

  final String wireName;

  static AndroidRhythmDeliveryFailureCode parse(String value) {
    for (final AndroidRhythmDeliveryFailureCode code in values) {
      if (code.wireName == value) {
        return code;
      }
    }
    return AndroidRhythmDeliveryFailureCode.unknown;
  }
}

final class AndroidRhythmDeliveryFailure implements Exception {
  const AndroidRhythmDeliveryFailure({
    required this.code,
    required this.message,
    this.details,
  });

  final AndroidRhythmDeliveryFailureCode code;
  final String message;
  final Object? details;

  @override
  String toString() =>
      'AndroidRhythmDeliveryFailure(${code.wireName}): '
      '$message';
}

final class AndroidRhythmNotificationPresentation {
  const AndroidRhythmNotificationPresentation({
    required this.focusEnded,
    required this.restEnded,
    required this.muted,
  });

  final LocalizedNotificationPayload focusEnded;
  final LocalizedNotificationPayload restEnded;
  final bool muted;

  LocalizedNotificationPayload payloadFor(RhythmEventKind kind) {
    return switch (kind) {
      RhythmEventKind.focusEnds => focusEnded,
      RhythmEventKind.restEnds => restEnded,
    };
  }

  Map<String, Object?> toChannelMap() {
    _validateNotificationPayload(focusEnded, 'focusEnded');
    _validateNotificationPayload(restEnded, 'restEnded');
    return <String, Object?>{
      'focusEnded': _payloadToMap(focusEnded),
      'restEnded': _payloadToMap(restEnded),
      'muted': muted,
    };
  }

  factory AndroidRhythmNotificationPresentation.fromChannelMap(
    Map<Object?, Object?> map,
  ) {
    final LocalizedNotificationPayload focusEnded = _payloadFromMap(
      _readMap(map['focusEnded'], 'presentation.focusEnded'),
      'presentation.focusEnded',
    );
    final LocalizedNotificationPayload restEnded = _payloadFromMap(
      _readMap(map['restEnded'], 'presentation.restEnded'),
      'presentation.restEnded',
    );
    return AndroidRhythmNotificationPresentation(
      focusEnded: focusEnded,
      restEnded: restEnded,
      muted: _readBool(map['muted'], 'presentation.muted'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AndroidRhythmNotificationPresentation &&
            focusEnded == other.focusEnded &&
            restEnded == other.restEnded &&
            muted == other.muted;
  }

  @override
  int get hashCode => Object.hash(focusEnded, restEnded, muted);
}

final class AndroidRhythmPlanContext {
  AndroidRhythmPlanContext({
    required this.configuration,
    required this.presentation,
  }) {
    presentation.toChannelMap();
  }

  final RhythmConfiguration configuration;
  final AndroidRhythmNotificationPresentation presentation;

  Map<String, Object?> toChannelMap() {
    return <String, Object?>{
      'configuration': _configurationToMap(configuration),
      'presentation': presentation.toChannelMap(),
    };
  }

  factory AndroidRhythmPlanContext.fromChannelMap(Map<Object?, Object?> map) {
    return AndroidRhythmPlanContext(
      configuration: decodeAndroidRhythmConfiguration(
        _readMap(map['configuration'], 'configuration'),
      ),
      presentation: AndroidRhythmNotificationPresentation.fromChannelMap(
        _readMap(map['presentation'], 'presentation'),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AndroidRhythmPlanContext &&
            configuration == other.configuration &&
            presentation == other.presentation;
  }

  @override
  int get hashCode => Object.hash(configuration, presentation);
}

final class AndroidRhythmOccurrence {
  factory AndroidRhythmOccurrence({
    required String occurrenceId,
    required RhythmEventKind kind,
    required DateTime occursAt,
    required DateTime windowStartsAt,
    required String title,
    required String body,
    required bool muted,
  }) {
    final String validatedOccurrenceId = _requireNonEmpty(
      occurrenceId,
      'occurrenceId',
    );
    if (occursAt.isUtc || windowStartsAt.isUtc) {
      throw ArgumentError(
        'Android Rhythm occurrence times must be local DateTime values.',
      );
    }
    if (occursAt.microsecond != 0 || windowStartsAt.microsecond != 0) {
      throw ArgumentError(
        'Android Rhythm occurrence times must have millisecond precision.',
      );
    }
    if (!occursAt.isAfter(windowStartsAt)) {
      throw ArgumentError.value(
        occursAt,
        'occursAt',
        'must be after windowStartsAt',
      );
    }
    return AndroidRhythmOccurrence._(
      occurrenceId: validatedOccurrenceId,
      kind: kind,
      occursAt: occursAt,
      windowStartsAt: windowStartsAt,
      title: _requireNonEmpty(title, 'title'),
      body: _requireNonEmpty(body, 'body'),
      muted: muted,
    );
  }

  const AndroidRhythmOccurrence._({
    required this.occurrenceId,
    required this.kind,
    required this.occursAt,
    required this.windowStartsAt,
    required this.title,
    required this.body,
    required this.muted,
  });

  final String occurrenceId;
  final RhythmEventKind kind;
  final DateTime occursAt;
  final DateTime windowStartsAt;
  final String title;
  final String body;
  final bool muted;

  factory AndroidRhythmOccurrence.fromRhythmEvent({
    required RhythmEvent event,
    required AndroidRhythmNotificationPresentation presentation,
  }) {
    final LocalizedNotificationPayload payload = presentation.payloadFor(
      event.kind,
    );
    return AndroidRhythmOccurrence(
      occurrenceId: _occurrenceId(event),
      kind: event.kind,
      occursAt: event.occursAt,
      windowStartsAt: event.windowStartsAt,
      title: payload.title,
      body: payload.body,
      muted: presentation.muted,
    );
  }

  AndroidRhythmOccurrence replacePresentation(
    AndroidRhythmNotificationPresentation presentation,
  ) {
    final LocalizedNotificationPayload payload = presentation.payloadFor(kind);
    return AndroidRhythmOccurrence(
      occurrenceId: occurrenceId,
      kind: kind,
      occursAt: occursAt,
      windowStartsAt: windowStartsAt,
      title: payload.title,
      body: payload.body,
      muted: presentation.muted,
    );
  }

  Map<String, Object?> toChannelMap() {
    return <String, Object?>{
      'occurrenceId': occurrenceId,
      'kind': kind.name,
      'occursAtEpochMillis': occursAt.millisecondsSinceEpoch,
      'windowStartsAtEpochMillis': windowStartsAt.millisecondsSinceEpoch,
      'title': title,
      'body': body,
      'muted': muted,
    };
  }

  factory AndroidRhythmOccurrence.fromChannelMap(Map<Object?, Object?> map) {
    final int occursAtEpochMillis = _readPlatformInteger(
      map['occursAtEpochMillis'],
      'occursAtEpochMillis',
    );
    final int windowStartsAtEpochMillis = _readPlatformInteger(
      map['windowStartsAtEpochMillis'],
      'windowStartsAtEpochMillis',
    );
    return AndroidRhythmOccurrence(
      occurrenceId: _readString(map['occurrenceId'], 'occurrenceId'),
      kind: _eventKindFromWireName(_readString(map['kind'], 'kind')),
      occursAt: DateTime.fromMillisecondsSinceEpoch(occursAtEpochMillis),
      windowStartsAt: DateTime.fromMillisecondsSinceEpoch(
        windowStartsAtEpochMillis,
      ),
      title: _readString(map['title'], 'title'),
      body: _readString(map['body'], 'body'),
      muted: _readBool(map['muted'], 'muted'),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AndroidRhythmOccurrence &&
            occurrenceId == other.occurrenceId &&
            kind == other.kind &&
            occursAt == other.occursAt &&
            windowStartsAt == other.windowStartsAt &&
            title == other.title &&
            body == other.body &&
            muted == other.muted;
  }

  @override
  int get hashCode {
    return Object.hash(
      occurrenceId,
      kind,
      occursAt,
      windowStartsAt,
      title,
      body,
      muted,
    );
  }
}

final class AndroidRhythmDeliveryPlan {
  factory AndroidRhythmDeliveryPlan({
    required int revision,
    required String registrationId,
    required AndroidRhythmPlanContext context,
    required List<AndroidRhythmOccurrence> occurrences,
  }) {
    _requirePositivePlatformInteger(revision, 'revision');
    final String validatedRegistrationId = _requireNonEmpty(
      registrationId,
      'registrationId',
    );
    if (occurrences.isEmpty) {
      throw ArgumentError.value(
        occurrences,
        'occurrences',
        'must contain at least one occurrence',
      );
    }
    _validateChronologicalOccurrences(occurrences);
    return AndroidRhythmDeliveryPlan._(
      revision: revision,
      registrationId: validatedRegistrationId,
      context: context,
      occurrences: List<AndroidRhythmOccurrence>.unmodifiable(occurrences),
    );
  }

  const AndroidRhythmDeliveryPlan._({
    required this.revision,
    required this.registrationId,
    required this.context,
    required this.occurrences,
  });

  final int revision;
  final String registrationId;
  final AndroidRhythmPlanContext context;
  final List<AndroidRhythmOccurrence> occurrences;

  bool get hasMinimumPrecomputedQueue =>
      occurrences.length >= androidRhythmMinimumPrecomputedOccurrences;

  AndroidRhythmDeliveryPlan replacePresentation({
    required AndroidRhythmNotificationPresentation presentation,
    required int revision,
  }) {
    if (revision <= this.revision) {
      throw ArgumentError.value(
        revision,
        'revision',
        'must advance the existing revision',
      );
    }
    return AndroidRhythmDeliveryPlan(
      revision: revision,
      registrationId: _registrationId(revision),
      context: AndroidRhythmPlanContext(
        configuration: context.configuration,
        presentation: presentation,
      ),
      occurrences: occurrences
          .map(
            (AndroidRhythmOccurrence occurrence) =>
                occurrence.replacePresentation(presentation),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toChannelMap() {
    return <String, Object?>{
      'schemaVersion': androidRhythmDeliverySchemaVersion,
      'revision': revision,
      'registrationId': registrationId,
      ...context.toChannelMap(),
      'occurrences': occurrences
          .map(
            (AndroidRhythmOccurrence occurrence) => occurrence.toChannelMap(),
          )
          .toList(growable: false),
    };
  }

  factory AndroidRhythmDeliveryPlan.fromChannelMap(Map<Object?, Object?> map) {
    final int schemaVersion = _readPlatformInteger(
      map['schemaVersion'],
      'schemaVersion',
    );
    if (schemaVersion != androidRhythmDeliverySchemaVersion) {
      throw FormatException(
        'Unsupported Android Rhythm delivery schema version: $schemaVersion',
      );
    }
    final List<Object?> occurrenceValues = _readList(
      map['occurrences'],
      'occurrences',
    );
    try {
      return AndroidRhythmDeliveryPlan(
        revision: _readPositivePlatformInteger(map['revision'], 'revision'),
        registrationId: _readString(map['registrationId'], 'registrationId'),
        context: AndroidRhythmPlanContext.fromChannelMap(map),
        occurrences: occurrenceValues
            .map(
              (Object? value) => AndroidRhythmOccurrence.fromChannelMap(
                _readMap(value, 'occurrences[]'),
              ),
            )
            .toList(growable: false),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid Android Rhythm delivery plan: $error');
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AndroidRhythmDeliveryPlan &&
            revision == other.revision &&
            registrationId == other.registrationId &&
            context == other.context &&
            _listsEqual(occurrences, other.occurrences);
  }

  @override
  int get hashCode => Object.hash(
    revision,
    registrationId,
    context,
    Object.hashAll(occurrences),
  );
}

final class AndroidRhythmBackgroundRequest {
  AndroidRhythmBackgroundRequest({
    required this.expectedRevision,
    required this.observedAt,
    required this.context,
  }) {
    _requirePositivePlatformInteger(expectedRevision, 'expectedRevision');
    if (observedAt.isUtc) {
      throw ArgumentError.value(
        observedAt,
        'observedAt',
        'must be a local DateTime',
      );
    }
  }

  final int expectedRevision;
  final DateTime observedAt;
  final AndroidRhythmPlanContext context;

  factory AndroidRhythmBackgroundRequest.fromChannelMap(
    Map<Object?, Object?> map,
  ) {
    try {
      return AndroidRhythmBackgroundRequest(
        expectedRevision: _readPositivePlatformInteger(
          map['expectedRevision'],
          'expectedRevision',
        ),
        observedAt: DateTime.fromMillisecondsSinceEpoch(
          _readPlatformInteger(
            map['observedAtEpochMillis'],
            'observedAtEpochMillis',
          ),
        ),
        context: AndroidRhythmPlanContext.fromChannelMap(map),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid Android Rhythm refill request: $error');
    }
  }

  Map<String, Object?> toChannelMap() {
    return <String, Object?>{
      'expectedRevision': expectedRevision,
      'observedAtEpochMillis': observedAt.millisecondsSinceEpoch,
      ...context.toChannelMap(),
    };
  }
}

final class AndroidRhythmDeliveryStatus {
  const AndroidRhythmDeliveryStatus({
    required this.revision,
    required this.isActive,
    required this.needsRecovery,
    required this.activePlan,
  });

  final int revision;
  final bool isActive;
  final bool needsRecovery;
  final AndroidRhythmDeliveryPlan? activePlan;

  factory AndroidRhythmDeliveryStatus.fromChannelMap(
    Map<Object?, Object?> map,
  ) {
    final int revision = _readPlatformInteger(map['revision'], 'revision');
    if (revision < 0) {
      throw const FormatException('revision must not be negative.');
    }
    final Object? planValue = map['activePlan'];
    final bool isActive = _readBool(map['isActive'], 'isActive');
    final AndroidRhythmDeliveryPlan? activePlan = planValue == null
        ? null
        : AndroidRhythmDeliveryPlan.fromChannelMap(
            _readMap(planValue, 'activePlan'),
          );
    if ((!isActive && activePlan != null) ||
        (activePlan != null && activePlan.revision != revision)) {
      throw const FormatException(
        'Android Rhythm delivery status is internally inconsistent.',
      );
    }
    return AndroidRhythmDeliveryStatus(
      revision: revision,
      isActive: isActive,
      needsRecovery: _readBool(map['needsRecovery'], 'needsRecovery'),
      activePlan: activePlan,
    );
  }
}

final class AndroidRhythmDeliveryPlanFactory {
  const AndroidRhythmDeliveryPlanFactory();

  AndroidRhythmDeliveryPlan forScheduledEvent({
    required RhythmEvent currentEvent,
    required AndroidRhythmPlanContext context,
    required int revision,
  }) {
    final RhythmSchedule schedule = RhythmSchedule(
      configuration: context.configuration,
    );
    final RhythmEvent expectedCurrent = schedule.nextEventAfter(
      currentEvent.occursAt.subtract(const Duration(milliseconds: 1)),
    );
    if (expectedCurrent != currentEvent) {
      throw ArgumentError.value(
        currentEvent,
        'currentEvent',
        'must belong to the supplied Rhythm configuration',
      );
    }
    final List<RhythmEvent> events = <RhythmEvent>[currentEvent];
    RhythmEvent previous = currentEvent;
    while (events.length < androidRhythmMinimumPrecomputedOccurrences) {
      previous = schedule.nextEventAfter(previous.occursAt);
      events.add(previous);
    }
    return _fromEvents(events: events, context: context, revision: revision);
  }

  AndroidRhythmDeliveryPlan forBackgroundRefill(
    AndroidRhythmBackgroundRequest request,
  ) {
    return forReconciliation(
      observedAt: request.observedAt,
      context: request.context,
      currentRevision: request.expectedRevision,
    );
  }

  AndroidRhythmDeliveryPlan forReconciliation({
    required DateTime observedAt,
    required AndroidRhythmPlanContext context,
    required int currentRevision,
  }) {
    if (currentRevision < 0 || currentRevision >= _maximumPlatformInteger) {
      throw ArgumentError.value(
        currentRevision,
        'currentRevision',
        'must be a non-negative revision that can advance',
      );
    }
    if (observedAt.isUtc) {
      throw ArgumentError.value(
        observedAt,
        'observedAt',
        'must be a local DateTime',
      );
    }
    final RhythmSchedule schedule = RhythmSchedule(
      configuration: context.configuration,
    );
    final List<RhythmEvent> events = <RhythmEvent>[];
    DateTime cursor = observedAt;
    while (events.length < androidRhythmMinimumPrecomputedOccurrences) {
      final RhythmEvent event = schedule.nextEventAfter(cursor);
      events.add(event);
      cursor = event.occursAt;
    }
    return _fromEvents(
      events: events,
      context: context,
      revision: currentRevision + 1,
    );
  }

  AndroidRhythmDeliveryPlan _fromEvents({
    required List<RhythmEvent> events,
    required AndroidRhythmPlanContext context,
    required int revision,
  }) {
    return AndroidRhythmDeliveryPlan(
      revision: revision,
      registrationId: _registrationId(revision),
      context: context,
      occurrences: events
          .map(
            (RhythmEvent event) => AndroidRhythmOccurrence.fromRhythmEvent(
              event: event,
              presentation: context.presentation,
            ),
          )
          .toList(growable: false),
    );
  }
}

Map<String, Object?> _configurationToMap(RhythmConfiguration configuration) {
  return <String, Object?>{
    'focusMinutes': configuration.focusDuration.minutes,
    'restMinutes': configuration.restDuration.minutes,
    'dailyStart': configuration.dailyRhythm.start.text,
    'dailyEnd': configuration.dailyRhythm.end.text,
  };
}

RhythmConfiguration decodeAndroidRhythmConfiguration(
  Map<Object?, Object?> map,
) {
  try {
    return RhythmConfiguration(
      dailyRhythm: DailyRhythm(
        start: ClockTime.parse(_readString(map['dailyStart'], 'dailyStart')),
        end: ClockTime.parse(_readString(map['dailyEnd'], 'dailyEnd')),
      ),
      focusDuration: DurationMinutes.focus(
        _readPlatformInteger(map['focusMinutes'], 'focusMinutes'),
      ),
      restDuration: DurationMinutes.rest(
        _readPlatformInteger(map['restMinutes'], 'restMinutes'),
      ),
    );
  } on ArgumentError catch (error) {
    throw FormatException('Invalid Rhythm configuration: $error');
  }
}

Map<String, Object?> _payloadToMap(LocalizedNotificationPayload payload) {
  _validateNotificationPayload(payload, 'payload');
  return <String, Object?>{'title': payload.title, 'body': payload.body};
}

LocalizedNotificationPayload _payloadFromMap(
  Map<Object?, Object?> map,
  String field,
) {
  final LocalizedNotificationPayload payload = LocalizedNotificationPayload(
    title: _readString(map['title'], '$field.title'),
    body: _readString(map['body'], '$field.body'),
  );
  _validateNotificationPayload(payload, field);
  return payload;
}

void _validateNotificationPayload(
  LocalizedNotificationPayload payload,
  String field,
) {
  _requireNonEmpty(payload.title, '$field.title');
  _requireNonEmpty(payload.body, '$field.body');
}

String _occurrenceId(RhythmEvent event) {
  return '${event.occursAt.millisecondsSinceEpoch}:${event.kind.name}';
}

String _registrationId(int revision) => 'rhythm:$revision';

RhythmEventKind _eventKindFromWireName(String value) {
  return switch (value) {
    'focusEnds' => RhythmEventKind.focusEnds,
    'restEnds' => RhythmEventKind.restEnds,
    _ => throw FormatException('Unsupported Rhythm Event kind: $value'),
  };
}

void _validateChronologicalOccurrences(
  List<AndroidRhythmOccurrence> occurrences,
) {
  final Set<String> occurrenceIds = <String>{};
  AndroidRhythmOccurrence? previous;
  for (final AndroidRhythmOccurrence occurrence in occurrences) {
    if (!occurrenceIds.add(occurrence.occurrenceId)) {
      throw ArgumentError.value(
        occurrence.occurrenceId,
        'occurrences',
        'must have unique occurrence IDs',
      );
    }
    if (previous != null && !occurrence.occursAt.isAfter(previous.occursAt)) {
      throw ArgumentError.value(
        occurrences,
        'occurrences',
        'must be strictly chronological',
      );
    }
    previous = occurrence;
  }
}

Map<Object?, Object?> _readMap(Object? value, String field) {
  if (value is Map<Object?, Object?>) {
    return value;
  }
  throw FormatException('$field must be a map.');
}

List<Object?> _readList(Object? value, String field) {
  if (value is List<Object?>) {
    return value;
  }
  throw FormatException('$field must be a list.');
}

String _readString(Object? value, String field) {
  if (value is String) {
    return _requireNonEmpty(value, field);
  }
  throw FormatException('$field must be a string.');
}

bool _readBool(Object? value, String field) {
  if (value is bool) {
    return value;
  }
  throw FormatException('$field must be a boolean.');
}

int _readPlatformInteger(Object? value, String field) {
  if (value is int &&
      value >= -_maximumPlatformInteger - 1 &&
      value <= _maximumPlatformInteger) {
    return value;
  }
  throw FormatException('$field must be a signed 64-bit integer.');
}

int _readPositivePlatformInteger(Object? value, String field) {
  final int parsed = _readPlatformInteger(value, field);
  if (parsed <= 0) {
    throw FormatException('$field must be positive.');
  }
  return parsed;
}

void _requirePositivePlatformInteger(int value, String field) {
  if (value <= 0 || value > _maximumPlatformInteger) {
    throw ArgumentError.value(value, field, 'must be a positive 64-bit value');
  }
}

String _requireNonEmpty(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return value;
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
