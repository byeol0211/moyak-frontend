import 'dart:async';

import 'package:daily_flutter/daily_flutter.dart' as daily;
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak/calls/call_room.dart';
import 'package:moyak/calls/daily_call_native.dart';

class _JoinData implements daily.CallJoinData {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements daily.CallClient {
  final eventsController = StreamController<daily.Event>.broadcast();
  final joining = Completer<daily.CallJoinData>();
  final enteredJoin = Completer<void>();
  int disposals = 0;
  int leaves = 0;
  @override
  Stream<daily.Event> get events => eventsController.stream;
  @override
  Future<void> setUsername(String username) async {}
  @override
  Future<daily.CallJoinData> join({
    required Uri url,
    daily.ClientSettingsUpdate? clientSettings,
    String? token,
  }) {
    enteredJoin.complete();
    return joining.future;
  }

  @override
  daily.Participants get participants => daily.Participants(
    local: daily.Participant(
      id: const daily.ParticipantId('local'),
      info: daily.ParticipantInfo(isLocal: true, isOwner: false),
    ),
    remote: const {},
    all: const {},
  );
  @override
  Future<void> leave() async {
    leaves++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    await eventsController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final room = CallRoom(roomUrl: 'https://example.daily.co/test');
  test(
    'closing during join waits and disposes once without leave race',
    () async {
      final client = _Client();
      final engine = DailyCallEngine(createClient: () async => client);
      final connection = engine.connect(room);
      await client.enteredJoin.future;
      final close = engine.close();
      await Future<void>.delayed(Duration.zero);
      expect(client.disposals, 0);
      client.joining.complete(_JoinData());
      await connection;
      await close;
      await engine.close();
      expect(client.disposals, 1);
      expect(client.leaves, 0);
      engine.dispose();
    },
  );
  test('closing during client creation releases the late client', () async {
    final client = _Client();
    final creating = Completer<daily.CallClient>();
    final started = Completer<void>();
    final engine = DailyCallEngine(
      createClient: () {
        started.complete();
        return creating.future;
      },
    );
    final connection = engine.connect(room);
    await started.future;
    final close = engine.close();
    creating.complete(client);
    await connection;
    await close;
    expect(client.enteredJoin.isCompleted, isFalse);
    expect(client.disposals, 1);
    engine.dispose();
  });
}
