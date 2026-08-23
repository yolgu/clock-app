import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../contexts/preferences/public_model.dart' show ThemePreference;
import '../contexts/preferences/public_presentation.dart'
    show ClockRhythmTheme, ThemeCatalog;
import '../shared/i18n/public.dart' show AppLocalizations, LanguageLocaleMapper;

final class ClockRhythmApp extends StatelessWidget {
  const ClockRhythmApp({
    required this.router,
    this.locale = LanguageLocaleMapper.koreanLocale,
    this.theme = ThemePreference.current,
    this.mutationsSuspended = false,
    super.key,
  });

  final GoRouter router;
  final Locale locale;
  final ThemePreference theme;
  final bool mutationsSuspended;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'clock_rhythm_app',
      onGenerateTitle: (BuildContext context) {
        return AppLocalizations.of(context).appTitle;
      },
      locale: locale,
      supportedLocales: LanguageLocaleMapper.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ClockRhythmTheme.build(ThemeCatalog.resolve(theme)),
      builder: (BuildContext context, Widget? child) {
        return AbsorbPointer(
          absorbing: mutationsSuspended,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
