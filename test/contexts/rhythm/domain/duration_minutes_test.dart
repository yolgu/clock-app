import 'package:clock_rhythm/contexts/rhythm/domain/duration_minutes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts the Focus duration boundaries', () {
    expect(DurationMinutes.focus(1).minutes, 1);
    expect(DurationMinutes.focus(180).minutes, 180);
  });

  test('rejects a Focus duration outside 1 through 180 minutes', () {
    expect(() => DurationMinutes.focus(0), throwsArgumentError);
    expect(() => DurationMinutes.focus(181), throwsArgumentError);
  });

  test('accepts the Rest duration boundaries', () {
    expect(DurationMinutes.rest(1).minutes, 1);
    expect(DurationMinutes.rest(60).minutes, 60);
  });

  test('rejects a Rest duration outside 1 through 60 minutes', () {
    expect(() => DurationMinutes.rest(0), throwsArgumentError);
    expect(() => DurationMinutes.rest(61), throwsArgumentError);
  });

  test('compares durations by their minute value', () {
    expect(DurationMinutes.focus(10), DurationMinutes.rest(10));
    expect(
      DurationMinutes.focus(10).hashCode,
      DurationMinutes.rest(10).hashCode,
    );
  });
}
