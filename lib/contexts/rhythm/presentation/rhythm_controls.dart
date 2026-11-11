import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart'
    show ClockRhythmSpace, LineGlyph, LineIcon, SemanticStatusAnnouncement;
import '../application/ports/legacy_coexistence_warning.dart';
import '../application/ports/rhythm_start_capability.dart';
import '../domain/rhythm_session.dart';
import 'rhythm_providers.dart';
import 'rhythm_view_state.dart';

final class RhythmControls extends ConsumerStatefulWidget {
  const RhythmControls({this.center, super.key});

  /// Content shown above the commands, such as session status.
  final Widget? center;

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
    // The primary slot swaps with the session; it keeps its place and width
    // so the pointer never has to chase the next command.
    final Widget primary = switch (status) {
      RhythmSessionStatus.running => _PrimaryControl(
        controlKey: const ValueKey<String>('pause-rhythm'),
        icon: LineGlyph.pause,
        label: copy.rhythmControlPause,
        onPressed: !state.isBusy && canPause
            ? () => ref.read(rhythmViewModelProvider.notifier).pause()
            : null,
      ),
      RhythmSessionStatus.paused => _PrimaryControl(
        controlKey: const ValueKey<String>('resume-rhythm'),
        icon: LineGlyph.play,
        label: copy.rhythmControlResume,
        onPressed: !state.isBusy && canResume
            ? () => ref.read(rhythmViewModelProvider.notifier).resume()
            : null,
      ),
      RhythmSessionStatus.idle ||
      RhythmSessionStatus.stoppedForToday => _PrimaryControl(
        controlKey: const ValueKey<String>('start-rhythm'),
        icon: LineGlyph.play,
        label: copy.rhythmControlStart,
        onPressed: !state.isBusy && !_isPreparingStart && canStart
            ? _startRhythm
            : null,
      ),
    };
    final Widget stop = OutlinedButton(
      key: const ValueKey<String>('stop-rhythm-for-today'),
      onPressed: !state.isBusy && canStop
          ? () => ref.read(rhythmViewModelProvider.notifier).stopForToday()
          : null,
      child: Text(copy.rhythmControlStopForToday),
    );
    final Widget? center = widget.center;
    return Column(
      key: const ValueKey<String>('rhythm-controls'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (center != null) ...<Widget>[
          Center(child: center),
          const SizedBox(height: ClockRhythmSpace.space16),
        ],
        Row(
          children: <Widget>[
            stop,
            const SizedBox(width: ClockRhythmSpace.space12),
            Expanded(child: primary),
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
      leading: const LineIcon(LineGlyph.warning),
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

/// The session's main command: a filled accent button that takes the room
/// the secondary command leaves.
final class _PrimaryControl extends StatelessWidget {
  const _PrimaryControl({
    required this.controlKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Key controlKey;
  final LineGlyph icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: controlKey,
      onPressed: onPressed,
      icon: LineIcon(icon, size: 18),
      label: Text(label),
    );
  }
}
