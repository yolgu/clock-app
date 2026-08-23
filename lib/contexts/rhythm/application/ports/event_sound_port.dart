enum EventSoundSelectionMode { bundledDefault, custom, muted }

final class EventSoundSelection {
  factory EventSoundSelection.bundledDefault({required double volume}) {
    return EventSoundSelection._(
      mode: EventSoundSelectionMode.bundledDefault,
      privateSource: null,
      volume: _validatedVolume(volume),
    );
  }

  factory EventSoundSelection.custom({
    required String privateSource,
    required double volume,
  }) {
    final String normalizedSource = privateSource.trim();
    if (normalizedSource.isEmpty) {
      throw ArgumentError.value(
        privateSource,
        'privateSource',
        'must identify private media',
      );
    }
    return EventSoundSelection._(
      mode: EventSoundSelectionMode.custom,
      privateSource: normalizedSource,
      volume: _validatedVolume(volume),
    );
  }

  factory EventSoundSelection.muted({required double volume}) {
    return EventSoundSelection._(
      mode: EventSoundSelectionMode.muted,
      privateSource: null,
      volume: _validatedVolume(volume),
    );
  }

  const EventSoundSelection._({
    required this.mode,
    required this.privateSource,
    required this.volume,
  });

  final EventSoundSelectionMode mode;
  final String? privateSource;
  final double volume;

  static double _validatedVolume(double value) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw ArgumentError.value(value, 'volume', 'must be between 0 and 1');
    }
    return value;
  }
}

enum EventSoundPlaybackSource { none, bundledDefault, custom }

final class EventSoundPlaybackResult {
  const EventSoundPlaybackResult({
    required this.source,
    required this.customRepairRequired,
  });

  static const EventSoundPlaybackResult muted = EventSoundPlaybackResult(
    source: EventSoundPlaybackSource.none,
    customRepairRequired: false,
  );

  final EventSoundPlaybackSource source;
  final bool customRepairRequired;
}

enum EventSoundFailureCode { bundledPlaybackUnavailable }

final class EventSoundFailure implements Exception {
  const EventSoundFailure({required this.code, required this.cause});

  final EventSoundFailureCode code;
  final Object cause;

  @override
  String toString() => 'EventSoundFailure(${code.name})';
}

abstract interface class EventSoundPort {
  Future<EventSoundPlaybackResult> play(EventSoundSelection selection);

  Future<void> stop();
}
