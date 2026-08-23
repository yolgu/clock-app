enum NotificationSoundMode {
  bundledDefault('default'),
  custom('custom'),
  muted('muted');

  const NotificationSoundMode(this.id);

  final String id;

  static NotificationSoundMode parse(String id) {
    for (final NotificationSoundMode mode in values) {
      if (mode.id == id) {
        return mode;
      }
    }
    throw FormatException('Unsupported notification sound mode: $id');
  }
}

enum UnmuteSoundBehavior { restorePreviousSelection, bundledDefault }

final class AudibleNotificationSoundSelection {
  factory AudibleNotificationSoundSelection.bundledDefault() {
    return const AudibleNotificationSoundSelection._(
      mode: NotificationSoundMode.bundledDefault,
      customFileName: null,
      privateSource: null,
    );
  }

  factory AudibleNotificationSoundSelection.custom({
    required String fileName,
    required String privateSource,
  }) {
    return AudibleNotificationSoundSelection._(
      mode: NotificationSoundMode.custom,
      customFileName: NotificationSoundPreference.validateCustomFileName(
        fileName,
      ),
      privateSource: NotificationSoundPreference.validatePrivateSource(
        privateSource,
      ),
    );
  }

  const AudibleNotificationSoundSelection._({
    required this.mode,
    required this.customFileName,
    required this.privateSource,
  });

  final NotificationSoundMode mode;
  final String? customFileName;
  final String? privateSource;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AudibleNotificationSoundSelection &&
            mode == other.mode &&
            customFileName == other.customFileName &&
            privateSource == other.privateSource;
  }

  @override
  int get hashCode => Object.hash(mode, customFileName, privateSource);
}

final class NotificationSoundSnapshot {
  const NotificationSoundSnapshot({
    required this.mode,
    required this.customFileName,
    required this.privateSource,
    required this.volume,
    required this.mutedFrom,
  });

  final NotificationSoundMode mode;
  final String? customFileName;
  final String? privateSource;
  final double volume;
  final AudibleNotificationSoundSelection? mutedFrom;

  Map<String, Object?> toJsonLikeMap() {
    return <String, Object?>{
      'mode': mode.id,
      'customFileName': customFileName,
      'customSource': privateSource,
      'volume': volume,
      'mutedFrom': switch (mutedFrom) {
        null => null,
        final AudibleNotificationSoundSelection selection => <String, Object?>{
          'mode': selection.mode.id,
          'customFileName': selection.customFileName,
          'customSource': selection.privateSource,
        },
      },
    };
  }
}

final class NotificationSoundPreference {
  factory NotificationSoundPreference.bundledDefault({double volume = 1}) {
    return NotificationSoundPreference._(
      mode: NotificationSoundMode.bundledDefault,
      customFileName: null,
      privateSource: null,
      volume: _validateVolume(volume),
      mutedFrom: null,
    );
  }

  factory NotificationSoundPreference.custom({
    required String fileName,
    required String privateSource,
    double volume = 1,
  }) {
    return NotificationSoundPreference._(
      mode: NotificationSoundMode.custom,
      customFileName: validateCustomFileName(fileName),
      privateSource: validatePrivateSource(privateSource),
      volume: _validateVolume(volume),
      mutedFrom: null,
    );
  }

  factory NotificationSoundPreference.restore(
    NotificationSoundSnapshot snapshot,
  ) {
    final double volume = _validateVolume(snapshot.volume);
    return switch (snapshot.mode) {
      NotificationSoundMode.bundledDefault =>
        NotificationSoundPreference.bundledDefault(volume: volume),
      NotificationSoundMode.custom => NotificationSoundPreference.custom(
        fileName: snapshot.customFileName ?? '',
        privateSource: snapshot.privateSource ?? '',
        volume: volume,
      ),
      NotificationSoundMode.muted => NotificationSoundPreference._(
        mode: NotificationSoundMode.muted,
        customFileName: null,
        privateSource: null,
        volume: volume,
        mutedFrom: _restoreAudibleSelection(snapshot.mutedFrom),
      ),
    };
  }

  const NotificationSoundPreference._({
    required this.mode,
    required this.customFileName,
    required this.privateSource,
    required this.volume,
    required this.mutedFrom,
  });

  final NotificationSoundMode mode;
  final String? customFileName;
  final String? privateSource;
  final double volume;
  final AudibleNotificationSoundSelection? mutedFrom;

  bool get isNotificationVisible => true;

  bool get isAudible => mode != NotificationSoundMode.muted;

  NotificationSoundPreference useBundledDefault() {
    return NotificationSoundPreference.bundledDefault(volume: volume);
  }

  NotificationSoundPreference changeVolume(double nextVolume) {
    return NotificationSoundPreference._(
      mode: mode,
      customFileName: customFileName,
      privateSource: privateSource,
      volume: _validateVolume(nextVolume),
      mutedFrom: mutedFrom,
    );
  }

  NotificationSoundPreference toggleMute(UnmuteSoundBehavior behavior) {
    if (mode != NotificationSoundMode.muted) {
      return NotificationSoundPreference._(
        mode: NotificationSoundMode.muted,
        customFileName: null,
        privateSource: null,
        volume: volume,
        mutedFrom: _audibleSelection(),
      );
    }
    if (behavior == UnmuteSoundBehavior.bundledDefault) {
      return NotificationSoundPreference.bundledDefault(volume: volume);
    }
    return _restorePreviousSelection();
  }

  NotificationSoundSnapshot snapshot() {
    return NotificationSoundSnapshot(
      mode: mode,
      customFileName: customFileName,
      privateSource: privateSource,
      volume: volume,
      mutedFrom: mutedFrom,
    );
  }

  AudibleNotificationSoundSelection _audibleSelection() {
    if (mode == NotificationSoundMode.custom) {
      return AudibleNotificationSoundSelection.custom(
        fileName: customFileName!,
        privateSource: privateSource!,
      );
    }
    return AudibleNotificationSoundSelection.bundledDefault();
  }

  NotificationSoundPreference _restorePreviousSelection() {
    final AudibleNotificationSoundSelection? previous = mutedFrom;
    if (previous == null ||
        previous.mode == NotificationSoundMode.bundledDefault) {
      return NotificationSoundPreference.bundledDefault(volume: volume);
    }
    return NotificationSoundPreference.custom(
      fileName: previous.customFileName!,
      privateSource: previous.privateSource!,
      volume: volume,
    );
  }

  static AudibleNotificationSoundSelection? _restoreAudibleSelection(
    AudibleNotificationSoundSelection? selection,
  ) {
    if (selection == null) {
      return null;
    }
    return switch (selection.mode) {
      NotificationSoundMode.bundledDefault =>
        AudibleNotificationSoundSelection.bundledDefault(),
      NotificationSoundMode.custom => AudibleNotificationSoundSelection.custom(
        fileName: selection.customFileName ?? '',
        privateSource: selection.privateSource ?? '',
      ),
      NotificationSoundMode.muted => throw const FormatException(
        'A muted sound cannot be the previous audible selection.',
      ),
    };
  }

  static String validateCustomFileName(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty || !normalized.toLowerCase().endsWith('.mp3')) {
      throw ArgumentError.value(value, 'fileName', 'must be an MP3 file name');
    }
    return normalized;
  }

  static String validatePrivateSource(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'privateSource',
        'must identify adopted private media',
      );
    }
    return normalized;
  }

  static double _validateVolume(double value) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw ArgumentError.value(value, 'volume', 'must be between 0 and 1');
    }
    return value;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationSoundPreference &&
            mode == other.mode &&
            customFileName == other.customFileName &&
            privateSource == other.privateSource &&
            volume == other.volume &&
            mutedFrom == other.mutedFrom;
  }

  @override
  int get hashCode {
    return Object.hash(mode, customFileName, privateSource, volume, mutedFrom);
  }
}
