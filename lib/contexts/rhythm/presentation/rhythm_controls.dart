import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/i18n/public.dart';
import '../../../shared/ui/public.dart'
    show ClockRhythmSpace, SemanticStatusAnnouncement, StableContentSlot;
import '../application/ports/legacy_coexistence_warning.dart';
import '../application/ports/rhythm_start_capability.dart';
import '../domain/rhythm_session.dart';
import 'rhythm_providers.dart';
import 'rhythm_view_state.dart';

final class RhythmControls extends ConsumerStatefulWidget {
  const RhythmControls({this.center, super.key});

  /// Content shown between the two round controls, such as session status.
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    // The primary slot swaps with the session, like Start/Pause in Clock.
    final Widget primary = switch (status) {
      RhythmSessionStatus.running => _RoundControl(
        controlKey: const ValueKey<String>('pause-rhythm'),
        label: copy.rhythmControlPause,
        alternateLabels: <String>[
          copy.rhythmControlStart,
          copy.rhythmControlResume,
        ],
        tone: _RoundTone.tinted(_pauseOrange, colors),
        onPressed: !state.isBusy && canPause
            ? () => ref.read(rhythmViewModelProvider.notifier).pause()
            : null,
      ),
      RhythmSessionStatus.paused => _RoundControl(
        controlKey: const ValueKey<String>('resume-rhythm'),
        label: copy.rhythmControlResume,
        alternateLabels: <String>[
          copy.rhythmControlStart,
          copy.rhythmControlPause,
        ],
        tone: _RoundTone.tinted(colors.secondary, colors),
        onPressed: !state.isBusy && canResume
            ? () => ref.read(rhythmViewModelProvider.notifier).resume()
            : null,
      ),
      RhythmSessionStatus.idle ||
      RhythmSessionStatus.stoppedForToday => _RoundControl(
        controlKey: const ValueKey<String>('start-rhythm'),
        label: copy.rhythmControlStart,
        alternateLabels: <String>[
          copy.rhythmControlPause,
          copy.rhythmControlResume,
        ],
        tone: _RoundTone.tinted(colors.secondary, colors),
        onPressed: !state.isBusy && !_isPreparingStart && canStart
            ? _startRhythm
            : null,
      ),
    };
    final Widget stop = _RoundControl(
      controlKey: const ValueKey<String>('stop-rhythm-for-today'),
      label: copy.rhythmControlStopForToday,
      tone: _RoundTone.neutral(colors),
      onPressed: !state.isBusy && canStop
          ? () => ref.read(rhythmViewModelProvider.notifier).stopForToday()
          : null,
    );
    final Widget? center = widget.center;
    return Column(
      key: const ValueKey<String>('rhythm-controls'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            stop,
            const SizedBox(width: ClockRhythmSpace.space12),
            Expanded(child: center ?? const SizedBox.shrink()),
            const SizedBox(width: ClockRhythmSpace.space12),
            primary,
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

const Color _pauseOrange = Color(0xFFFF9F0A);

final class _RoundTone {
  const _RoundTone({
    required this.fill,
    required this.ring,
    required this.label,
  });

  /// Apple's tinted style: a dim wash of the hue with a bright label.
  factory _RoundTone.tinted(Color hue, ColorScheme colors) {
    return _RoundTone(
      fill: Color.lerp(colors.surface, hue, 0.24)!,
      ring: Color.lerp(colors.surface, hue, 0.24)!,
      label: Color.lerp(hue, Colors.white, 0.18)!,
    );
  }

  factory _RoundTone.neutral(ColorScheme colors) {
    return _RoundTone(
      fill: colors.surfaceContainerHighest,
      ring: colors.surfaceContainerHighest,
      label: colors.onSurface,
    );
  }

  final Color fill;
  final Color ring;
  final Color label;
}

/// A round control with the double ring of the Clock app's timer buttons.
/// It grows into a capsule when its label needs more room.
final class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.controlKey,
    required this.label,
    required this.tone,
    required this.onPressed,
    this.alternateLabels = const <String>[],
  });

  static const double diameter = 84;

  final Key controlKey;
  final String label;
  final _RoundTone tone;
  final VoidCallback? onPressed;
  final List<String> alternateLabels;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final double opacity = enabled ? 1 : 0.4;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: tone.ring.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FilledButton(
          key: controlKey,
          onPressed: onPressed,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll<Size>(
              Size.square(diameter - 10),
            ),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: ClockRhythmSpace.space12),
            ),
            shape: const WidgetStatePropertyAll<OutlinedBorder>(
              StadiumBorder(),
            ),
            backgroundColor: WidgetStatePropertyAll<Color>(
              tone.fill.withValues(alpha: opacity),
            ),
            foregroundColor: WidgetStatePropertyAll<Color>(
              tone.label.withValues(alpha: enabled ? 1 : 0.55),
            ),
          ),
          child: StableContentSlot(
            labels: <String>[label, ...alternateLabels],
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
