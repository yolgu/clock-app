import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/i18n/public.dart';
import '../../../../shared/ui/public.dart'
    show
        ClockRhythmCard,
        ClockRhythmLayout,
        ClockRhythmSpace,
        LineGlyph,
        LineIcon;
import '../../domain/notification_sound_preference.dart';
import '../../domain/user_preferences.dart';
import '../preferences_data_controller.dart';
import '../preferences_providers.dart';

/// A Settings-style row summarising the saved rhythm that opens the
/// Settings destination, where the focus window and sound are edited.
///
/// On its own it is a card; [embedded] draws it as the closing row of the
/// card that holds it, separated by a hairline.
final class RhythmSettingsShortcut extends ConsumerWidget {
  const RhythmSettingsShortcut({
    required this.onPressed,
    this.embedded = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations copy = AppLocalizations.of(context);
    final UserPreferences? preferences = ref
        .watch(preferencesDataControllerProvider)
        .maybeWhen(
          data: (PreferencesDataState state) => state.preferences,
          orElse: () => null,
        );
    final String? summary = preferences == null
        ? null
        : _summary(copy, preferences);
    final double padding = ClockRhythmLayout.cardPaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    final Widget row = Semantics(
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
              vertical: ClockRhythmSpace.space12,
            ),
            child: Row(
              children: <Widget>[
                LineIcon(
                  LineGlyph.bell,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: ClockRhythmSpace.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.rhythmSettingsDisclosureTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
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
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: ClockRhythmSpace.space8),
                LineIcon(
                  LineGlyph.chevronRight,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (embedded) {
      return DecoratedBox(
        key: const ValueKey<String>('rhythm-settings-shortcut'),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: row,
      );
    }
    return ClockRhythmCard.unpadded(
      key: const ValueKey<String>('rhythm-settings-shortcut'),
      child: row,
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
