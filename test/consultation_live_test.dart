import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/config/app_config.dart';
import 'package:moyak/data/app_session.dart';
import 'package:moyak/data/consultation_api.dart';
import 'package:moyak/data/models.dart';
import 'package:moyak/screens/consultation_screen.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _consultation({
  String status = 'pending',
  String? roomUrl = 'https://moyak.daily.co/room-1',
  String? drug,
  String? reason,
  String? summary,
  String? endedAt,
  String chatSummary = '직접 상담 요청 (사전 챗봇 대화 없음)',
}) => {
  'id': 'c-1',
  'user_id': 'user-1',
  'chat_summary': chatSummary,
  'room_url': roomUrl,
  'status': status,
  'decision_reason': reason,
  'created_at': '2026-10-17T05:00:00',
  'approved_drug_name': drug,
  'summary': summary,
  'ended_at': endedAt,
};

Future<void> _pumpPhone(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  setUp(() {
    AppConfig.preview.value = false;
    AppSession.instance.userId = 'user-1';
    AppSession.instance.chatSummary = '사용자: 머리가 아파요\n모약이: 타이레놀을 참고하세요';
    AppSession.instance.clearCallRoom();
    AppSession.instance.cancelConsultation();
  });

  test('parses server times as UTC and maps statuses', () {
    final snapshot = ConsultationApi.parse(
      _consultation(status: 'approved', drug: '타이레놀정500밀리그람'),
    );
    expect(snapshot.record.status, ConsultStatus.approved);
    expect(snapshot.record.direct, isTrue);
    expect(snapshot.record.createdAt, DateTime.utc(2026, 10, 17, 5).toLocal());
    expect(
      ConsultationApi.parse(_consultation(status: 'cancelled')).cancelled,
      isTrue,
    );
  });

  testWidgets('requests a consultation with the chat, then shows approval', (
    tester,
  ) async {
    final requests = <String>[];
    Map<String, dynamic>? createdBody;
    var current = _consultation(chatSummary: '사용자: 머리가 아파요');
    final client = MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      final path = request.url.path;
      if (path == '/consultations' && request.method == 'GET') {
        expect(request.url.queryParameters, {
          'status': 'pending',
          'user_id': 'user-1',
        });
        return _json([]);
      }
      if (path == '/consultations' && request.method == 'POST') {
        createdBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _json(current);
      }
      if (path == '/consultations/c-1') return _json(current);
      if (path == '/consultations/c-1/presence') {
        return _json({
          'available': true,
          'participants': 1,
          'pharmacist_in_room': true,
        });
      }
      return _json({'detail': 'unexpected $path'}, 404);
    });

    await _pumpPhone(
      tester,
      ConsultationScreen(
        direct: false,
        api: ConsultationApi(client: client),
        onScanQr: () {},
        onOpenChatbot: () {},
      ),
    );
    expect(find.text('상담을 요청하고 있어요'), findsOneWidget);
    await tester.pump();
    await tester.pump();

    expect(createdBody, {
      'user_id': 'user-1',
      'chat_summary': '사용자: 머리가 아파요\n모약이: 타이레놀을 참고하세요',
    });
    expect(find.text('약사 연결을 기다리는 중이에요'), findsOneWidget);
    expect(find.text('🎥 화상 상담 입장하기'), findsOneWidget);
    expect(AppSession.instance.callConsultationId, 'c-1');

    // 3초 후 상태 확인: 약사가 화상방에 들어왔다
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
    expect(find.text('🔔 약사가 들어왔어요 — 지금 입장하기'), findsOneWidget);

    // 약사가 처방을 승인했다
    current = _consultation(status: 'approved', drug: '타이레놀정500밀리그람');
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
    expect(find.text('약사가 처방을 완료했어요'), findsOneWidget);
    expect(find.text('처방약: 타이레놀정500밀리그람'), findsOneWidget);
    expect(find.text('상담 요청 취소'), findsNothing);
    expect(requests.where((r) => r == 'POST /consultations'), hasLength(1));
    // 서버 종료 이후에도 약사가 늦게 공개하는 요약을 계속 조회한다.
    current = _consultation(status: 'approved', endedAt: '2026-10-17T05:10:00');
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
    current = _consultation(
      status: 'approved',
      endedAt: '2026-10-17T05:10:00',
      summary: '검토 후 공개된 상담 요약',
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
    expect(AppSession.instance.consultation?.summary, '검토 후 공개된 상담 요약');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reuses a pending consultation instead of creating one', (
    tester,
  ) async {
    var created = false;
    final client = MockClient((request) async {
      if (request.url.path == '/consultations' && request.method == 'GET') {
        return _json([_consultation()]);
      }
      if (request.method == 'POST') created = true;
      return _json(_consultation());
    });
    await _pumpPhone(
      tester,
      ConsultationScreen(
        direct: false,
        api: ConsultationApi(client: client),
        onScanQr: () {},
        onOpenChatbot: () {},
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(created, isFalse);
    expect(find.text('약사 연결을 기다리는 중이에요'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancel calls the server and returns to the chatbot', (
    tester,
  ) async {
    var cancelled = false;
    var openedChatbot = false;
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/consultations' && request.method == 'GET') {
        return _json([]);
      }
      if (path == '/consultations/c-1/cancel') {
        cancelled = true;
        return _json(_consultation(status: 'cancelled'));
      }
      return _json(_consultation(roomUrl: null));
    });
    await _pumpPhone(
      tester,
      ConsultationScreen(
        direct: false,
        api: ConsultationApi(client: client),
        onScanQr: () {},
        onOpenChatbot: () => openedChatbot = true,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(find.text('상담 요청 취소'), 200);
    await tester.tap(find.text('상담 요청 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('요청 취소'));
    await tester.pump();
    await tester.pump();
    expect(cancelled, isTrue);
    expect(openedChatbot, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the server error and retries', (tester) async {
    var fail = true;
    final client = MockClient((request) async {
      if (fail) return _json({'detail': '요청이 너무 많아요.'}, 429);
      if (request.method == 'GET' && request.url.path == '/consultations') {
        return _json([]);
      }
      return _json(_consultation(roomUrl: null));
    });
    await _pumpPhone(
      tester,
      ConsultationScreen(
        direct: false,
        api: ConsultationApi(client: client),
        onScanQr: () {},
        onOpenChatbot: () {},
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('상담 요청에 실패했어요'), findsOneWidget);
    expect(find.text('요청이 너무 많아요.'), findsOneWidget);

    fail = false;
    await tester.scrollUntilVisible(find.text('다시 요청하기'), 200);
    await tester.tap(find.text('다시 요청하기'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('약사 연결을 기다리는 중이에요'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('loads history without cancelled ones and maps permits', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/consultations') {
        return _json([
          _consultation(status: 'approved', drug: '베아제정'),
          _consultation(status: 'cancelled'),
        ]);
      }
      return _json([
        {
          'drug_item_name': '베아제정',
          'status': 'pending',
          'approved_by': 'pharm-1',
          'created_at': '2026-10-17T05:00:00',
          'expires_at': '2026-10-18T05:00:00',
        },
      ]);
    });
    final api = ConsultationApi(client: client);
    final history = await api.history('user-1');
    expect(history, hasLength(1));
    expect(history.single.approvedDrugName, '베아제정');
    final permits = await api.permits('user-1');
    expect(permits.single.status, PermitStatus.available);
    expect(permits.single.pharmacist, 'pharm-1');
  });
}
