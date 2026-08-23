import '../../../rhythm/public_model.dart';
import '../../domain/rhythm_settings_draft.dart';

enum RhythmSettingsFieldError { focus, rest, start, end, dailyWindow }

final class RhythmSettingsFormResult {
  RhythmSettingsFormResult._({
    required this.draft,
    required Set<RhythmSettingsFieldError> errors,
  }) : errors = Set<RhythmSettingsFieldError>.unmodifiable(errors);

  final RhythmSettingsDraft? draft;
  final Set<RhythmSettingsFieldError> errors;

  bool get isValid => draft != null && errors.isEmpty;
}

final class RhythmSettingsFormInput {
  const RhythmSettingsFormInput({
    required this.focusMinutes,
    required this.restMinutes,
    required this.dailyStart,
    required this.dailyEnd,
    required this.autoStartEnabled,
  });

  final String focusMinutes;
  final String restMinutes;
  final String dailyStart;
  final String dailyEnd;
  final bool autoStartEnabled;

  RhythmSettingsFormResult validate() {
    final Set<RhythmSettingsFieldError> errors = <RhythmSettingsFieldError>{};
    final int? focus = int.tryParse(focusMinutes);
    final int? rest = int.tryParse(restMinutes);

    if (focus == null || !_isValidFocus(focus)) {
      errors.add(RhythmSettingsFieldError.focus);
    }
    if (rest == null || !_isValidRest(rest)) {
      errors.add(RhythmSettingsFieldError.rest);
    }
    if (!_isValidClockTime(dailyStart)) {
      errors.add(RhythmSettingsFieldError.start);
    }
    if (!_isValidClockTime(dailyEnd)) {
      errors.add(RhythmSettingsFieldError.end);
    }
    if (errors.isNotEmpty) {
      return RhythmSettingsFormResult._(draft: null, errors: errors);
    }

    try {
      final RhythmSettingsDraft draft = RhythmSettingsDraft.restore(
        RhythmSettingsDraftSnapshot(
          focusMinutes: focus!,
          restMinutes: rest!,
          dailyStart: dailyStart,
          dailyEnd: dailyEnd,
          autoStartEnabled: autoStartEnabled,
        ),
      );
      return RhythmSettingsFormResult._(
        draft: draft,
        errors: const <RhythmSettingsFieldError>{},
      );
    } on ArgumentError {
      return RhythmSettingsFormResult._(
        draft: null,
        errors: const <RhythmSettingsFieldError>{
          RhythmSettingsFieldError.dailyWindow,
        },
      );
    }
  }

  static bool _isValidFocus(int minutes) {
    try {
      DurationMinutes.focus(minutes);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  static bool _isValidRest(int minutes) {
    try {
      DurationMinutes.rest(minutes);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  static bool _isValidClockTime(String value) {
    try {
      ClockTime.parse(value);
      return true;
    } on ArgumentError {
      return false;
    }
  }
}
