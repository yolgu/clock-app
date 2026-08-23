import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contexts/preferences/public_presentation.dart'
    show
        NotificationSoundPanel,
        PermissionStatusPanel,
        PreferencesPlatformCapabilities,
        RhythmSettingsPanel,
        preferencesPlatformCapabilitiesProvider;
import '../../contexts/rhythm/public_presentation.dart'
    show
        AnalogClock,
        DigitalClock,
        RhythmControls,
        RhythmStatusPanel,
        RhythmViewState,
        VisibleClockTicker,
        rhythmViewModelProvider;
import '../../shared/i18n/public.dart' show AppLocalizations;
import '../../shared/ui/public.dart'
    show AdaptiveContentLayout, AdaptiveContentMode;

final class ClockPage extends ConsumerWidget {
  const ClockPage({this.todayTodo, this.now = DateTime.now, super.key});

  final Widget? todayTodo;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RhythmViewState> rhythm = ref.watch(
      rhythmViewModelProvider,
    );
    final PreferencesPlatformCapabilities capabilities = ref.watch(
      preferencesPlatformCapabilitiesProvider,
    );
    return ListView(
      key: const PageStorageKey<String>('clock-page-scroll'),
      restorationId: 'clock_page_scroll',
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        rhythm.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context).failureDeliveryRecoveryRequired,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(rhythmViewModelProvider),
                  child: Text(AppLocalizations.of(context).actionRetry),
                ),
              ],
            ),
          ),
          data: (RhythmViewState state) => AdaptiveContentLayout(
            wideMinimumWidth: 760,
            builder: (BuildContext context, AdaptiveContentMode mode) {
              final Widget clock = VisibleClockTicker(
                now: now,
                notifyOnInitialVisibility: false,
                onBecameVisible: () {
                  ref.read(rhythmViewModelProvider.notifier).reconcile();
                },
                builder: (BuildContext context, DateTime current) {
                  return _ClockFace(now: current);
                },
              );
              final Widget session = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  RhythmStatusPanel(snapshot: state.snapshot),
                  const SizedBox(height: 12),
                  const RhythmControls(),
                ],
              );
              if (mode == AdaptiveContentMode.wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(child: Center(child: clock)),
                    const SizedBox(width: 24),
                    Expanded(child: session),
                  ],
                );
              }
              return Column(
                children: <Widget>[clock, const SizedBox(height: 16), session],
              );
            },
          ),
        ),
        if (todayTodo case final Widget todo) ...<Widget>[
          const SizedBox(height: 16),
          todo,
        ],
        const SizedBox(height: 16),
        RhythmSettingsPanel(now: now),
        const SizedBox(height: 16),
        const NotificationSoundPanel(),
        if (capabilities.showsDeliveryPermissions) ...<Widget>[
          const SizedBox(height: 16),
          const PermissionStatusPanel(),
        ],
      ],
    );
  }
}

final class _ClockFace extends StatelessWidget {
  const _ClockFace({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey<String>('clock-face-repaint-boundary'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnalogClock(now: now),
          const SizedBox(height: 12),
          DigitalClock(now: now),
        ],
      ),
    );
  }
}
