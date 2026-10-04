import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/i18n/public.dart';
import '../../../../shared/ui/public.dart'
    show
        ClockRhythmCard,
        ClockRhythmLayout,
        ClockRhythmPageHeader,
        ClockRhythmSpace,
        SemanticStatusAnnouncement;
import '../../application/preferences_command_result.dart';
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
        final double cardPadding = ClockRhythmLayout.cardPaddingFor(width);
        final double scaledTitleLineHeight = MediaQuery.textScalerOf(
          context,
        ).scale(24);
        final int maximumTitleLines =
            width < ClockRhythmLayout.compactBreakpoint ? 2 : 3;
        final double cardExtent = math.max(
          176,
          cardPadding * 2 +
              ClockRhythmSpace.space8 +
              48 +
              scaledTitleLineHeight * maximumTitleLines,
        );
        return CustomScrollView(
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
                    ClockRhythmPageHeader(
                      eyebrow: copy.themeEyebrow,
                      title: copy.themeTitle,
                      description: copy.themeDescription,
                    ),
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
                                    .repairEffect(PreferencesRepairNeed.visual),
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
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: cardExtent,
                  crossAxisSpacing: ClockRhythmSpace.space16,
                  mainAxisSpacing: ClockRhythmSpace.space16,
                ),
                itemCount: ThemeCatalog.definitions.length,
                itemBuilder: (BuildContext context, int index) {
                  final ThemeDefinition definition =
                      ThemeCatalog.definitions[index];
                  final bool selected =
                      definition.id == state.preferences.theme;
                  return _ThemeChoice(
                    definition: definition,
                    name: _localizedThemeName(copy, definition.id),
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
        );
      },
    );
  }
}

String _localizedThemeName(AppLocalizations copy, ThemePreference preference) {
  return switch (preference) {
    ThemePreference.current => copy.themeCurrentName,
    ThemePreference.tokyoNight => copy.themeTokyoNightName,
    ThemePreference.oneDarkPro => copy.themeOneDarkProName,
    ThemePreference.catppuccinMocha => copy.themeCatppuccinMochaName,
    ThemePreference.nord => copy.themeNordName,
    ThemePreference.draculaOfficial => copy.themeDraculaName,
    ThemePreference.gruvbox => copy.themeGruvboxName,
    ThemePreference.monokaiPro => copy.themeNeonDuskName,
    ThemePreference.nightOwl => copy.themeNightOwlName,
    ThemePreference.synthwave84 => copy.themeSynthwave84Name,
    ThemePreference.ayuMirageDark => copy.themeAyuMirageDarkName,
  };
}

final class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.definition,
    required this.name,
    required this.selected,
    required this.selectedLabel,
    required this.selectLabel,
    required this.enabled,
    required this.maximumTitleLines,
    required this.onSelected,
  });

  final ThemeDefinition definition;
  final String name;
  final bool selected;
  final String selectedLabel;
  final String selectLabel;
  final bool enabled;
  final int maximumTitleLines;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: name,
      hint: selectLabel,
      child: ClockRhythmCard.unpadded(
        color: definition.surface.color,
        borderColor: selected ? definition.accentPrimary.color : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('theme-${definition.id.id}'),
          onTap: enabled && !selected ? onSelected : null,
          child: Padding(
            padding: EdgeInsets.all(
              ClockRhythmLayout.cardPaddingFor(
                MediaQuery.sizeOf(context).width,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        name,
                        maxLines: maximumTitleLines,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: definition.text.color),
                      ),
                    ),
                    if (selected)
                      Tooltip(
                        message: selectedLabel,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: definition.accentPrimary.color,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: ClockRhythmLayout.minimumInteractiveDimension,
                  child: Row(
                    children: definition.sourceSwatches
                        .map((ColorToken token) {
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: ClockRhythmSpace.space8,
                            ),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: token.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: definition.text.color.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
