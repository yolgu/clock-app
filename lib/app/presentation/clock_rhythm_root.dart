import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../contexts/preferences/public_model.dart'
    show
        AppearancePreference,
        LanguagePreference,
        ThemePreference,
        UserPreferences;
import '../../contexts/preferences/public_presentation.dart'
    show PreferencesDataState, preferencesDataControllerProvider;
import '../../features/data_transfer/public_presentation.dart'
    show DataTransferPhase, DataTransferState, dataTransferViewModelProvider;
import '../../shared/i18n/public.dart' show LanguageLocaleMapper;
import '../clock_rhythm_app.dart';

final class ClockRhythmRoot extends ConsumerWidget {
  const ClockRhythmRoot({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserPreferences preferences = ref
        .watch(preferencesDataControllerProvider)
        .maybeWhen(
          data: (PreferencesDataState state) => state.preferences,
          orElse: UserPreferences.defaults,
        );
    final DataTransferState transfer = ref.watch(dataTransferViewModelProvider);
    final LanguagePreference language = preferences.language;
    final ThemePreference theme = preferences.theme;
    final AppearancePreference appearance = preferences.appearance;
    return ClockRhythmApp(
      router: router,
      locale: LanguageLocaleMapper.localeForPreferenceId(language.id),
      theme: theme,
      appearance: appearance,
      mutationsSuspended: transfer.phase == DataTransferPhase.confirming,
    );
  }
}
