import 'dart:async';

import 'package:clock_rhythm/contexts/rhythm/application/ports/event_sound_port.dart';
import 'package:clock_rhythm/contexts/rhythm/infrastructure/audio/audio_event_sound_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mute skips playback while stopping a previous event', () async {
    final FakeEventAudioPlayer player = FakeEventAudioPlayer();
    final AudioEventSoundAdapter adapter = AudioEventSoundAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );
    await adapter.play(EventSoundSelection.bundledDefault(volume: 1));

    final EventSoundPlaybackResult result = await adapter.play(
      EventSoundSelection.muted(volume: 1),
    );

    expect(result, same(EventSoundPlaybackResult.muted));
    expect(player.calls, <String>[
      'asset:assets/audio/CHIME14.mp3:1.0',
      'stop',
    ]);
    expect(adapter.isPlaying, isFalse);
    await adapter.dispose();
  });

  test('zero volume still starts bundled playback exactly once', () async {
    final FakeEventAudioPlayer player = FakeEventAudioPlayer();
    final AudioEventSoundAdapter adapter = AudioEventSoundAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );

    final EventSoundPlaybackResult result = await adapter.play(
      EventSoundSelection.bundledDefault(volume: 0),
    );

    expect(result.source, EventSoundPlaybackSource.bundledDefault);
    expect(player.calls, <String>['asset:assets/audio/CHIME14.mp3:0.0']);
    expect(adapter.isPlaying, isTrue);
    await adapter.dispose();
  });

  test('new event stops prior playback and restarts from its source', () async {
    final FakeEventAudioPlayer player = FakeEventAudioPlayer();
    final AudioEventSoundAdapter adapter = AudioEventSoundAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );

    await adapter.play(EventSoundSelection.bundledDefault(volume: 0.5));
    await adapter.play(
      EventSoundSelection.custom(
        privateSource: r'C:\private\bell.mp3',
        volume: 0.25,
      ),
    );

    expect(player.calls, <String>[
      'asset:assets/audio/CHIME14.mp3:0.5',
      'stop',
      r'file:C:\private\bell.mp3:0.25',
    ]);
    await adapter.dispose();
  });

  test('completion clears active playback state', () async {
    final FakeEventAudioPlayer player = FakeEventAudioPlayer();
    final AudioEventSoundAdapter adapter = AudioEventSoundAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );
    await adapter.play(EventSoundSelection.bundledDefault(volume: 1));

    player.complete();
    await Future<void>.delayed(Duration.zero);

    expect(adapter.isPlaying, isFalse);
    await adapter.dispose();
  });

  test(
    'custom failure falls back without mutating selection and requests repair',
    () async {
      final FakeEventAudioPlayer player = FakeEventAudioPlayer()
        ..fileFailure = StateError('custom decoder failed');
      final AudioEventSoundAdapter adapter = AudioEventSoundAdapter(
        bundledAssetPath: 'assets/audio/CHIME14.mp3',
        player: player,
      );
      final EventSoundSelection selection = EventSoundSelection.custom(
        privateSource: r'C:\private\bell.mp3',
        volume: 0.4,
      );

      final EventSoundPlaybackResult result = await adapter.play(selection);

      expect(result.source, EventSoundPlaybackSource.bundledDefault);
      expect(result.customRepairRequired, isTrue);
      expect(selection.mode, EventSoundSelectionMode.custom);
      expect(selection.privateSource, r'C:\private\bell.mp3');
      expect(player.calls, <String>[
        r'file:C:\private\bell.mp3:0.4',
        'stop',
        'asset:assets/audio/CHIME14.mp3:0.4',
      ]);
      await adapter.dispose();
    },
  );

  test('explicit stop and disposal stop playback without looping', () async {
    final FakeEventAudioPlayer player = FakeEventAudioPlayer();
    final AudioEventSoundAdapter adapter = AudioEventSoundAdapter(
      bundledAssetPath: 'assets/audio/CHIME14.mp3',
      player: player,
    );
    await adapter.play(EventSoundSelection.bundledDefault(volume: 1));

    await adapter.stop();
    await adapter.dispose();
    await adapter.dispose();

    expect(player.calls, <String>[
      'asset:assets/audio/CHIME14.mp3:1.0',
      'stop',
      'dispose',
    ]);
  });
}

final class FakeEventAudioPlayer implements EventAudioPlayer {
  final StreamController<void> _completed = StreamController<void>.broadcast();
  final List<String> calls = <String>[];
  Object? fileFailure;
  Object? assetFailure;

  void complete() => _completed.add(null);

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
    final Object? failure = assetFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> playFile(String filePath, {required double volume}) async {
    calls.add('file:$filePath:$volume');
    final Object? failure = fileFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }
}
