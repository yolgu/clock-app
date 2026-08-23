import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/i18n/public.dart';
import '../../../../shared/ui/public.dart' show SemanticStatusAnnouncement;
import '../../application/preferences_command_result.dart';
import '../../domain/theme_preference.dart';
import '../preferences_providers.dart';
import '../preferences_view_state.dart';
import 'theme_catalog.dart';

final class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final AsyncValue<PreferencesViewState> value = ref.watch(
      preferencesViewModelProvider,
    );
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) =>
          Center(child: Text(copy.messagePreferencesFailed)),
      data: (PreferencesViewState state) {
        return CustomScrollView(
          key: const PageStorageKey<String>('theme-page-scroll'),
          restorationId: 'theme_page_scroll',
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(copy.themeEyebrow),
                    Text(
                      copy.themeTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(copy.themeDescription),
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
                                    .read(preferencesViewModelProvider.notifier)
                                    .repairEffect(PreferencesRepairNeed.visual),
                          child: Text(copy.actionRetry),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 176,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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
                    onSelected: () {
                      ref
                          .read(preferencesViewModelProvider.notifier)
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
    required this.onSelected,
  });

  final ThemeDefinition definition;
  final String name;
  final bool selected;
  final String selectedLabel;
  final String selectLabel;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: name,
      hint: selectLabel,
      child: Card(
        color: definition.surface.color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('theme-${definition.id.id}'),
          onTap: enabled && !selected ? onSelected : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: definition.text.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      Tooltip(
                        message: selectedLabel,
                        child: Icon(
                          Icons.check_circle,
                          color: definition.accentPrimary.color,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: definition.sourceSwatches
                      .map((ColorToken token) {
                        return Expanded(
                          child: Container(height: 48, color: token.color),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
