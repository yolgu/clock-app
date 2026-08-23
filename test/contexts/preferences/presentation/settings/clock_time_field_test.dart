import 'package:clock_rhythm/contexts/preferences/presentation/settings/clock_time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('24-hour picker commits one canonical HH:mm draft value', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: '05:00',
    );
    addTearDown(controller.dispose);
    final List<String> changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClockTimeField(
            label: 'Focus window start',
            pickerTooltip: 'Select time',
            controller: controller,
            onChanged: changes.add,
            errorText: null,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('clock-time-picker-Focus window start'),
      ),
    );
    await tester.pumpAndSettle();
    final Finder picker = find.byType(TimePickerDialog);
    expect(MediaQuery.of(tester.element(picker)).alwaysUse24HourFormat, isTrue);

    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final Finder pickerFields = find.descendant(
      of: picker,
      matching: find.byType(TextField),
    );
    await tester.enterText(pickerFields.first, '23');
    await tester.enterText(pickerFields.last, '5');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(controller.text, '23:05');
    expect(changes, <String>['23:05']);
  });
}
