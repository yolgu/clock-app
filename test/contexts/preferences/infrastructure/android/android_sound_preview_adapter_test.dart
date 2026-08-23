import 'dart:async';

import 'package:clock_rhythm/contexts/preferences/infrastructure/android/android_sound_preview_adapter.dart';
import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plays the bundled asset once and completes with the player', () async {
    final _FakeAndroidPreviewPlayer player = _FakeAndroidPreviewPlayer();
    final AndroidSoundPreviewAdapter adapter = AndroidSoundPreviewAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );
    addTearDown(adapter.dispose);

    final playback = await adapter.play(
      NotificationSoundPreference.bundledDefault(),
    );
    expect(player.playedAssets, <String>['assets/audio/CHIME14.mp3']);

    player.completePlayback();
    await expectLater(playback.completed, completes);
  });

  test(
    'starting another preview stops and completes the previous one',
    () async {
      final _FakeAndroidPreviewPlayer player = _FakeAndroidPreviewPlayer();
      final AndroidSoundPreviewAdapter adapter = AndroidSoundPreviewAdapter(
        bundledAssetPath: 'assets/audio/CHIME14.mp3',
        player: player,
      );
      addTearDown(adapter.dispose);

      final first = await adapter.play(
        NotificationSoundPreference.bundledDefault(),
      );
      final second = await adapter.play(
        NotificationSoundPreference.bundledDefault(),
      );

      await expectLater(first.completed, completes);
      expect(player.stopCalls, 2);
      player.completePlayback();
      await expectLater(second.completed, completes);
    },
  );

  test('rejects muted and custom preview modes', () async {
    final AndroidSoundPreviewAdapter adapter = AndroidSoundPreviewAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: _FakeAndroidPreviewPlayer(),
    );
    addTearDown(adapter.dispose);

    await expectLater(
      adapter.play(
        NotificationSoundPreference.bundledDefault().toggleMute(
          UnmuteSoundBehavior.bundledDefault,
        ),
      ),
      throwsArgumentError,
    );
    await expectLater(
      adapter.play(
        NotificationSoundPreference.custom(
          fileName: 'custom.mp3',
          privateSource: 'private/custom.mp3',
        ),
      ),
      throwsArgumentError,
    );
  });

  test(
    'stop and dispose are idempotent and complete active playback',
    () async {
      final _FakeAndroidPreviewPlayer player = _FakeAndroidPreviewPlayer();
      final AndroidSoundPreviewAdapter adapter = AndroidSoundPreviewAdapter(
        bundledAssetPath: 'assets/audio/CHIME14.mp3',
        player: player,
      );

      final playback = await adapter.play(
        NotificationSoundPreference.bundledDefault(),
      );
      await adapter.stop();
      await expectLater(playback.completed, completes);
      await adapter.dispose();
      await adapter.dispose();

      expect(player.disposeCalls, 1);
      await expectLater(
        adapter.play(NotificationSoundPreference.bundledDefault()),
        throwsStateError,
      );
    },
  );
}

final class _FakeAndroidPreviewPlayer implements AndroidPreviewPlayer {
  final StreamController<void> _completed = StreamController<void>.broadcast();
  final List<String> playedAssets = <String>[];
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> playBundledAsset(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    await _completed.close();
  }

  void completePlayback() {
    _completed.add(null);
  }
}
