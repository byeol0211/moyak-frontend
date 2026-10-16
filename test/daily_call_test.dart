import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/calls/call_engine.dart';
import 'package:moyak/calls/call_room.dart';
import 'package:moyak/calls/consultation_chat.dart';
import 'package:moyak/screens/video_consultation_page.dart';

class FakeCall extends CallEngine {
  @override
  CallPhase phase = CallPhase.idle;
  @override
  String? error;
  @override
  bool cameraEnabled = true;
  @override
  bool microphoneEnabled = true;
  @override
  bool hasRemoteParticipant = true;
  @override
  bool remoteHasVideo = true;
  @override
  bool localHasVideo = true;
  @override
  bool controlsBusy = false;
  int joins = 0;
  int flips = 0;
  bool closed = false;
  bool suspended = false;
  @override
  Widget remoteVideo() =>
      const ColoredBox(key: Key('daily-remote'), color: Colors.blue);
  @override
  Widget localVideo() =>
      const ColoredBox(key: Key('daily-local'), color: Colors.green);
  void update() => notifyListeners();
  @override
  Future<void> connect(CallRoom room) async {
    joins++;
    phase = CallPhase.connected;
    update();
  }

  @override
  Future<void> setCamera(bool enabled) async {
    cameraEnabled = enabled;
    update();
  }

  @override
  Future<void> setMicrophone(bool enabled) async {
    microphoneEnabled = enabled;
    update();
  }

  @override
  Future<void> flipCamera() async {
    flips++;
  }

  @override
  Future<void> suspendMedia() async {
    suspended = true;
  }

  @override
  Future<void> resumeMedia() async {
    suspended = false;
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

class FakeChat implements ConsultationChat {
  @override
  String? get summary => ended || remoteEnded ? '서버 상담 요약' : null;
  bool failSend = false;
  bool failEnd = false;
  bool ended = false;
  bool remoteEnded = false;
  final messages = <CallChatMessage>[
    const CallChatMessage(id: '1', text: '약사 메시지', local: false),
  ];
  @override
  Future<ConsultationChatSnapshot> poll() async =>
      ConsultationChatSnapshot(messages, ended: remoteEnded);
  @override
  Future<CallChatMessage> send(String text) async {
    if (failSend) throw StateError('offline');
    final message = CallChatMessage(
      id: '${messages.length + 1}',
      text: text,
      local: true,
    );
    messages.add(message);
    return message;
  }

  @override
  Future<void> end() async {
    if (failEnd) throw StateError('offline');
    ended = true;
  }

  @override
  Future<void> cancel() async {
    ended = true;
  }

  @override
  void dispose() {}
}

Future<void> openCall(
  WidgetTester tester,
  FakeCall call, {
  FakeChat? chat,
}) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => VideoConsultationPage(
                  room: CallRoom(roomUrl: 'https://test.daily.co/room'),
                  engine: call,
                  chat: chat,
                ),
              ),
            ),
            child: const Text('입장'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('입장'));
  await tester.pumpAndSettle();
}

void main() {
  test('room credentials are validated and never included in diagnostics', () {
    final room = CallRoom.fromJson({
      'room_url': 'https://test.daily.co/room',
      'meeting_token': 'secret',
    });
    expect(room.token, 'secret');
    expect(room.toString(), isNot(contains('secret')));
    expect(room.toString(), isNot(contains('test.daily.co')));
    for (final value in [
      'http://test.daily.co/room',
      'file:///room',
      'https://test.daily.co',
      'https://user:pass@test.daily.co/room',
    ]) {
      expect(() => CallRoom(roomUrl: value), throwsFormatException);
    }
  });

  test('consultation client polls, posts user messages and ends existing consultation', () async {
    final calls = <http.Request>[];
    final client = MockClient((request) async {
      calls.add(request);
      final Object data;
      if (request.url.path.endsWith('/messages')) {
        final message = {
          'id': 1,
          'content': '안녕하세요',
          'sender_role': 'user',
          'sender_id': 'user-1',
        };
        data = request.method == 'GET' ? [message] : message;
      } else {
        data = <String, Object?>{'ended_at': null};
      }
      return http.Response(
        jsonEncode(data),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final chat = ApiConsultationChat(
      consultationId: 'c-1',
      userId: 'user-1',
      client: client,
      baseUrl: Uri.parse('https://api.example.com'),
    );
    final batch = await chat.poll();
    expect(batch.messages.single.local, isTrue);
    expect(batch.ended, isFalse);
    expect((await chat.send('안녕하세요')).text, '안녕하세요');
    await chat.end();
    final post = calls.firstWhere(
      (request) =>
          request.method == 'POST' && request.url.path.endsWith('/messages'),
    );
    expect(jsonDecode(post.body), {
      'sender_role': 'user',
      'sender_id': 'user-1',
      'content': '안녕하세요',
    });
    expect(calls.last.url.path, '/consultations/c-1/end');
    chat.dispose();
    client.close();
  });

  testWidgets(
    'real call controls drive engine and retry keeps media behind chat',
    (tester) async {
      final call = FakeCall();
      await openCall(tester, call);
      expect(call.joins, 1);
      expect(find.byKey(const Key('daily-remote')), findsOneWidget);
      await tester.tap(find.byTooltip('카메라 끄기'));
      await tester.pump();
      expect(call.cameraEnabled, isFalse);
      await tester.tap(find.byTooltip('마이크 끄기'));
      await tester.pump();
      expect(call.microphoneEnabled, isFalse);
      call.phase = CallPhase.disconnected;
      call.update();
      await tester.pump();
      await tester.tap(find.text('다시 연결'));
      await tester.pumpAndSettle();
      expect(call.joins, 2);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(call.suspended, isTrue);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(call.suspended, isFalse);
      await tester.pumpWidget(const SizedBox());
      expect(call.closed, isTrue);
      call.dispose();
    },
  );

  testWidgets(
    'chat deduplicates, preserves failed text and handles remote end',
    (tester) async {
      final call = FakeCall();
      final chat = FakeChat()..failSend = true;
      await openCall(tester, call, chat: chat);
      await tester.tap(find.byTooltip('채팅 열기'));
      await tester.pumpAndSettle();
      expect(find.text('약사 메시지'), findsOneWidget);
      final videoElement = tester.element(
        find.byKey(const Key('daily-remote')),
      );
      await tester.enterText(find.byType(TextField), '보낼 내용');
      await tester.tap(find.byTooltip('메시지 보내기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '보낼 내용',
      );
      expect(find.textContaining('메시지를 보내지 못했어요'), findsOneWidget);
      chat.failSend = false;
      await tester.tap(find.byTooltip('메시지 보내기'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('보낼 내용'), findsOneWidget);
      expect(
        tester.element(find.byKey(const Key('daily-remote'))),
        same(videoElement),
      );
      chat.remoteEnded = true;
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(call.closed, isTrue);
      expect(find.text('상담이 종료되었어요'), findsWidgets);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await tester.pumpWidget(const SizedBox());
      call.dispose();
    },
  );

  testWidgets(
    'failed server end can be retried or leave media without ending record',
    (tester) async {
      final call = FakeCall();
      final chat = FakeChat()..failEnd = true;
      await openCall(tester, call, chat: chat);
      await tester.tap(find.text('상담 종료'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('종료'));
      await tester.pumpAndSettle();
      expect(call.closed, isTrue);
      expect(find.textContaining('상담 종료를 서버에 반영하지 못했어요'), findsOneWidget);
      await tester.tap(find.text('상담 종료'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('통화만 나가기'));
      await tester.pumpAndSettle();
      expect(call.closed, isTrue);
      expect(chat.ended, isFalse);
      expect(find.text('입장'), findsOneWidget);
      call.dispose();
    },
  );
}
