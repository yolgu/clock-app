// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_rhythm_database.dart';

// ignore_for_file: type=lint
class $PreferenceRecordsTable extends PreferenceRecords
    with TableInfo<$PreferenceRecordsTable, PreferenceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferenceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(1),
  );
  static const VerificationMeta _focusMinutesMeta = const VerificationMeta(
    'focusMinutes',
  );
  @override
  late final GeneratedColumn<int> focusMinutes = GeneratedColumn<int>(
    'focus_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restMinutesMeta = const VerificationMeta(
    'restMinutes',
  );
  @override
  late final GeneratedColumn<int> restMinutes = GeneratedColumn<int>(
    'rest_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyStartMeta = const VerificationMeta(
    'dailyStart',
  );
  @override
  late final GeneratedColumn<String> dailyStart = GeneratedColumn<String>(
    'daily_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyEndMeta = const VerificationMeta(
    'dailyEnd',
  );
  @override
  late final GeneratedColumn<String> dailyEnd = GeneratedColumn<String>(
    'daily_end',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autoStartEnabledMeta = const VerificationMeta(
    'autoStartEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoStartEnabled = GeneratedColumn<bool>(
    'auto_start_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_start_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _soundModeMeta = const VerificationMeta(
    'soundMode',
  );
  @override
  late final GeneratedColumn<String> soundMode = GeneratedColumn<String>(
    'sound_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customFileNameMeta = const VerificationMeta(
    'customFileName',
  );
  @override
  late final GeneratedColumn<String> customFileName = GeneratedColumn<String>(
    'custom_file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soundVolumeMeta = const VerificationMeta(
    'soundVolume',
  );
  @override
  late final GeneratedColumn<double> soundVolume = GeneratedColumn<double>(
    'sound_volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutedFromModeMeta = const VerificationMeta(
    'mutedFromMode',
  );
  @override
  late final GeneratedColumn<String> mutedFromMode = GeneratedColumn<String>(
    'muted_from_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mutedFromFileNameMeta = const VerificationMeta(
    'mutedFromFileName',
  );
  @override
  late final GeneratedColumn<String> mutedFromFileName =
      GeneratedColumn<String>(
        'muted_from_file_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialSetupCompletedMeta =
      const VerificationMeta('initialSetupCompleted');
  @override
  late final GeneratedColumn<bool> initialSetupCompleted =
      GeneratedColumn<bool>(
        'initial_setup_completed',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("initial_setup_completed" IN (0, 1))',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    focusMinutes,
    restMinutes,
    dailyStart,
    dailyEnd,
    autoStartEnabled,
    soundMode,
    customFileName,
    soundVolume,
    mutedFromMode,
    mutedFromFileName,
    language,
    theme,
    initialSetupCompleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preference_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('focus_minutes')) {
      context.handle(
        _focusMinutesMeta,
        focusMinutes.isAcceptableOrUnknown(
          data['focus_minutes']!,
          _focusMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_focusMinutesMeta);
    }
    if (data.containsKey('rest_minutes')) {
      context.handle(
        _restMinutesMeta,
        restMinutes.isAcceptableOrUnknown(
          data['rest_minutes']!,
          _restMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_restMinutesMeta);
    }
    if (data.containsKey('daily_start')) {
      context.handle(
        _dailyStartMeta,
        dailyStart.isAcceptableOrUnknown(data['daily_start']!, _dailyStartMeta),
      );
    } else if (isInserting) {
      context.missing(_dailyStartMeta);
    }
    if (data.containsKey('daily_end')) {
      context.handle(
        _dailyEndMeta,
        dailyEnd.isAcceptableOrUnknown(data['daily_end']!, _dailyEndMeta),
      );
    } else if (isInserting) {
      context.missing(_dailyEndMeta);
    }
    if (data.containsKey('auto_start_enabled')) {
      context.handle(
        _autoStartEnabledMeta,
        autoStartEnabled.isAcceptableOrUnknown(
          data['auto_start_enabled']!,
          _autoStartEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_autoStartEnabledMeta);
    }
    if (data.containsKey('sound_mode')) {
      context.handle(
        _soundModeMeta,
        soundMode.isAcceptableOrUnknown(data['sound_mode']!, _soundModeMeta),
      );
    } else if (isInserting) {
      context.missing(_soundModeMeta);
    }
    if (data.containsKey('custom_file_name')) {
      context.handle(
        _customFileNameMeta,
        customFileName.isAcceptableOrUnknown(
          data['custom_file_name']!,
          _customFileNameMeta,
        ),
      );
    }
    if (data.containsKey('sound_volume')) {
      context.handle(
        _soundVolumeMeta,
        soundVolume.isAcceptableOrUnknown(
          data['sound_volume']!,
          _soundVolumeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_soundVolumeMeta);
    }
    if (data.containsKey('muted_from_mode')) {
      context.handle(
        _mutedFromModeMeta,
        mutedFromMode.isAcceptableOrUnknown(
          data['muted_from_mode']!,
          _mutedFromModeMeta,
        ),
      );
    }
    if (data.containsKey('muted_from_file_name')) {
      context.handle(
        _mutedFromFileNameMeta,
        mutedFromFileName.isAcceptableOrUnknown(
          data['muted_from_file_name']!,
          _mutedFromFileNameMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeMeta);
    }
    if (data.containsKey('initial_setup_completed')) {
      context.handle(
        _initialSetupCompletedMeta,
        initialSetupCompleted.isAcceptableOrUnknown(
          data['initial_setup_completed']!,
          _initialSetupCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialSetupCompletedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  PreferenceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenceRecord(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      focusMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_minutes'],
      )!,
      restMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_minutes'],
      )!,
      dailyStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_start'],
      )!,
      dailyEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_end'],
      )!,
      autoStartEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_start_enabled'],
      )!,
      soundMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_mode'],
      )!,
      customFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_file_name'],
      ),
      soundVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sound_volume'],
      )!,
      mutedFromMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muted_from_mode'],
      ),
      mutedFromFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muted_from_file_name'],
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      initialSetupCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}initial_setup_completed'],
      )!,
    );
  }

  @override
  $PreferenceRecordsTable createAlias(String alias) {
    return $PreferenceRecordsTable(attachedDatabase, alias);
  }
}

class PreferenceRecord extends DataClass
    implements Insertable<PreferenceRecord> {
  final int singletonId;
  final int focusMinutes;
  final int restMinutes;
  final String dailyStart;
  final String dailyEnd;
  final bool autoStartEnabled;
  final String soundMode;
  final String? customFileName;
  final double soundVolume;
  final String? mutedFromMode;
  final String? mutedFromFileName;
  final String language;
  final String theme;
  final bool initialSetupCompleted;
  const PreferenceRecord({
    required this.singletonId,
    required this.focusMinutes,
    required this.restMinutes,
    required this.dailyStart,
    required this.dailyEnd,
    required this.autoStartEnabled,
    required this.soundMode,
    this.customFileName,
    required this.soundVolume,
    this.mutedFromMode,
    this.mutedFromFileName,
    required this.language,
    required this.theme,
    required this.initialSetupCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    map['focus_minutes'] = Variable<int>(focusMinutes);
    map['rest_minutes'] = Variable<int>(restMinutes);
    map['daily_start'] = Variable<String>(dailyStart);
    map['daily_end'] = Variable<String>(dailyEnd);
    map['auto_start_enabled'] = Variable<bool>(autoStartEnabled);
    map['sound_mode'] = Variable<String>(soundMode);
    if (!nullToAbsent || customFileName != null) {
      map['custom_file_name'] = Variable<String>(customFileName);
    }
    map['sound_volume'] = Variable<double>(soundVolume);
    if (!nullToAbsent || mutedFromMode != null) {
      map['muted_from_mode'] = Variable<String>(mutedFromMode);
    }
    if (!nullToAbsent || mutedFromFileName != null) {
      map['muted_from_file_name'] = Variable<String>(mutedFromFileName);
    }
    map['language'] = Variable<String>(language);
    map['theme'] = Variable<String>(theme);
    map['initial_setup_completed'] = Variable<bool>(initialSetupCompleted);
    return map;
  }

  PreferenceRecordsCompanion toCompanion(bool nullToAbsent) {
    return PreferenceRecordsCompanion(
      singletonId: Value(singletonId),
      focusMinutes: Value(focusMinutes),
      restMinutes: Value(restMinutes),
      dailyStart: Value(dailyStart),
      dailyEnd: Value(dailyEnd),
      autoStartEnabled: Value(autoStartEnabled),
      soundMode: Value(soundMode),
      customFileName: customFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(customFileName),
      soundVolume: Value(soundVolume),
      mutedFromMode: mutedFromMode == null && nullToAbsent
          ? const Value.absent()
          : Value(mutedFromMode),
      mutedFromFileName: mutedFromFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(mutedFromFileName),
      language: Value(language),
      theme: Value(theme),
      initialSetupCompleted: Value(initialSetupCompleted),
    );
  }

  factory PreferenceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenceRecord(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      focusMinutes: serializer.fromJson<int>(json['focusMinutes']),
      restMinutes: serializer.fromJson<int>(json['restMinutes']),
      dailyStart: serializer.fromJson<String>(json['dailyStart']),
      dailyEnd: serializer.fromJson<String>(json['dailyEnd']),
      autoStartEnabled: serializer.fromJson<bool>(json['autoStartEnabled']),
      soundMode: serializer.fromJson<String>(json['soundMode']),
      customFileName: serializer.fromJson<String?>(json['customFileName']),
      soundVolume: serializer.fromJson<double>(json['soundVolume']),
      mutedFromMode: serializer.fromJson<String?>(json['mutedFromMode']),
      mutedFromFileName: serializer.fromJson<String?>(
        json['mutedFromFileName'],
      ),
      language: serializer.fromJson<String>(json['language']),
      theme: serializer.fromJson<String>(json['theme']),
      initialSetupCompleted: serializer.fromJson<bool>(
        json['initialSetupCompleted'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'focusMinutes': serializer.toJson<int>(focusMinutes),
      'restMinutes': serializer.toJson<int>(restMinutes),
      'dailyStart': serializer.toJson<String>(dailyStart),
      'dailyEnd': serializer.toJson<String>(dailyEnd),
      'autoStartEnabled': serializer.toJson<bool>(autoStartEnabled),
      'soundMode': serializer.toJson<String>(soundMode),
      'customFileName': serializer.toJson<String?>(customFileName),
      'soundVolume': serializer.toJson<double>(soundVolume),
      'mutedFromMode': serializer.toJson<String?>(mutedFromMode),
      'mutedFromFileName': serializer.toJson<String?>(mutedFromFileName),
      'language': serializer.toJson<String>(language),
      'theme': serializer.toJson<String>(theme),
      'initialSetupCompleted': serializer.toJson<bool>(initialSetupCompleted),
    };
  }

  PreferenceRecord copyWith({
    int? singletonId,
    int? focusMinutes,
    int? restMinutes,
    String? dailyStart,
    String? dailyEnd,
    bool? autoStartEnabled,
    String? soundMode,
    Value<String?> customFileName = const Value.absent(),
    double? soundVolume,
    Value<String?> mutedFromMode = const Value.absent(),
    Value<String?> mutedFromFileName = const Value.absent(),
    String? language,
    String? theme,
    bool? initialSetupCompleted,
  }) => PreferenceRecord(
    singletonId: singletonId ?? this.singletonId,
    focusMinutes: focusMinutes ?? this.focusMinutes,
    restMinutes: restMinutes ?? this.restMinutes,
    dailyStart: dailyStart ?? this.dailyStart,
    dailyEnd: dailyEnd ?? this.dailyEnd,
    autoStartEnabled: autoStartEnabled ?? this.autoStartEnabled,
    soundMode: soundMode ?? this.soundMode,
    customFileName: customFileName.present
        ? customFileName.value
        : this.customFileName,
    soundVolume: soundVolume ?? this.soundVolume,
    mutedFromMode: mutedFromMode.present
        ? mutedFromMode.value
        : this.mutedFromMode,
    mutedFromFileName: mutedFromFileName.present
        ? mutedFromFileName.value
        : this.mutedFromFileName,
    language: language ?? this.language,
    theme: theme ?? this.theme,
    initialSetupCompleted: initialSetupCompleted ?? this.initialSetupCompleted,
  );
  PreferenceRecord copyWithCompanion(PreferenceRecordsCompanion data) {
    return PreferenceRecord(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      focusMinutes: data.focusMinutes.present
          ? data.focusMinutes.value
          : this.focusMinutes,
      restMinutes: data.restMinutes.present
          ? data.restMinutes.value
          : this.restMinutes,
      dailyStart: data.dailyStart.present
          ? data.dailyStart.value
          : this.dailyStart,
      dailyEnd: data.dailyEnd.present ? data.dailyEnd.value : this.dailyEnd,
      autoStartEnabled: data.autoStartEnabled.present
          ? data.autoStartEnabled.value
          : this.autoStartEnabled,
      soundMode: data.soundMode.present ? data.soundMode.value : this.soundMode,
      customFileName: data.customFileName.present
          ? data.customFileName.value
          : this.customFileName,
      soundVolume: data.soundVolume.present
          ? data.soundVolume.value
          : this.soundVolume,
      mutedFromMode: data.mutedFromMode.present
          ? data.mutedFromMode.value
          : this.mutedFromMode,
      mutedFromFileName: data.mutedFromFileName.present
          ? data.mutedFromFileName.value
          : this.mutedFromFileName,
      language: data.language.present ? data.language.value : this.language,
      theme: data.theme.present ? data.theme.value : this.theme,
      initialSetupCompleted: data.initialSetupCompleted.present
          ? data.initialSetupCompleted.value
          : this.initialSetupCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceRecord(')
          ..write('singletonId: $singletonId, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('restMinutes: $restMinutes, ')
          ..write('dailyStart: $dailyStart, ')
          ..write('dailyEnd: $dailyEnd, ')
          ..write('autoStartEnabled: $autoStartEnabled, ')
          ..write('soundMode: $soundMode, ')
          ..write('customFileName: $customFileName, ')
          ..write('soundVolume: $soundVolume, ')
          ..write('mutedFromMode: $mutedFromMode, ')
          ..write('mutedFromFileName: $mutedFromFileName, ')
          ..write('language: $language, ')
          ..write('theme: $theme, ')
          ..write('initialSetupCompleted: $initialSetupCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singletonId,
    focusMinutes,
    restMinutes,
    dailyStart,
    dailyEnd,
    autoStartEnabled,
    soundMode,
    customFileName,
    soundVolume,
    mutedFromMode,
    mutedFromFileName,
    language,
    theme,
    initialSetupCompleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferenceRecord &&
          other.singletonId == this.singletonId &&
          other.focusMinutes == this.focusMinutes &&
          other.restMinutes == this.restMinutes &&
          other.dailyStart == this.dailyStart &&
          other.dailyEnd == this.dailyEnd &&
          other.autoStartEnabled == this.autoStartEnabled &&
          other.soundMode == this.soundMode &&
          other.customFileName == this.customFileName &&
          other.soundVolume == this.soundVolume &&
          other.mutedFromMode == this.mutedFromMode &&
          other.mutedFromFileName == this.mutedFromFileName &&
          other.language == this.language &&
          other.theme == this.theme &&
          other.initialSetupCompleted == this.initialSetupCompleted);
}

class PreferenceRecordsCompanion extends UpdateCompanion<PreferenceRecord> {
  final Value<int> singletonId;
  final Value<int> focusMinutes;
  final Value<int> restMinutes;
  final Value<String> dailyStart;
  final Value<String> dailyEnd;
  final Value<bool> autoStartEnabled;
  final Value<String> soundMode;
  final Value<String?> customFileName;
  final Value<double> soundVolume;
  final Value<String?> mutedFromMode;
  final Value<String?> mutedFromFileName;
  final Value<String> language;
  final Value<String> theme;
  final Value<bool> initialSetupCompleted;
  const PreferenceRecordsCompanion({
    this.singletonId = const Value.absent(),
    this.focusMinutes = const Value.absent(),
    this.restMinutes = const Value.absent(),
    this.dailyStart = const Value.absent(),
    this.dailyEnd = const Value.absent(),
    this.autoStartEnabled = const Value.absent(),
    this.soundMode = const Value.absent(),
    this.customFileName = const Value.absent(),
    this.soundVolume = const Value.absent(),
    this.mutedFromMode = const Value.absent(),
    this.mutedFromFileName = const Value.absent(),
    this.language = const Value.absent(),
    this.theme = const Value.absent(),
    this.initialSetupCompleted = const Value.absent(),
  });
  PreferenceRecordsCompanion.insert({
    this.singletonId = const Value.absent(),
    required int focusMinutes,
    required int restMinutes,
    required String dailyStart,
    required String dailyEnd,
    required bool autoStartEnabled,
    required String soundMode,
    this.customFileName = const Value.absent(),
    required double soundVolume,
    this.mutedFromMode = const Value.absent(),
    this.mutedFromFileName = const Value.absent(),
    required String language,
    required String theme,
    required bool initialSetupCompleted,
  }) : focusMinutes = Value(focusMinutes),
       restMinutes = Value(restMinutes),
       dailyStart = Value(dailyStart),
       dailyEnd = Value(dailyEnd),
       autoStartEnabled = Value(autoStartEnabled),
       soundMode = Value(soundMode),
       soundVolume = Value(soundVolume),
       language = Value(language),
       theme = Value(theme),
       initialSetupCompleted = Value(initialSetupCompleted);
  static Insertable<PreferenceRecord> custom({
    Expression<int>? singletonId,
    Expression<int>? focusMinutes,
    Expression<int>? restMinutes,
    Expression<String>? dailyStart,
    Expression<String>? dailyEnd,
    Expression<bool>? autoStartEnabled,
    Expression<String>? soundMode,
    Expression<String>? customFileName,
    Expression<double>? soundVolume,
    Expression<String>? mutedFromMode,
    Expression<String>? mutedFromFileName,
    Expression<String>? language,
    Expression<String>? theme,
    Expression<bool>? initialSetupCompleted,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (focusMinutes != null) 'focus_minutes': focusMinutes,
      if (restMinutes != null) 'rest_minutes': restMinutes,
      if (dailyStart != null) 'daily_start': dailyStart,
      if (dailyEnd != null) 'daily_end': dailyEnd,
      if (autoStartEnabled != null) 'auto_start_enabled': autoStartEnabled,
      if (soundMode != null) 'sound_mode': soundMode,
      if (customFileName != null) 'custom_file_name': customFileName,
      if (soundVolume != null) 'sound_volume': soundVolume,
      if (mutedFromMode != null) 'muted_from_mode': mutedFromMode,
      if (mutedFromFileName != null) 'muted_from_file_name': mutedFromFileName,
      if (language != null) 'language': language,
      if (theme != null) 'theme': theme,
      if (initialSetupCompleted != null)
        'initial_setup_completed': initialSetupCompleted,
    });
  }

  PreferenceRecordsCompanion copyWith({
    Value<int>? singletonId,
    Value<int>? focusMinutes,
    Value<int>? restMinutes,
    Value<String>? dailyStart,
    Value<String>? dailyEnd,
    Value<bool>? autoStartEnabled,
    Value<String>? soundMode,
    Value<String?>? customFileName,
    Value<double>? soundVolume,
    Value<String?>? mutedFromMode,
    Value<String?>? mutedFromFileName,
    Value<String>? language,
    Value<String>? theme,
    Value<bool>? initialSetupCompleted,
  }) {
    return PreferenceRecordsCompanion(
      singletonId: singletonId ?? this.singletonId,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      restMinutes: restMinutes ?? this.restMinutes,
      dailyStart: dailyStart ?? this.dailyStart,
      dailyEnd: dailyEnd ?? this.dailyEnd,
      autoStartEnabled: autoStartEnabled ?? this.autoStartEnabled,
      soundMode: soundMode ?? this.soundMode,
      customFileName: customFileName ?? this.customFileName,
      soundVolume: soundVolume ?? this.soundVolume,
      mutedFromMode: mutedFromMode ?? this.mutedFromMode,
      mutedFromFileName: mutedFromFileName ?? this.mutedFromFileName,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      initialSetupCompleted:
          initialSetupCompleted ?? this.initialSetupCompleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (focusMinutes.present) {
      map['focus_minutes'] = Variable<int>(focusMinutes.value);
    }
    if (restMinutes.present) {
      map['rest_minutes'] = Variable<int>(restMinutes.value);
    }
    if (dailyStart.present) {
      map['daily_start'] = Variable<String>(dailyStart.value);
    }
    if (dailyEnd.present) {
      map['daily_end'] = Variable<String>(dailyEnd.value);
    }
    if (autoStartEnabled.present) {
      map['auto_start_enabled'] = Variable<bool>(autoStartEnabled.value);
    }
    if (soundMode.present) {
      map['sound_mode'] = Variable<String>(soundMode.value);
    }
    if (customFileName.present) {
      map['custom_file_name'] = Variable<String>(customFileName.value);
    }
    if (soundVolume.present) {
      map['sound_volume'] = Variable<double>(soundVolume.value);
    }
    if (mutedFromMode.present) {
      map['muted_from_mode'] = Variable<String>(mutedFromMode.value);
    }
    if (mutedFromFileName.present) {
      map['muted_from_file_name'] = Variable<String>(mutedFromFileName.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (initialSetupCompleted.present) {
      map['initial_setup_completed'] = Variable<bool>(
        initialSetupCompleted.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceRecordsCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('restMinutes: $restMinutes, ')
          ..write('dailyStart: $dailyStart, ')
          ..write('dailyEnd: $dailyEnd, ')
          ..write('autoStartEnabled: $autoStartEnabled, ')
          ..write('soundMode: $soundMode, ')
          ..write('customFileName: $customFileName, ')
          ..write('soundVolume: $soundVolume, ')
          ..write('mutedFromMode: $mutedFromMode, ')
          ..write('mutedFromFileName: $mutedFromFileName, ')
          ..write('language: $language, ')
          ..write('theme: $theme, ')
          ..write('initialSetupCompleted: $initialSetupCompleted')
          ..write(')'))
        .toString();
  }
}

class $TodoRecordsTable extends TodoRecords
    with TableInfo<$TodoRecordsTable, TodoRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayTimeMeta = const VerificationMeta(
    'displayTime',
  );
  @override
  late final GeneratedColumn<String> displayTime = GeneratedColumn<String>(
    'display_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageOrderMeta = const VerificationMeta(
    'storageOrder',
  );
  @override
  late final GeneratedColumn<int> storageOrder = GeneratedColumn<int>(
    'storage_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    localDate,
    displayTime,
    completed,
    displayOrder,
    createdAt,
    updatedAt,
    storageOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<TodoRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('display_time')) {
      context.handle(
        _displayTimeMeta,
        displayTime.isAcceptableOrUnknown(
          data['display_time']!,
          _displayTimeMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('storage_order')) {
      context.handle(
        _storageOrderMeta,
        storageOrder.isAcceptableOrUnknown(
          data['storage_order']!,
          _storageOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storageOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      displayTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_time'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      storageOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}storage_order'],
      )!,
    );
  }

  @override
  $TodoRecordsTable createAlias(String alias) {
    return $TodoRecordsTable(attachedDatabase, alias);
  }
}

class TodoRecord extends DataClass implements Insertable<TodoRecord> {
  final String id;
  final String title;
  final String localDate;
  final String? displayTime;
  final bool completed;
  final int displayOrder;
  final String createdAt;
  final String updatedAt;
  final int storageOrder;
  const TodoRecord({
    required this.id,
    required this.title,
    required this.localDate,
    this.displayTime,
    required this.completed,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.storageOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['local_date'] = Variable<String>(localDate);
    if (!nullToAbsent || displayTime != null) {
      map['display_time'] = Variable<String>(displayTime);
    }
    map['completed'] = Variable<bool>(completed);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['storage_order'] = Variable<int>(storageOrder);
    return map;
  }

  TodoRecordsCompanion toCompanion(bool nullToAbsent) {
    return TodoRecordsCompanion(
      id: Value(id),
      title: Value(title),
      localDate: Value(localDate),
      displayTime: displayTime == null && nullToAbsent
          ? const Value.absent()
          : Value(displayTime),
      completed: Value(completed),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      storageOrder: Value(storageOrder),
    );
  }

  factory TodoRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoRecord(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      localDate: serializer.fromJson<String>(json['localDate']),
      displayTime: serializer.fromJson<String?>(json['displayTime']),
      completed: serializer.fromJson<bool>(json['completed']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      storageOrder: serializer.fromJson<int>(json['storageOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'localDate': serializer.toJson<String>(localDate),
      'displayTime': serializer.toJson<String?>(displayTime),
      'completed': serializer.toJson<bool>(completed),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'storageOrder': serializer.toJson<int>(storageOrder),
    };
  }

  TodoRecord copyWith({
    String? id,
    String? title,
    String? localDate,
    Value<String?> displayTime = const Value.absent(),
    bool? completed,
    int? displayOrder,
    String? createdAt,
    String? updatedAt,
    int? storageOrder,
  }) => TodoRecord(
    id: id ?? this.id,
    title: title ?? this.title,
    localDate: localDate ?? this.localDate,
    displayTime: displayTime.present ? displayTime.value : this.displayTime,
    completed: completed ?? this.completed,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    storageOrder: storageOrder ?? this.storageOrder,
  );
  TodoRecord copyWithCompanion(TodoRecordsCompanion data) {
    return TodoRecord(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      displayTime: data.displayTime.present
          ? data.displayTime.value
          : this.displayTime,
      completed: data.completed.present ? data.completed.value : this.completed,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      storageOrder: data.storageOrder.present
          ? data.storageOrder.value
          : this.storageOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoRecord(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('localDate: $localDate, ')
          ..write('displayTime: $displayTime, ')
          ..write('completed: $completed, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('storageOrder: $storageOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    localDate,
    displayTime,
    completed,
    displayOrder,
    createdAt,
    updatedAt,
    storageOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoRecord &&
          other.id == this.id &&
          other.title == this.title &&
          other.localDate == this.localDate &&
          other.displayTime == this.displayTime &&
          other.completed == this.completed &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.storageOrder == this.storageOrder);
}

class TodoRecordsCompanion extends UpdateCompanion<TodoRecord> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> localDate;
  final Value<String?> displayTime;
  final Value<bool> completed;
  final Value<int> displayOrder;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> storageOrder;
  final Value<int> rowid;
  const TodoRecordsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.localDate = const Value.absent(),
    this.displayTime = const Value.absent(),
    this.completed = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.storageOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodoRecordsCompanion.insert({
    required String id,
    required String title,
    required String localDate,
    this.displayTime = const Value.absent(),
    required bool completed,
    required int displayOrder,
    required String createdAt,
    required String updatedAt,
    required int storageOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       localDate = Value(localDate),
       completed = Value(completed),
       displayOrder = Value(displayOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       storageOrder = Value(storageOrder);
  static Insertable<TodoRecord> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? localDate,
    Expression<String>? displayTime,
    Expression<bool>? completed,
    Expression<int>? displayOrder,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? storageOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (localDate != null) 'local_date': localDate,
      if (displayTime != null) 'display_time': displayTime,
      if (completed != null) 'completed': completed,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (storageOrder != null) 'storage_order': storageOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodoRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? localDate,
    Value<String?>? displayTime,
    Value<bool>? completed,
    Value<int>? displayOrder,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? storageOrder,
    Value<int>? rowid,
  }) {
    return TodoRecordsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      localDate: localDate ?? this.localDate,
      displayTime: displayTime ?? this.displayTime,
      completed: completed ?? this.completed,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      storageOrder: storageOrder ?? this.storageOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (displayTime.present) {
      map['display_time'] = Variable<String>(displayTime.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (storageOrder.present) {
      map['storage_order'] = Variable<int>(storageOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoRecordsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('localDate: $localDate, ')
          ..write('displayTime: $displayTime, ')
          ..write('completed: $completed, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('storageOrder: $storageOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ClockRhythmDatabase extends GeneratedDatabase {
  _$ClockRhythmDatabase(QueryExecutor e) : super(e);
  $ClockRhythmDatabaseManager get managers => $ClockRhythmDatabaseManager(this);
  late final $PreferenceRecordsTable preferenceRecords =
      $PreferenceRecordsTable(this);
  late final $TodoRecordsTable todoRecords = $TodoRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    preferenceRecords,
    todoRecords,
  ];
}

typedef $$PreferenceRecordsTableCreateCompanionBuilder =
    PreferenceRecordsCompanion Function({
      Value<int> singletonId,
      required int focusMinutes,
      required int restMinutes,
      required String dailyStart,
      required String dailyEnd,
      required bool autoStartEnabled,
      required String soundMode,
      Value<String?> customFileName,
      required double soundVolume,
      Value<String?> mutedFromMode,
      Value<String?> mutedFromFileName,
      required String language,
      required String theme,
      required bool initialSetupCompleted,
    });
typedef $$PreferenceRecordsTableUpdateCompanionBuilder =
    PreferenceRecordsCompanion Function({
      Value<int> singletonId,
      Value<int> focusMinutes,
      Value<int> restMinutes,
      Value<String> dailyStart,
      Value<String> dailyEnd,
      Value<bool> autoStartEnabled,
      Value<String> soundMode,
      Value<String?> customFileName,
      Value<double> soundVolume,
      Value<String?> mutedFromMode,
      Value<String?> mutedFromFileName,
      Value<String> language,
      Value<String> theme,
      Value<bool> initialSetupCompleted,
    });

class $$PreferenceRecordsTableFilterComposer
    extends Composer<_$ClockRhythmDatabase, $PreferenceRecordsTable> {
  $$PreferenceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restMinutes => $composableBuilder(
    column: $table.restMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyStart => $composableBuilder(
    column: $table.dailyStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyEnd => $composableBuilder(
    column: $table.dailyEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoStartEnabled => $composableBuilder(
    column: $table.autoStartEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundMode => $composableBuilder(
    column: $table.soundMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customFileName => $composableBuilder(
    column: $table.customFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get soundVolume => $composableBuilder(
    column: $table.soundVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutedFromMode => $composableBuilder(
    column: $table.mutedFromMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutedFromFileName => $composableBuilder(
    column: $table.mutedFromFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get initialSetupCompleted => $composableBuilder(
    column: $table.initialSetupCompleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferenceRecordsTableOrderingComposer
    extends Composer<_$ClockRhythmDatabase, $PreferenceRecordsTable> {
  $$PreferenceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restMinutes => $composableBuilder(
    column: $table.restMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyStart => $composableBuilder(
    column: $table.dailyStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyEnd => $composableBuilder(
    column: $table.dailyEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoStartEnabled => $composableBuilder(
    column: $table.autoStartEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundMode => $composableBuilder(
    column: $table.soundMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customFileName => $composableBuilder(
    column: $table.customFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get soundVolume => $composableBuilder(
    column: $table.soundVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutedFromMode => $composableBuilder(
    column: $table.mutedFromMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutedFromFileName => $composableBuilder(
    column: $table.mutedFromFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get initialSetupCompleted => $composableBuilder(
    column: $table.initialSetupCompleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferenceRecordsTableAnnotationComposer
    extends Composer<_$ClockRhythmDatabase, $PreferenceRecordsTable> {
  $$PreferenceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restMinutes => $composableBuilder(
    column: $table.restMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dailyStart => $composableBuilder(
    column: $table.dailyStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dailyEnd =>
      $composableBuilder(column: $table.dailyEnd, builder: (column) => column);

  GeneratedColumn<bool> get autoStartEnabled => $composableBuilder(
    column: $table.autoStartEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundMode =>
      $composableBuilder(column: $table.soundMode, builder: (column) => column);

  GeneratedColumn<String> get customFileName => $composableBuilder(
    column: $table.customFileName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get soundVolume => $composableBuilder(
    column: $table.soundVolume,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mutedFromMode => $composableBuilder(
    column: $table.mutedFromMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mutedFromFileName => $composableBuilder(
    column: $table.mutedFromFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<bool> get initialSetupCompleted => $composableBuilder(
    column: $table.initialSetupCompleted,
    builder: (column) => column,
  );
}

class $$PreferenceRecordsTableTableManager
    extends
        RootTableManager<
          _$ClockRhythmDatabase,
          $PreferenceRecordsTable,
          PreferenceRecord,
          $$PreferenceRecordsTableFilterComposer,
          $$PreferenceRecordsTableOrderingComposer,
          $$PreferenceRecordsTableAnnotationComposer,
          $$PreferenceRecordsTableCreateCompanionBuilder,
          $$PreferenceRecordsTableUpdateCompanionBuilder,
          (
            PreferenceRecord,
            BaseReferences<
              _$ClockRhythmDatabase,
              $PreferenceRecordsTable,
              PreferenceRecord
            >,
          ),
          PreferenceRecord,
          PrefetchHooks Function()
        > {
  $$PreferenceRecordsTableTableManager(
    _$ClockRhythmDatabase db,
    $PreferenceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferenceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferenceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferenceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<int> focusMinutes = const Value.absent(),
                Value<int> restMinutes = const Value.absent(),
                Value<String> dailyStart = const Value.absent(),
                Value<String> dailyEnd = const Value.absent(),
                Value<bool> autoStartEnabled = const Value.absent(),
                Value<String> soundMode = const Value.absent(),
                Value<String?> customFileName = const Value.absent(),
                Value<double> soundVolume = const Value.absent(),
                Value<String?> mutedFromMode = const Value.absent(),
                Value<String?> mutedFromFileName = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<bool> initialSetupCompleted = const Value.absent(),
              }) => PreferenceRecordsCompanion(
                singletonId: singletonId,
                focusMinutes: focusMinutes,
                restMinutes: restMinutes,
                dailyStart: dailyStart,
                dailyEnd: dailyEnd,
                autoStartEnabled: autoStartEnabled,
                soundMode: soundMode,
                customFileName: customFileName,
                soundVolume: soundVolume,
                mutedFromMode: mutedFromMode,
                mutedFromFileName: mutedFromFileName,
                language: language,
                theme: theme,
                initialSetupCompleted: initialSetupCompleted,
              ),
          createCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                required int focusMinutes,
                required int restMinutes,
                required String dailyStart,
                required String dailyEnd,
                required bool autoStartEnabled,
                required String soundMode,
                Value<String?> customFileName = const Value.absent(),
                required double soundVolume,
                Value<String?> mutedFromMode = const Value.absent(),
                Value<String?> mutedFromFileName = const Value.absent(),
                required String language,
                required String theme,
                required bool initialSetupCompleted,
              }) => PreferenceRecordsCompanion.insert(
                singletonId: singletonId,
                focusMinutes: focusMinutes,
                restMinutes: restMinutes,
                dailyStart: dailyStart,
                dailyEnd: dailyEnd,
                autoStartEnabled: autoStartEnabled,
                soundMode: soundMode,
                customFileName: customFileName,
                soundVolume: soundVolume,
                mutedFromMode: mutedFromMode,
                mutedFromFileName: mutedFromFileName,
                language: language,
                theme: theme,
                initialSetupCompleted: initialSetupCompleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferenceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ClockRhythmDatabase,
      $PreferenceRecordsTable,
      PreferenceRecord,
      $$PreferenceRecordsTableFilterComposer,
      $$PreferenceRecordsTableOrderingComposer,
      $$PreferenceRecordsTableAnnotationComposer,
      $$PreferenceRecordsTableCreateCompanionBuilder,
      $$PreferenceRecordsTableUpdateCompanionBuilder,
      (
        PreferenceRecord,
        BaseReferences<
          _$ClockRhythmDatabase,
          $PreferenceRecordsTable,
          PreferenceRecord
        >,
      ),
      PreferenceRecord,
      PrefetchHooks Function()
    >;
typedef $$TodoRecordsTableCreateCompanionBuilder =
    TodoRecordsCompanion Function({
      required String id,
      required String title,
      required String localDate,
      Value<String?> displayTime,
      required bool completed,
      required int displayOrder,
      required String createdAt,
      required String updatedAt,
      required int storageOrder,
      Value<int> rowid,
    });
typedef $$TodoRecordsTableUpdateCompanionBuilder =
    TodoRecordsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> localDate,
      Value<String?> displayTime,
      Value<bool> completed,
      Value<int> displayOrder,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> storageOrder,
      Value<int> rowid,
    });

class $$TodoRecordsTableFilterComposer
    extends Composer<_$ClockRhythmDatabase, $TodoRecordsTable> {
  $$TodoRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayTime => $composableBuilder(
    column: $table.displayTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storageOrder => $composableBuilder(
    column: $table.storageOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TodoRecordsTableOrderingComposer
    extends Composer<_$ClockRhythmDatabase, $TodoRecordsTable> {
  $$TodoRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayTime => $composableBuilder(
    column: $table.displayTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storageOrder => $composableBuilder(
    column: $table.storageOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TodoRecordsTableAnnotationComposer
    extends Composer<_$ClockRhythmDatabase, $TodoRecordsTable> {
  $$TodoRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get displayTime => $composableBuilder(
    column: $table.displayTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get storageOrder => $composableBuilder(
    column: $table.storageOrder,
    builder: (column) => column,
  );
}

class $$TodoRecordsTableTableManager
    extends
        RootTableManager<
          _$ClockRhythmDatabase,
          $TodoRecordsTable,
          TodoRecord,
          $$TodoRecordsTableFilterComposer,
          $$TodoRecordsTableOrderingComposer,
          $$TodoRecordsTableAnnotationComposer,
          $$TodoRecordsTableCreateCompanionBuilder,
          $$TodoRecordsTableUpdateCompanionBuilder,
          (
            TodoRecord,
            BaseReferences<
              _$ClockRhythmDatabase,
              $TodoRecordsTable,
              TodoRecord
            >,
          ),
          TodoRecord,
          PrefetchHooks Function()
        > {
  $$TodoRecordsTableTableManager(
    _$ClockRhythmDatabase db,
    $TodoRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String?> displayTime = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> storageOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodoRecordsCompanion(
                id: id,
                title: title,
                localDate: localDate,
                displayTime: displayTime,
                completed: completed,
                displayOrder: displayOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                storageOrder: storageOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String localDate,
                Value<String?> displayTime = const Value.absent(),
                required bool completed,
                required int displayOrder,
                required String createdAt,
                required String updatedAt,
                required int storageOrder,
                Value<int> rowid = const Value.absent(),
              }) => TodoRecordsCompanion.insert(
                id: id,
                title: title,
                localDate: localDate,
                displayTime: displayTime,
                completed: completed,
                displayOrder: displayOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                storageOrder: storageOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TodoRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ClockRhythmDatabase,
      $TodoRecordsTable,
      TodoRecord,
      $$TodoRecordsTableFilterComposer,
      $$TodoRecordsTableOrderingComposer,
      $$TodoRecordsTableAnnotationComposer,
      $$TodoRecordsTableCreateCompanionBuilder,
      $$TodoRecordsTableUpdateCompanionBuilder,
      (
        TodoRecord,
        BaseReferences<_$ClockRhythmDatabase, $TodoRecordsTable, TodoRecord>,
      ),
      TodoRecord,
      PrefetchHooks Function()
    >;

class $ClockRhythmDatabaseManager {
  final _$ClockRhythmDatabase _db;
  $ClockRhythmDatabaseManager(this._db);
  $$PreferenceRecordsTableTableManager get preferenceRecords =>
      $$PreferenceRecordsTableTableManager(_db, _db.preferenceRecords);
  $$TodoRecordsTableTableManager get todoRecords =>
      $$TodoRecordsTableTableManager(_db, _db.todoRecords);
}
