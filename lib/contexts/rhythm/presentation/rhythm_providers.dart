import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/legacy_coexistence_warning.dart';
import 'rhythm_actions.dart';
import 'rhythm_view_model.dart';
import 'rhythm_view_state.dart';

final Provider<RhythmActions> rhythmActionsProvider = Provider<RhythmActions>((
  Ref ref,
) {
  throw StateError('RhythmActions must be provided by composition.');
});

final Provider<LegacyCoexistenceWarning> legacyCoexistenceWarningProvider =
    Provider<LegacyCoexistenceWarning>(
      (Ref ref) => const NoLegacyCoexistenceWarning(),
    );

final AsyncNotifierProvider<RhythmViewModel, RhythmViewState>
rhythmViewModelProvider =
    AsyncNotifierProvider<RhythmViewModel, RhythmViewState>(
      RhythmViewModel.new,
    );
