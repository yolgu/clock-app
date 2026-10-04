import 'package:clock_rhythm/shared/ui/public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'dialog action retains text bounds while busy without hidden labels',
    (WidgetTester tester) async {
      final ValueNotifier<bool> busy = ValueNotifier<bool>(false);
      addTearDown(busy.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: busy,
              builder: (BuildContext context, bool value, _) => AlertDialog(
                actions: <Widget>[
                  FilledButton(
                    key: const ValueKey<String>('action'),
                    onPressed: value ? null : () {},
                    child: StableContentSlot(
                      labels: const <String>[
                        'Confirm import',
                        'Hidden sizing alternative',
                      ],
                      alignment: Alignment.center,
                      child: value
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('Confirm import'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder action = find.byKey(const ValueKey<String>('action'));
      final Rect before = tester.getRect(action);
      expect(find.text('Hidden sizing alternative'), findsNothing);
      busy.value = true;
      await tester.pump();
      expect(tester.getRect(action), before);
      expect(tester.takeException(), isNull);
    },
  );
}
