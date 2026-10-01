import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contexts/preferences/public_presentation.dart'
    show RhythmSettingsShortcut;
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
    show
        AdaptiveContentLayout,
        AdaptiveContentMode,
        ClockRhythmCard,
        ClockRhythmLayout,
        ClockRhythmPageHeader,
        ClockRhythmSpace;

/// The rhythm home: a Clock-app style hero (watch face, time, session status
/// and round controls) beside today's Todos. Rhythm settings live in the
/// Settings destination and are reached through a summary row.
final class ClockPage extends ConsumerWidget {
  const ClockPage({
    this.todayTodo,
    this.onOpenSettings,
    this.now = DateTime.now,
    super.key,
  });

  final Widget? todayTodo;
  final VoidCallback? onOpenSettings;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations copy = AppLocalizations.of(context);
    final AsyncValue<RhythmViewState> rhythm = ref.watch(
      rhythmViewModelProvider,
    );
    final VoidCallback? openSettings = onOpenSettings;
    final Widget? todo = todayTodo;
    return ListView(
      key: const PageStorageKey<String>('clock-page-scroll'),
      restorationId: 'clock_page_scroll',
      padding: ClockRhythmLayout.pageInsetsFor(
        MediaQuery.sizeOf(context).width,
      ),
      children: <Widget>[
        ClockRhythmPageHeader(
          eyebrow: copy.clockPageEyebrow,
          title: copy.navigationClock,
        ),
        AdaptiveContentLayout(
          wideMinimumWidth: 860,
          builder: (BuildContext context, AdaptiveContentMode mode) {
            final bool wide = mode == AdaptiveContentMode.wide;
            final Widget hero = rhythm.when(
              loading: () => const ClockRhythmCard.padded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object error, StackTrace stackTrace) =>
                  ClockRhythmCard.padded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(copy.failureDeliveryRecoveryRequired),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(rhythmViewModelProvider),
                          child: Text(copy.actionRetry),
                        ),
                      ],
                    ),
                  ),
              data: (RhythmViewState state) => _RhythmHero(
                state: state,
                now: now,
                faceSize: wide ? 300 : 248,
                onBecameVisible: () {
                  ref.read(rhythmViewModelProvider.notifier).reconcile();
                },
              ),
            );
            final Widget primaryColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                hero,
                if (openSettings != null) ...<Widget>[
                  const SizedBox(height: ClockRhythmSpace.space16),
                  RhythmSettingsShortcut(onPressed: openSettings),
                ],
              ],
            );
            if (wide && todo != null) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 11, child: primaryColumn),
                  const SizedBox(width: ClockRhythmSpace.space20),
                  Expanded(flex: 10, child: todo),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                primaryColumn,
                if (todo != null) ...<Widget>[
                  const SizedBox(height: ClockRhythmSpace.space20),
                  todo,
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One deep card holding the watch face, the digital time and the session
/// controls, lit from above with a soft gradient.
final class _RhythmHero extends StatelessWidget {
  const _RhythmHero({
    required this.state,
    required this.now,
    required this.faceSize,
    required this.onBecameVisible,
  });

  final RhythmViewState state;
  final DateTime Function() now;
  final double faceSize;
  final VoidCallback onBecameVisible;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ClockRhythmCard.unpadded(
      key: const ValueKey<String>('clock-face-card'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[colors.surfaceContainerHigh, colors.surface],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ClockRhythmSpace.space20,
            ClockRhythmSpace.space32,
            ClockRhythmSpace.space20,
            ClockRhythmSpace.space20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: VisibleClockTicker(
                  now: now,
                  notifyOnInitialVisibility: false,
                  onBecameVisible: onBecameVisible,
                  builder: (BuildContext context, DateTime current) {
                    return _ClockFace(now: current, size: faceSize);
                  },
                ),
              ),
              const SizedBox(height: ClockRhythmSpace.space24),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: RhythmControls(
                    center: RhythmStatusPanel(snapshot: state.snapshot),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ClockFace extends StatelessWidget {
  const _ClockFace({required this.now, required this.size});

  final DateTime now;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey<String>('clock-face-repaint-boundary'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnalogClock(now: now, size: size),
          const SizedBox(height: ClockRhythmSpace.space16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: DigitalClock(now: now),
          ),
        ],
      ),
    );
  }
}
