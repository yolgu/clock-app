import 'dart:convert';
import 'dart:io';

import 'package:clock_rhythm/contexts/preferences/public_model.dart';
import 'package:clock_rhythm/contexts/todo/public_model.dart';
import 'package:clock_rhythm/features/data_transfer/application/backup_failure.dart';
import 'package:clock_rhythm/features/data_transfer/application/ports.dart';
import 'package:clock_rhythm/features/data_transfer/infrastructure/json/backup_v1_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const BackupV1Codec codec = BackupV1Codec();

  test('restores missing legacy optionals to agreed defaults', () {
    final PortableBackupData data = codec.decode(
      File(
        'test/fixtures/backups/neutralino-v1-legacy-missing-optionals.json',
      ).readAsBytesSync(),
    );

    expect(data.preferences.language, LanguagePreference.korean);
    expect(data.preferences.theme, ThemePreference.current);
    expect(
      data.preferences.notificationSound.mode,
      NotificationSoundMode.bundledDefault,
    );
    expect(data.preferences.initialSetupCompleted, isFalse);
    expect(data.todos.single.time, isNull);
    expect(data.todos.single.displayOrder, greaterThanOrEqualTo(0));
  });

  test('accepts synthetic additive fields and normalizes microseconds', () {
    final PortableBackupData data = codec.decode(
      File(
        'test/fixtures/backups/synthetic-v1-additive-fields-and-microseconds.json',
      ).readAsBytesSync(),
    );

    expect(data.customSoundWasSanitized, isTrue);
    expect(
      data.preferences.notificationSound.mode,
      NotificationSoundMode.bundledDefault,
    );
    expect(data.preferences.notificationSound.volume, 0.5);
    expect(data.todos, hasLength(2));
    expect(data.todos.first.snapshot().createdAt, '2026-06-02T09:00:00.123Z');
    expect(data.todos.first.snapshot().updatedAt, '2026-06-02T09:10:00.999Z');
  });

  test('export emits canonical v1 and strips unknown and private fields', () {
    final PortableBackupData decoded = codec.decode(
      File(
        'test/fixtures/backups/synthetic-v1-additive-fields-and-microseconds.json',
      ).readAsBytesSync(),
    );

    final List<int> encoded = codec.encode(decoded);
    final String text = utf8.decode(encoded);
    final Map<String, Object?> envelope = Map<String, Object?>.from(
      jsonDecode(text) as Map<Object?, Object?>,
    );

    expect(envelope['appName'], 'Clock Rhythm');
    expect(envelope['schemaVersion'], 1);
    expect(envelope, isNot(contains('futureEnvelopeField')));
    expect(text, isNot(contains('googleTaskId')));
    expect(text, isNot(contains('/user-sounds/notification.mp3')));
    expect(text, isNot(contains('futurePreference')));

    final PortableBackupData roundTrip = codec.decode(encoded);
    expect(roundTrip.preferences, decoded.preferences);
    expect(
      roundTrip.todos.map((todo) => todo.snapshot()),
      decoded.todos.map((todo) => todo.snapshot()),
    );
  });

  test(
    'canonical Flutter bytes preserve every semantic accepted by the Neutralino importer',
    () {
      final List<int> neutralinoExport = File(
        'test/fixtures/backups/neutralino-v1-full.json',
      ).readAsBytesSync();
      final PortableBackupData decoded = codec.decode(neutralinoExport);
      final Object? neutralinoImportedSemantics = jsonDecode(
        File(
          'test/fixtures/backups/neutralino-v1-full-imported-semantics.json',
        ).readAsStringSync(),
      );

      expect(neutralinoExport.last, 0x7d);
      expect(decoded.customSoundWasSanitized, isTrue);
      expect(_semanticSnapshot(decoded), neutralinoImportedSemantics);

      final List<int> flutterCanonical = codec.encode(decoded);
      expect(
        flutterCanonical,
        File(
          'test/fixtures/backups/neutralino-v1-full-flutter-canonical.json',
        ).readAsBytesSync(),
      );

      final PortableBackupData canonicalRoundTrip = codec.decode(
        flutterCanonical,
      );
      expect(
        _semanticSnapshot(canonicalRoundTrip),
        neutralinoImportedSemantics,
      );
    },
  );

  test('rejects unknown versions without guessing', () {
    expect(
      () => codec.decode(
        File(
          'test/fixtures/backups/invalid-unknown-version.json',
        ).readAsBytesSync(),
      ),
      throwsA(
        isA<BackupFailure>().having(
          (BackupFailure failure) => failure.key,
          'key',
          BackupFailureKey.unsupportedSchemaVersion,
        ),
      ),
    );
  });

  test('reports invalid Todo index without leaking its title', () {
    try {
      codec.decode(
        File('test/fixtures/backups/invalid-todo-date.json').readAsBytesSync(),
      );
      fail('Expected invalid Todo date failure.');
    } on BackupFailure catch (failure) {
      expect(failure.key, BackupFailureKey.todoDateInvalid);
      expect(failure.zeroBasedTodoIndex, 0);
      expect(failure.toString(), isNot(contains('Never disclose')));
    }
  });

  final List<_InvalidTodoCase> invalidTodoCases = <_InvalidTodoCase>[
    _InvalidTodoCase(
      name: 'missing identifier',
      expectedKey: BackupFailureKey.todoIdInvalid,
      mutate: (Map<String, Object?> todo) => todo.remove('id'),
    ),
    _InvalidTodoCase(
      name: 'identifier longer than 128 characters',
      expectedKey: BackupFailureKey.todoIdInvalid,
      mutate: (Map<String, Object?> todo) {
        todo['id'] = List<String>.filled(129, 'x').join();
      },
    ),
    _InvalidTodoCase(
      name: 'multiline title',
      expectedKey: BackupFailureKey.todoTitleInvalid,
      mutate: (Map<String, Object?> todo) {
        todo['title'] = 'first line\nsecond line';
      },
    ),
    _InvalidTodoCase(
      name: 'non-Gregorian calendar date',
      expectedKey: BackupFailureKey.todoDateInvalid,
      mutate: (Map<String, Object?> todo) {
        todo['date'] = '2026-02-30';
      },
    ),
    _InvalidTodoCase(
      name: 'out-of-range display time',
      expectedKey: BackupFailureKey.todoTimeInvalid,
      mutate: (Map<String, Object?> todo) {
        todo['time'] = '24:00';
      },
    ),
    _InvalidTodoCase(
      name: 'non-Boolean completion',
      expectedKey: BackupFailureKey.todoCompletionInvalid,
      mutate: (Map<String, Object?> todo) {
        todo['completed'] = 'false';
      },
    ),
    _InvalidTodoCase(
      name: 'unparseable creation timestamp',
      expectedKey: BackupFailureKey.todoTimestampsInvalid,
      mutate: (Map<String, Object?> todo) {
        todo['createdAt'] = 'not-an-instant';
      },
    ),
    _InvalidTodoCase(
      name: 'update before creation',
      expectedKey: BackupFailureKey.todoTimestampsInvalid,
      mutate: (Map<String, Object?> todo) {
        todo['updatedAt'] = '2026-06-02T08:59:59.999Z';
      },
    ),
    _InvalidTodoCase(
      name: 'negative display order',
      expectedKey: BackupFailureKey.todoDisplayOrderInvalid,
      mutate: (Map<String, Object?> todo) {
        todo['displayOrder'] = -1;
      },
    ),
    _InvalidTodoCase(
      name: 'non-integer display order',
      expectedKey: BackupFailureKey.todoDisplayOrderInvalid,
      mutate: (Map<String, Object?> todo) {
        todo['displayOrder'] = 1.5;
      },
    ),
  ];

  for (final _InvalidTodoCase invalidCase in invalidTodoCases) {
    test('rejects Todo with ${invalidCase.name} at its source index', () {
      final Map<String, Object?> envelope = _fullEnvelope();
      invalidCase.mutate(_firstTodo(envelope));

      _expectIndexedTodoFailure(
        codec: codec,
        envelope: envelope,
        expectedKey: invalidCase.expectedKey,
      );
    });
  }

  test('rejects duplicate Todo identifiers at the duplicate index', () {
    final Map<String, Object?> envelope = _fullEnvelope();
    final List<Object?> todos = _todos(envelope);
    final Map<String, Object?> first = Map<String, Object?>.from(
      todos.first as Map<Object?, Object?>,
    );
    final Map<String, Object?> duplicate = Map<String, Object?>.from(
      todos[1] as Map<Object?, Object?>,
    )..['id'] = first['id'];
    todos[0] = first;
    todos[1] = duplicate;

    try {
      codec.decode(utf8.encode(jsonEncode(envelope)));
      fail('Expected duplicate Todo identifier failure.');
    } on BackupFailure catch (failure) {
      expect(failure.key, BackupFailureKey.todoIdDuplicate);
      expect(failure.zeroBasedTodoIndex, 1);
      expect(failure.toString(), isNot(contains('Portable task')));
      expect(failure.toString(), isNot(contains('Completed task')));
    }
  });

  test('rejects a present invalid optional preference', () {
    final Map<String, Object?> envelope = Map<String, Object?>.from(
      jsonDecode(
            File(
              'test/fixtures/backups/neutralino-v1-minimal.json',
            ).readAsStringSync(),
          )
          as Map<Object?, Object?>,
    );
    final Map<String, Object?> preferences = Map<String, Object?>.from(
      envelope['preferences']! as Map<Object?, Object?>,
    );
    preferences['language'] = 'ko';
    envelope['preferences'] = preferences;

    expect(
      () => codec.decode(utf8.encode(jsonEncode(envelope))),
      throwsA(
        isA<BackupFailure>().having(
          (BackupFailure failure) => failure.key,
          'key',
          BackupFailureKey.invalidPreferences,
        ),
      ),
    );
  });

  test('checks byte and Todo limits before item validation', () {
    expect(
      () => codec.decode(List<int>.filled(codec.maximumFileBytes + 1, 0)),
      throwsA(
        isA<BackupFailure>().having(
          (BackupFailure failure) => failure.key,
          'key',
          BackupFailureKey.fileTooLarge,
        ),
      ),
    );
    final Map<String, Object?> envelope = <String, Object?>{
      'appName': 'Clock Rhythm',
      'schemaVersion': 1,
      'exportedAt': '2026-06-02T10:00:00.000Z',
      'preferences': <String, Object?>{
        'focusMinutes': 50,
        'restMinutes': 10,
        'dailyStart': '05:00',
        'dailyEnd': '18:00',
        'autoStartEnabled': false,
      },
      'todos': List<Map<String, Object?>>.filled(25001, <String, Object?>{}),
    };
    expect(
      () => codec.decode(utf8.encode(jsonEncode(envelope))),
      throwsA(
        isA<BackupFailure>().having(
          (BackupFailure failure) => failure.key,
          'key',
          BackupFailureKey.tooManyTodos,
        ),
      ),
    );
  });
}

Map<String, Object?> _semanticSnapshot(PortableBackupData data) {
  return <String, Object?>{
    'preferences': data.preferences.snapshot().toJsonLikeMap(),
    'todos': data.todos
        .map((Todo todo) {
          final TodoSnapshot snapshot = todo.snapshot();
          return <String, Object?>{
            'completed': snapshot.completed,
            'createdAt': snapshot.createdAt,
            'date': snapshot.date,
            'displayOrder': snapshot.displayOrder,
            'id': snapshot.id,
            'time': snapshot.time,
            'title': snapshot.title,
            'updatedAt': snapshot.updatedAt,
          };
        })
        .toList(growable: false),
  };
}

Map<String, Object?> _fullEnvelope() {
  final Object? decoded = jsonDecode(
    File('test/fixtures/backups/neutralino-v1-full.json').readAsStringSync(),
  );
  if (decoded is! Map<Object?, Object?>) {
    throw const FormatException('Full backup fixture must be an object.');
  }
  final Map<String, Object?> envelope = Map<String, Object?>.from(decoded);
  envelope['todos'] = List<Object?>.from(_todos(envelope));
  return envelope;
}

List<Object?> _todos(Map<String, Object?> envelope) {
  final Object? value = envelope['todos'];
  if (value is! List<Object?>) {
    throw const FormatException('Full backup fixture Todos must be a list.');
  }
  return value;
}

Map<String, Object?> _firstTodo(Map<String, Object?> envelope) {
  final List<Object?> todos = _todos(envelope);
  final Object? value = todos.first;
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Full backup fixture Todo must be an object.');
  }
  final Map<String, Object?> todo = Map<String, Object?>.from(value);
  todos[0] = todo;
  return todo;
}

void _expectIndexedTodoFailure({
  required BackupV1Codec codec,
  required Map<String, Object?> envelope,
  required BackupFailureKey expectedKey,
}) {
  try {
    codec.decode(utf8.encode(jsonEncode(envelope)));
    fail('Expected indexed Todo validation failure.');
  } on BackupFailure catch (failure) {
    expect(failure.key, expectedKey);
    expect(failure.zeroBasedTodoIndex, 0);
    expect(failure.toString(), isNot(contains('Portable task')));
  }
}

final class _InvalidTodoCase {
  const _InvalidTodoCase({
    required this.name,
    required this.expectedKey,
    required this.mutate,
  });

  final String name;
  final BackupFailureKey expectedKey;
  final void Function(Map<String, Object?> todo) mutate;
}
