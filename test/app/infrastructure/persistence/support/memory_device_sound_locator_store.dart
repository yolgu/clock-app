import 'package:clock_rhythm/app/infrastructure/device_state/device_sound_locator_store.dart';

final class MemoryDeviceSoundLocatorStore implements DeviceSoundLocatorStore {
  DeviceSoundLocatorState state = DeviceSoundLocatorState.empty;
  Object? loadFailure;
  Object? saveFailure;
  Object? saveFailureAfterNextWrite;
  int saveCount = 0;

  @override
  Future<DeviceSoundLocatorState> load() async {
    final Object? failure = loadFailure;
    if (failure != null) {
      throw failure;
    }
    return state;
  }

  @override
  Future<void> save(DeviceSoundLocatorState nextState) async {
    saveCount += 1;
    final Object? failure = saveFailure;
    if (failure != null) {
      throw failure;
    }
    state = nextState;
    final Object? failureAfterWrite = saveFailureAfterNextWrite;
    saveFailureAfterNextWrite = null;
    if (failureAfterWrite != null) {
      throw failureAfterWrite;
    }
  }
}
