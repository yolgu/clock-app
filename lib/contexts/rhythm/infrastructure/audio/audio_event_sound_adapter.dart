import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../application/ports/event_sound_port.dart';

abstract interface class EventAudioPlayer {
  Stream<void> get onCompleted;

  Future<void> playAsset(String assetPath, {required double volume});

  Future<void> playFile(String filePath, {required double volume});

  Future<void> stop();

  Future<void> dispose();
}

final class AudioplayersEventAudioPlayer implements EventAudioPlayer {
  AudioplayersEventAudioPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    _player.audioCache = AudioCache(prefix: '');
  }

  final AudioPlayer _player;

  @override
  Stream<void> get onCompleted => _player.onPlayerComplete;

  @override
  Future<void> playAsset(String assetPath, {required double volume}) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(
      AssetSource(assetPath),
      volume: volume,
      position: Duration.zero,
    );
  }

  @override
  Future<void> playFile(String filePath, {required double volume}) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(
      DeviceFileSource(filePath),
      volume: volume,
      position: Duration.zero,
    );
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

final class AudioEventSoundAdapter implements EventSoundPort {
  AudioEventSoundAdapter({
    required this.bundledAssetPath,
    EventAudioPlayer? player,
  }) : _player = player ?? AudioplayersEventAudioPlayer() {
    _completionSubscription = _player.onCompleted.listen((_) {
      _isPlaying = false;
    }, onError: (Object _, StackTrace _) => _isPlaying = false);
  }

  final String bundledAssetPath;
  final EventAudioPlayer _player;
  late final StreamSubscription<void> _completionSubscription;
  Future<void> _operationTail = Future<void>.value();
  bool _isPlaying = false;
  bool _disposed = false;

  bool get isPlaying => _isPlaying;

  @override
  Future<EventSoundPlaybackResult> play(EventSoundSelection selection) {
    return _serialized<EventSoundPlaybackResult>(() async {
      await _stopPlayer();
      switch (selection.mode) {
        case EventSoundSelectionMode.muted:
          return EventSoundPlaybackResult.muted;
        case EventSoundSelectionMode.bundledDefault:
          await _playBundled(selection.volume);
          return const EventSoundPlaybackResult(
            source: EventSoundPlaybackSource.bundledDefault,
            customRepairRequired: false,
          );
        case EventSoundSelectionMode.custom:
          return _playCustomWithFallback(selection);
      }
    });
  }

  @override
  Future<void> stop() {
    return _serialized<void>(_stopPlayer);
  }

  Future<void> dispose() {
    if (_disposed) {
      return _operationTail;
    }
    _disposed = true;
    final Future<void> result = _operationTail.then<void>((_) async {
      await _stopPlayer();
      await _completionSubscription.cancel();
      await _player.dispose();
    });
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<EventSoundPlaybackResult> _playCustomWithFallback(
    EventSoundSelection selection,
  ) async {
    try {
      _isPlaying = true;
      await _player.playFile(
        selection.privateSource!,
        volume: selection.volume,
      );
      return const EventSoundPlaybackResult(
        source: EventSoundPlaybackSource.custom,
        customRepairRequired: false,
      );
    } on Object {
      await _stopPlayer(force: true);
      await _playBundled(selection.volume);
      return const EventSoundPlaybackResult(
        source: EventSoundPlaybackSource.bundledDefault,
        customRepairRequired: true,
      );
    }
  }

  Future<void> _playBundled(double volume) async {
    try {
      _isPlaying = true;
      await _player.playAsset(bundledAssetPath, volume: volume);
    } on Object catch (error) {
      try {
        await _stopPlayer(force: true);
      } on Object {
        _isPlaying = false;
      }
      throw EventSoundFailure(
        code: EventSoundFailureCode.bundledPlaybackUnavailable,
        cause: error,
      );
    }
  }

  Future<void> _stopPlayer({bool force = false}) async {
    if (!_isPlaying && !force) {
      return;
    }
    await _player.stop();
    _isPlaying = false;
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    if (_disposed) {
      return Future<T>.error(StateError('AudioEventSoundAdapter is disposed.'));
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
