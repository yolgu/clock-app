import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/i18n/public.dart';
import '../../../../shared/ui/public.dart'
    show
        ClockRhythmCard,
        ClockRhythmLayout,
        ClockRhythmPage,
        ClockRhythmRadius,
        ClockRhythmSpace,
        ClockRhythmStatusChip,
        LineGlyph,
        LineIcon,
        SemanticStatusAnnouncement;
import '../../application/preferences_command_result.dart';
import '../../domain/appearance_preference.dart';
import '../../domain/theme_preference.dart';
import '../preferences_data_controller.dart';
import 'theme_catalog.dart';

final class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final AsyncValue<PreferencesDataState> value = ref.watch(
      preferencesDataControllerProvider,
    );
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) =>
          Center(child: Text(copy.messagePreferencesFailed)),
      data: (PreferencesDataState state) {
        final double width = MediaQuery.sizeOf(context).width;
        final double horizontalInset = ClockRhythmLayout.horizontalInsetFor(
          width,
        );
        final TextScaler textScaler = MediaQuery.textScalerOf(context);
        final int maximumTitleLines =
            width < ClockRhythmLayout.compactBreakpoint ? 2 : 3;
        final double cardExtent =
            _ThemeChoice.padding * 2 +
            _ThemeChoice.previewHeight +
            ClockRhythmSpace.space8 * 2 +
            textScaler.scale(22) * maximumTitleLines +
            textScaler.scale(18) * _ThemeChoice.maximumDescriptionLines;
        final String appliedName = _ThemeCopy.of(
          copy,
          state.preferences.theme,
        ).name;
        return ClockRhythmPage(
          section: copy.themePageSection,
          title: copy.themeTitle,
          description: copy.themeDescription,
          trailing: ClockRhythmStatusChip(
            key: const ValueKey<String>('theme-applied-chip'),
            label: ClockRhythmPage.usesToolbar(context)
                ? '${copy.themeAppliedLabel} · $appliedName'
                : appliedName,
            tone: Theme.of(context).colorScheme.primary,
          ),
          builder: (BuildContext context, Widget lead) => CustomScrollView(
            key: const PageStorageKey<String>('theme-page-scroll'),
            restorationId: 'theme_page_scroll',
            slivers: <Widget>[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  ClockRhythmSpace.space24,
                  horizontalInset,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      lead,
                      _AppearanceSelector(
                        selected: state.preferences.appearance,
                        enabled: !state.isBusy,
                        onChanged: (AppearancePreference appearance) {
                          ref
                              .read(preferencesDataControllerProvider.notifier)
                              .changeAppearance(appearance);
                        },
                      ),
                      const SizedBox(height: ClockRhythmSpace.space16),
                      if (state.failure == PreferencesFailure.theme)
                        SemanticStatusAnnouncement(
                          message: copy.failurePreferencesSave,
                          child: Text(
                            copy.failurePreferencesSave,
                            key: const ValueKey<String>('theme-change-failure'),
                          ),
                        ),
                      if (state.repairNeeds.contains(
                        PreferencesRepairNeed.visual,
                      ))
                        ListTile(
                          key: const ValueKey<String>('theme-repair-needed'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(copy.failureUnknown),
                          trailing: TextButton(
                            onPressed: state.isBusy
                                ? null
                                : () => ref
                                      .read(
                                        preferencesDataControllerProvider
                                            .notifier,
                                      )
                                      .repairEffect(
                                        PreferencesRepairNeed.visual,
                                      ),
                            child: Text(copy.actionRetry),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  ClockRhythmSpace.space8,
                  horizontalInset,
                  ClockRhythmSpace.space24,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisExtent: cardExtent,
                    crossAxisSpacing: ClockRhythmSpace.space12,
                    mainAxisSpacing: ClockRhythmSpace.space12,
                  ),
                  itemCount: ThemeCatalog.definitions.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ThemeDefinition definition =
                        ThemeCatalog.definitions[index];
                    final bool selected =
                        definition.id == state.preferences.theme;
                    final _ThemeCopy themeCopy = _ThemeCopy.of(
                      copy,
                      definition.id,
                    );
                    return _ThemeChoice(
                      definition: definition,
                      name: themeCopy.name,
                      description: themeCopy.description,
                      selected: selected,
                      selectedLabel: copy.themeSelected,
                      selectLabel: copy.themeSelect,
                      enabled: !state.isBusy,
                      maximumTitleLines: maximumTitleLines,
                      onSelected: () {
                        ref
                            .read(preferencesDataControllerProvider.notifier)
                            .changeTheme(definition.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The localized name and one-line character of a theme, keyed by its stable
/// backup identifier.
final class _ThemeCopy {
  const _ThemeCopy(this.name, this.description);

  factory _ThemeCopy.of(AppLocalizations copy, ThemePreference preference) {
    return switch (preference) {
      ThemePreference.current => _ThemeCopy(
        copy.themeGraphiteName,
        copy.themeGraphiteDescription,
      ),
      ThemePreference.tokyoNight => _ThemeCopy(
        copy.themeMidnightName,
        copy.themeMidnightDescription,
      ),
      ThemePreference.oneDarkPro => _ThemeCopy(
        copy.themeSlateName,
        copy.themeSlateDescription,
      ),
      ThemePreference.catppuccinMocha => _ThemeCopy(
        copy.themeDuskName,
        copy.themeDuskDescription,
      ),
      ThemePreference.nord => _ThemeCopy(
        copy.themeGlacierName,
        copy.themeGlacierDescription,
      ),
      ThemePreference.draculaOfficial => _ThemeCopy(
        copy.themeOrchidName,
        copy.themeOrchidDescription,
      ),
      ThemePreference.gruvbox => _ThemeCopy(
        copy.themeEmberName,
        copy.themeEmberDescription,
      ),
      ThemePreference.monokaiPro => _ThemeCopy(
        copy.themeAuroraName,
        copy.themeAuroraDescription,
      ),
      ThemePreference.nightOwl => _ThemeCopy(
        copy.themeMossName,
        copy.themeMossDescription,
      ),
      ThemePreference.synthwave84 => _ThemeCopy(
        copy.themeSunsetName,
        copy.themeSunsetDescription,
      ),
      ThemePreference.ayuMirageDark => _ThemeCopy(
        copy.themeMonoName,
        copy.themeMonoDescription,
      ),
    };
  }

  final String name;
  final String description;
}

/// One theme as a card in the current theme, with a miniature of the
/// candidate palette so every option can be compared side by side.
final class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.definition,
    required this.name,
    required this.description,
    required this.selected,
    required this.selectedLabel,
    required this.selectLabel,
    required this.enabled,
    required this.maximumTitleLines,
    required this.onSelected,
  });

  static const double padding = ClockRhythmSpace.space12;
  static const double previewHeight = 88;
  static const int maximumDescriptionLines = 2;

  final ThemeDefinition definition;
  final String name;
  final String description;
  final bool selected;
  final String selectedLabel;
  final String selectLabel;
  final bool enabled;
  final int maximumTitleLines;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: name,
      hint: selectLabel,
      child: ClockRhythmCard.unpadded(
        borderColor: selected ? theme.colorScheme.primary : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('theme-${definition.id.id}'),
          onTap: enabled && !selected ? onSelected : null,
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ExcludeSemantics(
                  child: _PalettePreview(definition: definition),
                ),
                const SizedBox(height: ClockRhythmSpace.space8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        name,
                        maxLines: maximumTitleLines,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (selected)
                      Tooltip(
                        message: selectedLabel,
                        child: LineIcon(
                          LineGlyph.checkCircle,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: ClockRhythmSpace.space4),
                Text(
                  description,
                  maxLines: maximumDescriptionLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A miniature screen drawn in the candidate palette: page background, a
/// title line, and a surface holding the primary, secondary and danger roles.
/// Dark, light, or whatever the operating system uses; the palette below
/// keeps its hues in either mode.
final class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final AppearancePreference selected;
  final bool enabled;
  final ValueChanged<AppearancePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: ClockRhythmSpace.space12,
      runSpacing: ClockRhythmSpace.space8,
      children: <Widget>[
        Text(
          copy.themeAppearanceTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SegmentedButton<AppearancePreference>(
          key: const ValueKey<String>('theme-appearance'),
          showSelectedIcon: false,
          segments: <ButtonSegment<AppearancePreference>>[
            ButtonSegment<AppearancePreference>(
              value: AppearancePreference.system,
              label: Text(copy.themeAppearanceSystem),
            ),
            ButtonSegment<AppearancePreference>(
              value: AppearancePreference.light,
              label: Text(copy.themeAppearanceLight),
            ),
            ButtonSegment<AppearancePreference>(
              value: AppearancePreference.dark,
              label: Text(copy.themeAppearanceDark),
            ),
          ],
          selected: <AppearancePreference>{selected},
          onSelectionChanged: enabled
              ? (Set<AppearancePreference> next) => onChanged(next.single)
              : null,
        ),
      ],
    );
  }
}

final class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.definition});

  final ThemeDefinition definition;

  @override
  Widget build(BuildContext context) {
    final ThemeSeeds seeds = definition.seedsFor(Theme.of(context).brightness);
    final Color text = seeds.text.color;
    return Container(
      height: _ThemeChoice.previewHeight,
      padding: const EdgeInsets.all(ClockRhythmSpace.space8),
      decoration: BoxDecoration(
        color: seeds.background.color,
        borderRadius: BorderRadius.circular(ClockRhythmRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _PreviewBlock(
                color: seeds.accentPrimary.color,
                width: 10,
                height: 10,
                radius: 3,
              ),
              const SizedBox(width: 6),
              _PreviewBlock(
                color: text.withValues(alpha: 0.85),
                width: 64,
                height: 6,
                radius: 3,
              ),
            ],
          ),
          const SizedBox(height: ClockRhythmSpace.space8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: ClockRhythmSpace.space8,
              ),
              decoration: BoxDecoration(
                color: seeds.surface.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _PreviewBlock(
                    color: Color.lerp(text, seeds.surface.color, 0.38)!,
                    width: 96,
                    height: 5,
                    radius: 3,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      _PreviewBlock(
                        color: seeds.accentPrimary.color,
                        width: 34,
                        height: 12,
                        radius: 4,
                      ),
                      const SizedBox(width: 6),
                      _PreviewBlock(
                        color: seeds.accentSecondary.color,
                        width: 12,
                        height: 12,
                        radius: 6,
                      ),
                      const SizedBox(width: 6),
                      _PreviewBlock(
                        color: seeds.danger.color,
                        width: 12,
                        height: 12,
                        radius: 6,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({
    required this.color,
    required this.width,
    required this.height,
    required this.radius,
  });

  final Color color;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
