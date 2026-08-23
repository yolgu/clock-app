import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../application/ports/sound_preview_port.dart';
import '../../domain/notification_sound_preference.dart';

abstract interface class AndroidPreviewPlayer {
  Stream<void> get completed;

  Future<void> playBundledAsset(String assetPath);

  Future<void> stop();

  Future<void> dispose();
}

final class AndroidSoundPreviewAdapter implements SoundPreviewPort {
  AndroidSoundPreviewAdapter({
    required this.bundledAssetPath,
    AndroidPreviewPlayer? player,
  }) : _player = player ?? AudioplayersAndroidPreviewPlayer();

  final String bundledAssetPath;
  final AndroidPreviewPlayer _player;

  Completer<void>? _activeCompletion;
  StreamSubscription<void>? _completionSubscription;
  bool _disposed = false;

  @override
  Future<SoundPreviewPlayback> play(NotificationSoundPreference sound) async {
    _requireActive();
    if (sound.mode != NotificationSoundMode.bundledDefault) {
      throw ArgumentError.value(
        sound.mode,
        'sound.mode',
        'Android preview supports the bundled sound only',
      );
    }

    await stop();
    final Completer<void> completion = Completer<void>();
    _activeCompletion = completion;
    _completionSubscription = _player.completed.listen(
      (_) => _finishPlayback(completion),
      onError: (Object error, StackTrace stackTrace) {
        _finishPlayback(completion, error: error, stackTrace: stackTrace);
      },
    );
    try {
      await _player.playBundledAsset(bundledAssetPath);
    } on Object catch (error, stackTrace) {
      await _cancelCompletionSubscription();
      _activeCompletion = null;
      Error.throwWithStackTrace(error, stackTrace);
    }
    return SoundPreviewPlayback(completed: completion.future);
  }

  @override
  Future<void> stop() async {
    if (_disposed) {
      return;
    }
    await _player.stop();
    await _cancelCompletionSubscription();
    final Completer<void>? completion = _activeCompletion;
    _activeCompletion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await stop();
    _disposed = true;
    await _player.dispose();
  }

  void _finishPlayback(
    Completer<void> completion, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!identical(_activeCompletion, completion)) {
      return;
    }
    _activeCompletion = null;
    unawaited(_cancelCompletionSubscription());
    if (completion.isCompleted) {
      return;
    }
    if (error == null) {
      completion.complete();
      return;
    }
    completion.completeError(error, stackTrace ?? StackTrace.current);
  }

  Future<void> _cancelCompletionSubscription() async {
    final StreamSubscription<void>? subscription = _completionSubscription;
    _completionSubscription = null;
    await subscription?.cancel();
  }

  void _requireActive() {
    if (_disposed) {
      throw StateError('AndroidSoundPreviewAdapter is disposed.');
    }
  }
}

final class AudioplayersAndroidPreviewPlayer implements AndroidPreviewPlayer {
  AudioplayersAndroidPreviewPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<void> get completed => _player.onPlayerComplete;

  @override
  Future<void> playBundledAsset(String assetPath) {
    const String flutterAssetPrefix = 'assets/';
    if (!assetPath.startsWith(flutterAssetPrefix)) {
      throw ArgumentError.value(
        assetPath,
        'assetPath',
        'must be rooted under assets/',
      );
    }
    return _player.play(
      AssetSource(assetPath.substring(flutterAssetPrefix.length)),
      volume: 1,
      position: Duration.zero,
    );
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
