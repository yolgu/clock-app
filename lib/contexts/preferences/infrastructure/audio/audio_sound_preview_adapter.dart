import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../application/ports/sound_preview_port.dart';
import '../../domain/notification_sound_preference.dart';

abstract interface class PreviewAudioPlayer {
  Stream<void> get onCompleted;

  Future<void> playAsset(String assetPath, {required double volume});

  Future<void> playFile(String filePath, {required double volume});

  Future<void> stop();

  Future<void> dispose();
}

final class AudioplayersPreviewAudioPlayer implements PreviewAudioPlayer {
  AudioplayersPreviewAudioPlayer({AudioPlayer? player})
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

final class AudioSoundPreviewAdapter implements SoundPreviewPort {
  AudioSoundPreviewAdapter({
    required this.bundledAssetPath,
    PreviewAudioPlayer? player,
  }) : _player = player ?? AudioplayersPreviewAudioPlayer() {
    _completionSubscription = _player.onCompleted.listen((_) {
      _finishActivePlayback();
    }, onError: _failActivePlayback);
  }

  final String bundledAssetPath;
  final PreviewAudioPlayer _player;
  late final StreamSubscription<void> _completionSubscription;
  Future<void> _operationTail = Future<void>.value();
  Completer<void>? _activeCompletion;
  bool _isPlaying = false;
  bool _disposed = false;

  bool get isPlaying => _isPlaying;

  @override
  Future<SoundPreviewPlayback> play(NotificationSoundPreference sound) {
    return _serialized<SoundPreviewPlayback>(() async {
      await _stopPlayer();
      if (!sound.isAudible) {
        return SoundPreviewPlayback(completed: Future<void>.value());
      }

      final Completer<void> completion = Completer<void>();
      _activeCompletion = completion;
      _isPlaying = true;
      try {
        switch (sound.mode) {
          case NotificationSoundMode.bundledDefault:
            await _player.playAsset(bundledAssetPath, volume: sound.volume);
          case NotificationSoundMode.custom:
            await _player.playFile(sound.privateSource!, volume: sound.volume);
          case NotificationSoundMode.muted:
            throw StateError('Muted sound passed the audible guard.');
        }
      } on Object {
        try {
          await _player.stop();
        } on Object {
          // The original playback failure remains the useful boundary error.
        }
        _finishActivePlayback();
        rethrow;
      }
      return SoundPreviewPlayback(completed: completion.future);
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

  Future<void> _stopPlayer() async {
    if (_isPlaying) {
      await _player.stop();
    }
    _finishActivePlayback();
  }

  void _finishActivePlayback() {
    _isPlaying = false;
    final Completer<void>? completion = _activeCompletion;
    _activeCompletion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
  }

  void _failActivePlayback(Object error, StackTrace stackTrace) {
    _isPlaying = false;
    final Completer<void>? completion = _activeCompletion;
    _activeCompletion = null;
    if (completion != null && !completion.isCompleted) {
      completion.completeError(error, stackTrace);
    }
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    if (_disposed) {
      return Future<T>.error(
        StateError('AudioSoundPreviewAdapter is disposed.'),
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
