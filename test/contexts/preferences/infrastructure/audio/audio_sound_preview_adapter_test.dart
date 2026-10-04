import 'dart:async';

import 'package:clock_rhythm/contexts/preferences/application/ports/sound_preview_port.dart';
import 'package:clock_rhythm/contexts/preferences/domain/notification_sound_preference.dart';
import 'package:clock_rhythm/contexts/preferences/infrastructure/audio/audio_sound_preview_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'preview plays the current custom source once at saved volume',
    () async {
      final FakePreviewAudioPlayer player = FakePreviewAudioPlayer();
      final AudioSoundPreviewAdapter adapter = AudioSoundPreviewAdapter(
        bundledAssetPath: 'assets/audio/CHIME14.mp3',
        player: player,
      );

      await adapter.play(
        NotificationSoundPreference.custom(
          fileName: 'bell.mp3',
          privateSource: r'C:\private\bell.mp3',
          volume: 0.35,
        ),
      );

      expect(player.calls, <String>[r'file:C:\private\bell.mp3:0.35']);
      expect(adapter.isPlaying, isTrue);
      await adapter.dispose();
    },
  );

  test('completion resolves playback and clears preview state', () async {
    final FakePreviewAudioPlayer player = FakePreviewAudioPlayer();
    final AudioSoundPreviewAdapter adapter = AudioSoundPreviewAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );
    final SoundPreviewPlayback playback = await adapter.play(
      NotificationSoundPreference.bundledDefault(),
    );

    player.complete();
    await playback.completed;

    expect(adapter.isPlaying, isFalse);
    await adapter.dispose();
  });

  test(
    'asynchronous player failure rejects completion and clears state',
    () async {
      final FakePreviewAudioPlayer player = FakePreviewAudioPlayer();
      final AudioSoundPreviewAdapter adapter = AudioSoundPreviewAdapter(
        bundledAssetPath: 'assets/audio/CHIME14.mp3',
        player: player,
      );
      final SoundPreviewPlayback playback = await adapter.play(
        NotificationSoundPreference.bundledDefault(),
      );
      final Future<void> failure = expectLater(
        playback.completed,
        throwsStateError,
      );

      player.fail(StateError('playback failed'));
      await failure;

      expect(adapter.isPlaying, isFalse);
      await adapter.dispose();
    },
  );

  test(
    'new preview stops prior audio before restarting from the beginning',
    () async {
      final FakePreviewAudioPlayer player = FakePreviewAudioPlayer();
      final AudioSoundPreviewAdapter adapter = AudioSoundPreviewAdapter(
        bundledAssetPath: 'assets/audio/CHIME14.mp3',
        player: player,
      );
      final SoundPreviewPlayback first = await adapter.play(
        NotificationSoundPreference.bundledDefault(volume: 1),
      );

      await adapter.play(
        NotificationSoundPreference.bundledDefault(volume: 0.5),
      );
      await first.completed;

      expect(player.calls, <String>[
        'asset:assets/audio/CHIME14.mp3:1.0',
        'stop',
        'asset:assets/audio/CHIME14.mp3:0.5',
      ]);
      await adapter.dispose();
    },
  );

  test('Mute creates no audio and returns completed playback', () async {
    final FakePreviewAudioPlayer player = FakePreviewAudioPlayer();
    final AudioSoundPreviewAdapter adapter = AudioSoundPreviewAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );
    final NotificationSoundPreference muted =
        NotificationSoundPreference.bundledDefault().toggleMute(
          UnmuteSoundBehavior.restorePreviousSelection,
        );

    final SoundPreviewPlayback playback = await adapter.play(muted);
    await playback.completed;

    expect(player.calls, isEmpty);
    expect(adapter.isPlaying, isFalse);
    await adapter.dispose();
  });

  test('zero volume is forwarded without being converted to Mute', () async {
    final FakePreviewAudioPlayer player = FakePreviewAudioPlayer();
    final AudioSoundPreviewAdapter adapter = AudioSoundPreviewAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );

    await adapter.play(NotificationSoundPreference.bundledDefault(volume: 0));

    expect(player.calls, <String>['asset:assets/audio/CHIME14.mp3:0.0']);
    await adapter.dispose();
  });

  test('explicit stop resolves completion and releases player once', () async {
    final FakePreviewAudioPlayer player = FakePreviewAudioPlayer();
    final AudioSoundPreviewAdapter adapter = AudioSoundPreviewAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );
    final SoundPreviewPlayback playback = await adapter.play(
      NotificationSoundPreference.bundledDefault(),
    );

    await adapter.stop();
    await playback.completed;
    await adapter.dispose();
    await adapter.dispose();

    expect(player.calls, <String>[
      'asset:assets/audio/CHIME14.mp3:1.0',
      'stop',
      'dispose',
    ]);
  });
}

final class FakePreviewAudioPlayer implements PreviewAudioPlayer {
  final StreamController<void> _completed = StreamController<void>.broadcast();
  final List<String> calls = <String>[];

  void complete() => _completed.add(null);

  void fail(Object error) => _completed.addError(error, StackTrace.current);

  @override
  Stream<void> get onCompleted => _completed.stream;

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await _completed.close();
  }

  @override
  Future<void> playAsset(String assetPath, {required double volume}) async {
    calls.add('asset:$assetPath:$volume');
  }

  @override
  Future<void> playFile(String filePath, {required double volume}) async {
    calls.add('file:$filePath:$volume');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }
}
