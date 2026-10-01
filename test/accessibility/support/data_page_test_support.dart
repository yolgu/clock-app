import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/preferences/public_presentation.dart';
import 'package:clock_rhythm/features/data_transfer/public.dart';
import 'package:clock_rhythm/features/data_transfer/public_presentation.dart';
import 'package:clock_rhythm/shared/i18n/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget buildDataPageTestApp({TextScaler textScaler = TextScaler.noScaling}) {
  return ProviderScope(
    overrides: [
      dataTransferActionsProvider.overrideWithValue(
        const NoOpDataTransferActions(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: LanguageLocaleMapper.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ClockRhythmTheme.build(
        ThemeCatalog.resolve(ThemePreference.current),
        platform: TargetPlatform.android,
      ),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const Scaffold(body: DataPage()),
    ),
  );
}

final class NoOpDataTransferActions implements DataTransferActions {
  const NoOpDataTransferActions();

  @override
  Future<ConfirmBackupImportResult> confirmImport(
    PreparedBackupImport prepared,
  ) async {
    return const ConfirmBackupImportResult(autoStartRepairRequired: false);
  }

  @override
  Future<bool> exportBackup() async => false;

  @override
  Future<PreparedBackupImport?> prepareImport() async => null;

  @override
  Future<void> refreshAfterImport() async {}
}
