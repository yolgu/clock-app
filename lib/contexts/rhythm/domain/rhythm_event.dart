enum RhythmEventKind {
  focusEnds,
  restEnds;

  RhythmEventKind get next => switch (this) {
    RhythmEventKind.focusEnds => RhythmEventKind.restEnds,
    RhythmEventKind.restEnds => RhythmEventKind.focusEnds,
  };
}

final class RhythmEvent {
  factory RhythmEvent({
    required RhythmEventKind kind,
    required DateTime occursAt,
    required DateTime windowStartsAt,
  }) {
    if (occursAt.isUtc || windowStartsAt.isUtc) {
      throw ArgumentError('Rhythm Event times must be local DateTime values.');
    }
    if (!occursAt.isAfter(windowStartsAt)) {
      throw ArgumentError.value(
        occursAt,
        'occursAt',
        'must be after the Daily Rhythm window start',
      );
    }
    return RhythmEvent._(
      kind: kind,
      occursAt: occursAt,
      windowStartsAt: windowStartsAt,
    );
  }

  const RhythmEvent._({
    required this.kind,
    required this.occursAt,
    required this.windowStartsAt,
  });

  final RhythmEventKind kind;
  final DateTime occursAt;
  final DateTime windowStartsAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RhythmEvent &&
            kind == other.kind &&
            occursAt == other.occursAt &&
            windowStartsAt == other.windowStartsAt;
  }

  @override
  int get hashCode => Object.hash(kind, occursAt, windowStartsAt);
}
