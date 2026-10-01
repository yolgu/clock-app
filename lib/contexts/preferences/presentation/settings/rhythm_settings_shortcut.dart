import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/i18n/public.dart';
import '../../../../shared/ui/public.dart'
    show ClockRhythmCard, ClockRhythmLayout, ClockRhythmSpace;
import '../../domain/notification_sound_preference.dart';
import '../../domain/user_preferences.dart';
import '../preferences_providers.dart';
import '../preferences_view_state.dart';

/// A Settings-style row summarising the saved rhythm that opens the
/// Settings destination, where the focus window and sound are edited.
final class RhythmSettingsShortcut extends ConsumerWidget {
  const RhythmSettingsShortcut({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final UserPreferences? preferences = ref
        .watch(preferencesViewModelProvider)
        .maybeWhen(
          data: (PreferencesViewState state) => state.preferences,
          orElse: () => null,
        );
    final String? summary = preferences == null
        ? null
        : _summary(copy, preferences);
    final double padding = ClockRhythmLayout.cardPaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    return ClockRhythmCard.unpadded(
      key: const ValueKey<String>('rhythm-settings-shortcut'),
      child: Semantics(
        button: true,
        hint: copy.clockSettingsShortcutHint,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ClockRhythmLayout.minimumInteractiveDimension,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: ClockRhythmSpace.space16,
              ),
              child: Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: SizedBox.square(
                      dimension: 36,
                      child: Icon(
                        Icons.timer_outlined,
                        size: 22,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: ClockRhythmSpace.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          copy.rhythmSettingsDisclosureTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (summary != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: ClockRhythmSpace.space4,
                            ),
                            child: Text(
                              summary,
                              key: const ValueKey<String>(
                                'rhythm-settings-shortcut-summary',
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ClockRhythmSpace.space8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _summary(AppLocalizations copy, UserPreferences preferences) {
    final NotificationSoundPreference sound = preferences.notificationSound;
    final String soundSummary = switch (sound.mode) {
      NotificationSoundMode.muted => copy.rhythmSettingsSummaryMuted,
      _ when sound.volume == 0 => copy.rhythmSettingsSummaryZeroVolume,
      NotificationSoundMode.bundledDefault => copy.soundDefaultLabel,
      NotificationSoundMode.custom =>
        sound.customFileName ?? copy.soundCustomFallback,
    };
    return copy.rhythmSettingsSummary(
      preferences.rhythmConfiguration.focusDuration.minutes,
      preferences.rhythmConfiguration.restDuration.minutes,
      preferences.rhythmConfiguration.dailyRhythm.start.text,
      preferences.rhythmConfiguration.dailyRhythm.end.text,
      soundSummary,
    );
  }
}
