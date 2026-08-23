import 'package:clock_rhythm/contexts/preferences/infrastructure/windows/windows_auto_start_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowsAutoStartAdapter', () {
    test(
      'returns desired and actual state after native synchronization',
      () async {
        final FakeWindowsAutoStartNativeGateway native =
            FakeWindowsAutoStartNativeGateway(
              const WindowsAutoStartNativeResult.synchronized(
                desiredEnabled: true,
                actualEnabled: true,
              ),
            );
        final WindowsAutoStartAdapter adapter = WindowsAutoStartAdapter(
          nativeGateway: native,
        );

        final reconciliation = await adapter.reconcile(desiredEnabled: true);

        expect(reconciliation.desiredEnabled, isTrue);
        expect(reconciliation.actualEnabled, isTrue);
        expect(reconciliation.repairRequired, isFalse);
        expect(native.desiredValues, <bool>[true]);
      },
    );

    test(
      'maps a packaged user-disabled task to an explicit repair need',
      () async {
        final WindowsAutoStartAdapter adapter = WindowsAutoStartAdapter(
          nativeGateway: FakeWindowsAutoStartNativeGateway(
            const WindowsAutoStartNativeResult.needsUserAction(
              desiredEnabled: true,
              actualEnabled: false,
            ),
          ),
        );

        final reconciliation = await adapter.reconcile(desiredEnabled: true);

        expect(reconciliation.actualEnabled, isFalse);
        expect(reconciliation.repairRequired, isTrue);
      },
    );

    test(
      'maps an indeterminate actual state to an explicit repair need',
      () async {
        final WindowsAutoStartAdapter adapter = WindowsAutoStartAdapter(
          nativeGateway: FakeWindowsAutoStartNativeGateway(
            const WindowsAutoStartNativeResult.needsUserAction(
              desiredEnabled: false,
              actualEnabled: null,
            ),
          ),
        );

        final reconciliation = await adapter.reconcile(desiredEnabled: false);

        expect(reconciliation.actualEnabled, isNull);
        expect(reconciliation.repairRequired, isTrue);
      },
    );

    test(
      'preserves a typed native error instead of reporting false success',
      () async {
        final WindowsAutoStartAdapter adapter = WindowsAutoStartAdapter(
          nativeGateway: FakeWindowsAutoStartNativeGateway(
            const WindowsAutoStartNativeResult.error(
              desiredEnabled: true,
              errorCode: 'registryAccessDenied',
            ),
          ),
        );

        await expectLater(
          adapter.reconcile(desiredEnabled: true),
          throwsA(
            isA<WindowsAutoStartException>().having(
              (WindowsAutoStartException error) => error.code,
              'code',
              'registryAccessDenied',
            ),
          ),
        );
      },
    );

    test('rejects a native response for another desired state', () async {
      final WindowsAutoStartAdapter adapter = WindowsAutoStartAdapter(
        nativeGateway: FakeWindowsAutoStartNativeGateway(
          const WindowsAutoStartNativeResult.synchronized(
            desiredEnabled: false,
            actualEnabled: false,
          ),
        ),
      );

      await expectLater(
        adapter.reconcile(desiredEnabled: true),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test(
    'method channel gateway validates the four-field native result',
    () async {
      const MethodChannel channel = MethodChannel(
        'clock_rhythm/windows_auto_start_test',
      );
      MethodCall? receivedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            receivedCall = call;
            return <String, Object?>{
              'desiredEnabled': true,
              'actualEnabled': false,
              'status': 'needsUserAction',
              'errorCode': null,
            };
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final MethodChannelWindowsAutoStartNativeGateway gateway =
          MethodChannelWindowsAutoStartNativeGateway(channel: channel);

      final WindowsAutoStartNativeResult result = await gateway.reconcile(
        desiredEnabled: true,
      );

      expect(receivedCall?.method, 'reconcile');
      expect(receivedCall?.arguments, <String, bool>{'desiredEnabled': true});
      expect(result.status, WindowsAutoStartNativeStatus.needsUserAction);
      expect(result.desiredEnabled, isTrue);
      expect(result.actualEnabled, isFalse);
    },
  );
}

final class FakeWindowsAutoStartNativeGateway
    implements WindowsAutoStartNativeGateway {
  FakeWindowsAutoStartNativeGateway(this.result);

  final WindowsAutoStartNativeResult result;
  final List<bool> desiredValues = <bool>[];

  @override
  Future<WindowsAutoStartNativeResult> reconcile({
    required bool desiredEnabled,
  }) async {
    desiredValues.add(desiredEnabled);
    return result;
  }
}
