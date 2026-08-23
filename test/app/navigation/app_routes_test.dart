import 'package:clock_rhythm/app/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares the four stable main destination locations', () {
    expect(
      MainDestination.values.map((MainDestination value) => value.location),
      <String>['/clock', '/calendar', '/data', '/theme'],
    );
  });

  test('accepts only real Gregorian calendar query dates', () {
    expect(AppCalendarDate.parse('2028-02-29').iso8601, '2028-02-29');
    expect(() => AppCalendarDate.parse('2026-02-29'), throwsFormatException);
    expect(() => AppCalendarDate.parse('2026-2-01'), throwsFormatException);
    expect(() => AppCalendarDate.parse('2026-04-31'), throwsFormatException);
  });

  test('calendar route preserves the selected date in its URL', () {
    final AppRoute route = AppRoute.calendar(
      AppCalendarDate.parse('2026-08-22'),
    );

    expect(route.location, '/calendar?date=2026-08-22');
    expect(AppRoute.forDestination(MainDestination.clock).location, '/clock');
  });
}
