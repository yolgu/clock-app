import 'ports/settings_repository.dart';
import 'ports/sound_preview_port.dart';

final class PreviewNotificationSound {
  const PreviewNotificationSound({
    required this._settingsRepository,
    required this._soundPreview,
  });

  final SettingsRepository _settingsRepository;
  final SoundPreviewPort _soundPreview;

  Future<SoundPreviewPlayback> execute() async {
    final preferences = await _settingsRepository.load();
    return _soundPreview.play(preferences.notificationSound);
  }
}

final class StopNotificationSoundPreview {
  const StopNotificationSoundPreview(this._soundPreview);

  final SoundPreviewPort _soundPreview;

  Future<void> execute() {
    return _soundPreview.stop();
  }
}
