import '../../domain/notification_sound_preference.dart';

final class SoundPreviewPlayback {
  const SoundPreviewPlayback({required this.completed});

  final Future<void> completed;
}

abstract interface class SoundPreviewPort {
  Future<SoundPreviewPlayback> play(NotificationSoundPreference sound);

  Future<void> stop();
}
