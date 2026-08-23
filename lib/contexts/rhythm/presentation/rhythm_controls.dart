import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart' show SemanticStatusAnnouncement;
import '../application/ports/legacy_coexistence_warning.dart';
import '../application/ports/rhythm_start_capability.dart';
import '../domain/rhythm_session.dart';
import 'rhythm_providers.dart';
import 'rhythm_view_state.dart';

final class RhythmControls extends ConsumerStatefulWidget {
  const RhythmControls({super.key});

  @override
  ConsumerState<RhythmControls> createState() => _RhythmControlsState();
}

final class _RhythmControlsState extends ConsumerState<RhythmControls> {
  bool _isPreparingStart = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    ref.listen<AsyncValue<RhythmViewState>>(rhythmViewModelProvider, (
      AsyncValue<RhythmViewState>? previous,
      AsyncValue<RhythmViewState> next,
    ) {
      final RhythmViewState? currentState = next.value;
      if (currentState == null ||
          currentState.announcementSequence ==
              previous?.value?.announcementSequence) {
        return;
      }
      final String? announcement = _announcement(copy, currentState);
      if (announcement != null) {
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            announcement,
            Directionality.of(context),
          ).catchError((Object _) {}),
        );
      }
    });
    final AsyncValue<RhythmViewState> value = ref.watch(
      rhythmViewModelProvider,
    );
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Text(copy.failureUnknown),
      data: (RhythmViewState state) => _buildControls(context, ref, state),
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    RhythmViewState state,
  ) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final RhythmSessionStatus status = state.snapshot.status;
    final bool canStart =
        status == RhythmSessionStatus.idle ||
        status == RhythmSessionStatus.stoppedForToday;
    final bool canPause = status == RhythmSessionStatus.running;
    final bool canResume = status == RhythmSessionStatus.paused;
    final bool canStop =
        status == RhythmSessionStatus.running ||
        status == RhythmSessionStatus.paused;
    return Column(
      key: const ValueKey<String>('rhythm-controls'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              key: const ValueKey<String>('start-rhythm'),
              onPressed: !state.isBusy && !_isPreparingStart && canStart
                  ? _startRhythm
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(copy.rhythmControlStart),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('pause-rhythm'),
              onPressed: !state.isBusy && canPause
                  ? () => ref.read(rhythmViewModelProvider.notifier).pause()
                  : null,
              icon: const Icon(Icons.pause),
              label: Text(copy.rhythmControlPause),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('resume-rhythm'),
              onPressed: !state.isBusy && canResume
                  ? () => ref.read(rhythmViewModelProvider.notifier).resume()
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(copy.rhythmControlResume),
            ),
            OutlinedButton.icon(
              key: const ValueKey<String>('stop-rhythm-for-today'),
              onPressed: !state.isBusy && canStop
                  ? () => ref
                        .read(rhythmViewModelProvider.notifier)
                        .stopForToday()
                  : null,
              icon: const Icon(Icons.event_busy),
              label: Text(copy.rhythmControlStopForToday),
            ),
          ],
        ),
        if (state.startFailure != null)
          _StartFailure(
            failure: state.startFailure!,
            onAction: () {
              if (state.startFailure ==
                  RhythmStartFailure.deliveryUnavailable) {
                ref.read(rhythmViewModelProvider.notifier).start();
              } else {
                ref
                    .read(rhythmViewModelProvider.notifier)
                    .openStartFailureSettings();
              }
            },
          ),
        if (state.commandFailed)
          SemanticStatusAnnouncement(
            message: copy.failureDeliveryRecoveryRequired,
            child: Text(
              copy.failureDeliveryRecoveryRequired,
              key: const ValueKey<String>('rhythm-command-failure'),
            ),
          ),
      ],
    );
  }

  Future<void> _startRhythm() async {
    if (_isPreparingStart) {
      return;
    }
    setState(() {
      _isPreparingStart = true;
    });
    try {
      final LegacyCoexistenceWarning warning = ref.read(
        legacyCoexistenceWarningProvider,
      );
      if (await warning.shouldWarnBeforeStart()) {
        if (!mounted || !await _confirmLegacyAppStopped()) {
          return;
        }
        await warning.acknowledge();
      }
      if (mounted) {
        await ref.read(rhythmViewModelProvider.notifier).start();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingStart = false;
        });
      }
    }
  }

  Future<bool> _confirmLegacyAppStopped() async {
    final AppLocalizations copy = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          key: const ValueKey<String>('legacy-coexistence-warning'),
          title: Text(copy.legacyCoexistenceWarningTitle),
          content: Text(copy.legacyCoexistenceWarningDescription),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(copy.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(copy.legacyCoexistenceWarningConfirm),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  String? _announcement(AppLocalizations copy, RhythmViewState state) {
    return switch (state.announcement) {
      RhythmAnnouncement.running => copy.announcementRhythmRunning,
      RhythmAnnouncement.paused => copy.announcementRhythmPaused,
      RhythmAnnouncement.resumed => copy.announcementRhythmResumed,
      RhythmAnnouncement.stoppedForToday =>
        copy.announcementRhythmStoppedForToday,
      null => null,
    };
  }
}

final class _StartFailure extends StatelessWidget {
  const _StartFailure({required this.failure, required this.onAction});

  final RhythmStartFailure failure;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final String description = switch (failure) {
      RhythmStartFailure.notificationPermission =>
        copy.failureNotificationPermissionRequired,
      RhythmStartFailure.exactAlarmPermission =>
        copy.failureExactAlarmPermissionRequired,
      RhythmStartFailure.notificationAndExactAlarmPermission =>
        copy.failureNotificationAndExactAlarmPermissionRequired,
      RhythmStartFailure.deliveryUnavailable =>
        copy.failureDeliveryRecoveryRequired,
    };
    return ListTile(
      key: const ValueKey<String>('rhythm-start-failure'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.warning_amber),
      title: SemanticStatusAnnouncement(
        message: description,
        child: Text(description),
      ),
      trailing: TextButton(
        onPressed: onAction,
        child: Text(
          failure == RhythmStartFailure.deliveryUnavailable
              ? copy.actionRetry
              : copy.actionOpenSettings,
        ),
      ),
    );
  }
}
