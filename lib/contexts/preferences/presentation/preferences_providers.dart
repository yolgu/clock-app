import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences_actions.dart';
import 'preferences_platform_capabilities.dart';
import 'preferences_view_model.dart';
import 'preferences_view_state.dart';

final Provider<PreferencesActions> preferencesActionsProvider =
    Provider<PreferencesActions>((Ref ref) {
      throw StateError('PreferencesActions must be provided by composition.');
    });

final Provider<PreferencesPlatformCapabilities>
preferencesPlatformCapabilitiesProvider =
    Provider<PreferencesPlatformCapabilities>((Ref ref) {
      throw StateError(
        'PreferencesPlatformCapabilities must be provided by composition.',
      );
    });

final Provider<DeliveryPermissionActions?> deliveryPermissionActionsProvider =
    Provider<DeliveryPermissionActions?>((Ref ref) => null);

final AsyncNotifierProvider<PreferencesViewModel, PreferencesViewState>
preferencesViewModelProvider =
    AsyncNotifierProvider<PreferencesViewModel, PreferencesViewState>(
      PreferencesViewModel.new,
    );

final FutureProvider<DeliveryPermissionSnapshot?> deliveryPermissionProvider =
    FutureProvider<DeliveryPermissionSnapshot?>((Ref ref) async {
      final DeliveryPermissionActions? actions = ref.watch(
        deliveryPermissionActionsProvider,
      );
      return actions?.load();
    });
