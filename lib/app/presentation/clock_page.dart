import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contexts/preferences/public_presentation.dart'
    show RhythmSettingsShortcut;
import '../../contexts/rhythm/public_presentation.dart'
    show
        AnalogClock,
        DailyRhythmBar,
        DigitalClock,
        RhythmControls,
        RhythmScheduleNote,
        RhythmStatusChip,
        RhythmViewState,
        VisibleClockTicker,
        rhythmViewModelProvider;
import '../../shared/i18n/public.dart'
    show AppLocalizations, LocalDateFormatter;
import '../../shared/ui/public.dart'
    show
        AdaptiveContentLayout,
        AdaptiveContentMode,
        ClockRhythmCard,
        ClockRhythmLayout,
        ClockRhythmPage,
        ClockRhythmSpace;

/// The rhythm home: a clock card (watch face, time, today's rhythm bar and
/// session controls) beside today's Todos. The session state sits in the
/// page heading; rhythm settings live in the Settings destination and are
/// reached through a summary row.
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
    final bool roomy = ClockRhythmPage.usesToolbar(context);
    final LocalDateFormatter dates = LocalDateFormatter(
      Localizations.localeOf(context),
    );
    final DateTime today = now();
    final RhythmViewState? state = rhythm.value;
    final Widget? statusChip = state == null
        ? null
        : RhythmStatusChip(snapshot: state.snapshot);
    final Widget? trailing = roomy
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                dates.formatFullDate(today),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (statusChip != null) ...<Widget>[
                const SizedBox(width: ClockRhythmSpace.space12),
                statusChip,
              ],
            ],
          )
        : statusChip;
    final VoidCallback? openSettings = onOpenSettings;
    final Widget? todo = todayTodo;
    return ClockRhythmPage(
      section: copy.clockPageEyebrow,
      title: copy.navigationClock,
      compactEyebrow:
          '${copy.clockPageEyebrow} · ${dates.formatMonthDayWeekday(today)}',
      trailing: trailing,
      builder: (BuildContext context, Widget lead) => ListView(
        key: const PageStorageKey<String>('clock-page-scroll'),
        restorationId: 'clock_page_scroll',
        padding: ClockRhythmLayout.pageInsetsFor(
          MediaQuery.sizeOf(context).width,
        ),
        children: <Widget>[
          lead,
          AdaptiveContentLayout(
            wideMinimumWidth: 800,
            builder: (BuildContext context, AdaptiveContentMode mode) {
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
                  roomy: roomy,
                  settingsShortcut: roomy && openSettings != null
                      ? RhythmSettingsShortcut(
                          onPressed: openSettings,
                          embedded: true,
                        )
                      : null,
                  onBecameVisible: () {
                    ref.read(rhythmViewModelProvider.notifier).reconcile();
                  },
                ),
              );
              final Widget primaryColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  hero,
                  if (!roomy && openSettings != null) ...<Widget>[
                    const SizedBox(height: ClockRhythmSpace.space12),
                    RhythmSettingsShortcut(onPressed: openSettings),
                  ],
                ],
              );
              if (mode == AdaptiveContentMode.wide && todo != null) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 10, child: primaryColumn),
                    const SizedBox(width: ClockRhythmSpace.space20),
                    Expanded(flex: 13, child: todo),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  primaryColumn,
                  if (todo != null) ...<Widget>[
                    SizedBox(
                      height: roomy
                          ? ClockRhythmSpace.space20
                          : ClockRhythmSpace.space12,
                    ),
                    todo,
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One card holding the watch face, the time, today's rhythm bar and the
/// session controls. A roomy card stacks a large face over the time under a
/// titled header; a compact card sets a small face beside the time.
final class _RhythmHero extends StatelessWidget {
  const _RhythmHero({
    required this.state,
    required this.now,
    required this.roomy,
    required this.settingsShortcut,
    required this.onBecameVisible,
  });

  final RhythmViewState state;
  final DateTime Function() now;
  final bool roomy;
  final Widget? settingsShortcut;
  final VoidCallback onBecameVisible;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets inset = roomy
        ? const EdgeInsets.symmetric(horizontal: ClockRhythmSpace.space24)
        : const EdgeInsets.symmetric(horizontal: 18);
    return ClockRhythmCard.unpadded(
      key: const ValueKey<String>('clock-face-card'),
      child: VisibleClockTicker(
        now: now,
        notifyOnInitialVisibility: false,
        onBecameVisible: onBecameVisible,
        builder: (BuildContext context, DateTime current) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (roomy) _CardHeader(now: current),
              Padding(
                padding: inset.copyWith(
                  top: roomy ? 22 : 18,
                  bottom: roomy ? ClockRhythmSpace.space20 : 16,
                ),
                child: roomy
                    ? _StackedClockFace(now: current)
                    : _InlineClockFace(now: current),
              ),
              Padding(
                padding: inset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DailyRhythmBar(
                      configuration: state.snapshot.configuration,
                      now: current,
                      compact: !roomy,
                    ),
                    const SizedBox(height: ClockRhythmSpace.space8),
                    RhythmScheduleNote(snapshot: state.snapshot),
                  ],
                ),
              ),
              Padding(
                padding: inset.copyWith(
                  top: roomy ? ClockRhythmSpace.space16 : 12,
                  bottom: roomy ? ClockRhythmSpace.space20 : 18,
                ),
                child: const RhythmControls(),
              ),
              ?settingsShortcut,
            ],
          );
        },
      ),
    );
  }
}

final class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  AppLocalizations.of(context).clockCurrentTimeTitle,
                  style: muted?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Text(now.timeZoneName, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

final class _StackedClockFace extends StatelessWidget {
  const _StackedClockFace({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey<String>('clock-face-repaint-boundary'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnalogClock(now: now),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: DigitalClock(now: now),
          ),
        ],
      ),
    );
  }
}

final class _InlineClockFace extends StatelessWidget {
  const _InlineClockFace({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final String seconds = now.second.toString().padLeft(2, '0');
    return RepaintBoundary(
      key: const ValueKey<String>('clock-face-repaint-boundary'),
      child: Row(
        children: <Widget>[
          AnalogClock(now: now, size: 112),
          const SizedBox(width: ClockRhythmSpace.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: DigitalClock(
                    now: now,
                    showsSeconds: false,
                    fontSize: 44,
                  ),
                ),
                ExcludeSemantics(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).clockSecondsWithZone(seconds, now.timeZoneName),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
