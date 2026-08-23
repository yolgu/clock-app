import 'package:clock_rhythm/contexts/rhythm/public.dart';
import 'package:clock_rhythm/contexts/rhythm/public_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_rhythm_actions.dart';

void main() {
  test(
    'denied Start remains Idle and exposes the exact capability failure',
    () async {
      final FakeRhythmActions actions = FakeRhythmActions()
        ..startFailure = RhythmStartFailure.notificationPermission;
      final ProviderContainer container = _container(actions);
      addTearDown(container.dispose);
      await container.read(rhythmViewModelProvider.future);

      await container.read(rhythmViewModelProvider.notifier).start();

      final RhythmViewState state = container
          .read(rhythmViewModelProvider)
          .requireValue;
      expect(state.snapshot.status, RhythmSessionStatus.idle);
      expect(state.startFailure, RhythmStartFailure.notificationPermission);
      expect(state.announcementSequence, 0);
    },
  );

  test(
    'successful transitions announce each meaningful state change once',
    () async {
      final FakeRhythmActions actions = FakeRhythmActions();
      final ProviderContainer container = _container(actions);
      addTearDown(container.dispose);
      await container.read(rhythmViewModelProvider.future);
      final RhythmViewModel viewModel = container.read(
        rhythmViewModelProvider.notifier,
      );

      await viewModel.start();
      expect(
        container
            .read(rhythmViewModelProvider)
            .requireValue
            .announcementSequence,
        1,
      );
      await viewModel.reconcile();
      expect(
        container
            .read(rhythmViewModelProvider)
            .requireValue
            .announcementSequence,
        1,
      );
      await viewModel.pause();
      expect(
        container
            .read(rhythmViewModelProvider)
            .requireValue
            .announcementSequence,
        2,
      );
      await viewModel.resume();
      expect(
        container
            .read(rhythmViewModelProvider)
            .requireValue
            .announcementSequence,
        3,
      );
      await viewModel.stopForToday();
      final RhythmViewState stopped = container
          .read(rhythmViewModelProvider)
          .requireValue;
      expect(stopped.snapshot.status, RhythmSessionStatus.stoppedForToday);
      expect(stopped.announcementSequence, 4);
    },
  );

  test(
    'command failure keeps the observable snapshot and reports recovery',
    () async {
      final FakeRhythmActions actions = FakeRhythmActions(
        status: RhythmSessionStatus.running,
      )..commandFailure = StateError('delivery failed');
      final ProviderContainer container = _container(actions);
      addTearDown(container.dispose);
      final RhythmViewState initial = await container.read(
        rhythmViewModelProvider.future,
      );

      await container.read(rhythmViewModelProvider.notifier).pause();

      final RhythmViewState state = container
          .read(rhythmViewModelProvider)
          .requireValue;
      expect(state.snapshot, same(initial.snapshot));
      expect(state.commandFailed, isTrue);
    },
  );

  test('Start exception returns to Idle instead of staying busy', () async {
    final FakeRhythmActions actions = FakeRhythmActions()
      ..commandFailure = StateError('capability unavailable');
    final ProviderContainer container = _container(actions);
    addTearDown(container.dispose);
    await container.read(rhythmViewModelProvider.future);

    await container.read(rhythmViewModelProvider.notifier).start();

    final RhythmViewState state = container
        .read(rhythmViewModelProvider)
        .requireValue;
    expect(state.snapshot.status, RhythmSessionStatus.idle);
    expect(state.operation, RhythmOperation.idle);
    expect(state.startFailure, RhythmStartFailure.deliveryUnavailable);
  });

  test('failure action delegates without implicitly starting', () async {
    final FakeRhythmActions actions = FakeRhythmActions()
      ..startFailure = RhythmStartFailure.exactAlarmPermission;
    final ProviderContainer container = _container(actions);
    addTearDown(container.dispose);
    await container.read(rhythmViewModelProvider.future);
    final RhythmViewModel viewModel = container.read(
      rhythmViewModelProvider.notifier,
    );
    await viewModel.start();

    await viewModel.openStartFailureSettings();

    expect(actions.calls, <String>[
      'load',
      'start',
      'settings:exactAlarmPermission',
    ]);
    expect(
      container.read(rhythmViewModelProvider).requireValue.snapshot.status,
      RhythmSessionStatus.idle,
    );
  });
}

ProviderContainer _container(FakeRhythmActions actions) {
  return ProviderContainer(
    overrides: [rhythmActionsProvider.overrideWithValue(actions)],
  );
}
