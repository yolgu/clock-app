import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/i18n/public.dart';
import '../../../../shared/ui/public.dart' show SemanticStatusAnnouncement;
import '../../application/ports/notification_sound_file_port.dart';
import '../../application/preferences_command_result.dart';
import '../../domain/notification_sound_preference.dart';
import '../preferences_platform_capabilities.dart';
import '../preferences_providers.dart';
import '../preferences_view_state.dart';
import 'sound_preview_button.dart';

final class NotificationSoundPanel extends ConsumerStatefulWidget {
  const NotificationSoundPanel({super.key});

  @override
  ConsumerState<NotificationSoundPanel> createState() =>
      _NotificationSoundPanelState();
}

final class _NotificationSoundPanelState
    extends ConsumerState<NotificationSoundPanel> {
  double? _volume;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PreferencesViewState> value = ref.watch(
      preferencesViewModelProvider,
    );
    return value.when(
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stackTrace) => const SizedBox.shrink(),
      data: (PreferencesViewState state) => _buildPanel(context, state),
    );
  }

  Widget _buildPanel(BuildContext context, PreferencesViewState state) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final PreferencesPlatformCapabilities capabilities = ref.watch(
      preferencesPlatformCapabilitiesProvider,
    );
    final NotificationSoundPreference sound =
        state.preferences.notificationSound;
    final double volume = _volume ?? sound.volume;
    final String volumeLabel = NumberFormat.percentPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(volume);
    final String selection = switch (sound.mode) {
      NotificationSoundMode.bundledDefault => copy.soundDefaultLabel,
      NotificationSoundMode.custom =>
        sound.customFileName ?? copy.soundCustomFallback,
      NotificationSoundMode.muted => copy.soundMutedLabel,
    };
    final PreferencesRepairNeed? repairNeed =
        state.repairNeeds.contains(PreferencesRepairNeed.sound)
        ? PreferencesRepairNeed.sound
        : state.repairNeeds.contains(PreferencesRepairNeed.notificationPayload)
        ? PreferencesRepairNeed.notificationPayload
        : null;

    return Card(
      key: const ValueKey<String>('notification-sound-panel'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(copy.soundEyebrow),
            Text(
              copy.soundTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(selection, key: const ValueKey<String>('sound-selection')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  key: const ValueKey<String>('use-default-sound'),
                  onPressed: state.isBusy
                      ? null
                      : () {
                          _clearLocalVolume();
                          ref
                              .read(preferencesViewModelProvider.notifier)
                              .useBundledSound();
                        },
                  child: Text(copy.soundUseDefault),
                ),
                if (capabilities.showsCustomSound)
                  OutlinedButton(
                    key: const ValueKey<String>('choose-custom-sound'),
                    onPressed: state.isBusy
                        ? null
                        : () {
                            ref
                                .read(preferencesViewModelProvider.notifier)
                                .chooseCustomSound();
                          },
                    child: Text(copy.soundChooseMp3),
                  ),
                FilledButton.tonal(
                  key: const ValueKey<String>('toggle-mute'),
                  onPressed: state.isBusy
                      ? null
                      : () {
                          ref
                              .read(preferencesViewModelProvider.notifier)
                              .toggleMute();
                        },
                  child: Text(
                    sound.mode == NotificationSoundMode.muted
                        ? copy.soundUnmute
                        : copy.soundMute,
                  ),
                ),
                SoundPreviewButton(
                  isPreviewing: state.isSoundPreviewing,
                  previewLabel: copy.soundPreview,
                  stopLabel: copy.soundStopPreview,
                  enabled: !state.isBusy && sound.isAudible && volume > 0,
                  onPreview: () {
                    ref
                        .read(preferencesViewModelProvider.notifier)
                        .previewSound();
                  },
                  onStop: () {
                    ref
                        .read(preferencesViewModelProvider.notifier)
                        .stopSoundPreview();
                  },
                ),
              ],
            ),
            if (capabilities.showsCustomSound)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  copy.soundCustomRequirements(
                    NotificationSoundFilePort.maximumCustomMp3MiB,
                  ),
                ),
              ),
            if (capabilities.showsVolume) ...<Widget>[
              const SizedBox(height: 12),
              Semantics(
                label: copy.soundVolumeLabel,
                value: volumeLabel,
                child: Slider(
                  key: const ValueKey<String>('sound-volume'),
                  value: volume,
                  divisions: 20,
                  label: volumeLabel,
                  onChanged: state.isBusy
                      ? null
                      : (double next) => setState(() => _volume = next),
                  onChangeEnd: state.isBusy
                      ? null
                      : (double next) async {
                          await ref
                              .read(preferencesViewModelProvider.notifier)
                              .changeVolume(next);
                          _clearLocalVolume();
                        },
                ),
              ),
              if (volume == 0 && sound.mode != NotificationSoundMode.muted)
                Text(
                  copy.soundZeroVolumeWarning,
                  key: const ValueKey<String>('zero-volume-warning'),
                ),
            ],
            if (repairNeed != null)
              ListTile(
                key: const ValueKey<String>('sound-repair-needed'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning_amber),
                title: Text(copy.failureCustomSoundPlayback),
                trailing: TextButton(
                  onPressed: state.isBusy
                      ? null
                      : () {
                          ref
                              .read(preferencesViewModelProvider.notifier)
                              .repairEffect(repairNeed);
                        },
                  child: Text(copy.soundRepair),
                ),
              ),
            if (state.failure == PreferencesFailure.sound ||
                state.failure == PreferencesFailure.preview ||
                state.failure == PreferencesFailure.volume)
              SemanticStatusAnnouncement(
                message: state.failure == PreferencesFailure.preview
                    ? copy.failureCustomSoundPlayback
                    : copy.failurePreferencesSave,
                child: Text(
                  state.failure == PreferencesFailure.preview
                      ? copy.failureCustomSoundPlayback
                      : copy.failurePreferencesSave,
                  key: const ValueKey<String>('sound-operation-failure'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _clearLocalVolume() {
    if (mounted) {
      setState(() => _volume = null);
    }
  }
}
