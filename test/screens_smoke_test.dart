import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/data/demo_data.dart';
import 'package:moyak/data/models.dart';
import 'package:moyak/main.dart';
import 'package:moyak/screens/chatbot_screen.dart';
import 'package:moyak/screens/consult_history_screen.dart';
import 'package:moyak/screens/consultation_entry_page.dart';
import 'package:moyak/screens/consultation_screen.dart';
import 'package:moyak/screens/map_screen/map_screen.dart';
import 'package:moyak/screens/permit_list_screen.dart';
import 'package:moyak/config/app_config.dart';
import 'package:moyak/data/app_session.dart';

Future<void> _pumpPhone(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  setUp(() {
    AppConfig.preview.value = true;
    AppSession.instance.cancelConsultation();
    AppSession.instance.history.clear();
    AppSession.instance.permits.clear();
  });
  tearDown(() => AppConfig.preview.value = false);
  testWidgets('consultation: waiting → entry when the room is ready', (
    tester,
  ) async {
    await _pumpPhone(
      tester,
      ConsultationScreen(onScanQr: () {}, onOpenChatbot: () {}),
    );
    expect(find.text('약사 연결을 기다리는 중이에요'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('화상 상담 입장'), findsWidgets);
    expect(find.byTooltip('카메라 켜기'), findsOneWidget);
    expect(find.text('입장 전 화면과 소리를 확인해 주세요'), findsOneWidget);

    // 뒤로가면 대기 화면에서 입장 버튼이 보이고, 약사가 들어오면 문구가 바뀐다
    await tester.tap(find.byTooltip('이전 화면'));
    await tester.pump();
    expect(find.text('화상 상담 입장하기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('약사가 들어왔어요 — 지금 입장하기'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('consultation: cancel asks for confirmation', (tester) async {
    var openedChatbot = false;
    await _pumpPhone(
      tester,
      ConsultationScreen(
        direct: false,
        onScanQr: () {},
        onOpenChatbot: () => openedChatbot = true,
      ),
    );
    await tester.scrollUntilVisible(find.text('상담 요청 취소'), 200);
    await tester.tap(find.text('상담 요청 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('요청 취소'));
    await tester.pumpAndSettle();
    expect(openedChatbot, isTrue);
  });

  testWidgets('consult history lists records and opens details', (
    tester,
  ) async {
    ConsultRecord? opened;
    await _pumpPhone(
      tester,
      ConsultHistoryScreen(onOpenDetail: (record) => opened = record),
    );
    expect(find.text('불러오는 중...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('처방 완료'), findsOneWidget);
    await tester.tap(find.text('📝 상담 요약 보기'));
    await tester.pump();
    expect(find.text('주요 증상'), findsOneWidget);
    await tester.tap(find.text('자세히 보기 ›').first);
    expect(opened, isNotNull);
  });

  testWidgets('approved record shows the prescription result', (tester) async {
    final records = await tester.runAsync(fetchConsultHistory);
    final approved = records!.firstWhere(
      (r) => r.status == ConsultStatus.approved,
    );
    await _pumpPhone(
      tester,
      ConsultationScreen(
        record: approved,
        onScanQr: () {},
        onOpenChatbot: () {},
      ),
    );
    expect(find.text('약사가 처방을 완료했어요'), findsOneWidget);
    expect(find.text('처방약: 타이레놀정 500mg'), findsOneWidget);
    expect(find.text('상담 요청 취소'), findsNothing);
  });

  testWidgets('permit list renders demo permits', (tester) async {
    await _pumpPhone(tester, const PermitListScreen());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('사용 가능'), findsOneWidget);
    expect(find.textContaining('${DateTime.now().year}.'), findsOneWidget);
  });

  testWidgets('chatbot renders formatted answer and consult button', (
    tester,
  ) async {
    var consultRequested = false;
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'answer': '**타이레놀**은 해열제예요.\n- 4시간 간격\n- 하루 4정 이하',
          'sources': ['타이레놀정'],
          'evidence': [
            {'item_name': '타이레놀정', 'field_label': '용법', 'text': '1회 1정'},
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await _pumpPhone(
      tester,
      ChatPage(client: client, onRequestConsult: () => consultRequested = true),
    );
    expect(find.text('식품의약품안전처 공식 데이터 기반'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '타이레놀');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('타이레놀은 해열제예요.'), findsOneWidget);
    expect(find.text('하루 4정 이하'), findsOneWidget);
    await tester.tap(find.text('원문 근거 보기 (1)'));
    await tester.pumpAndSettle();
    expect(find.text('타이레놀정 · 용법'), findsOneWidget);
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('약사에게 바로 상담하기'));
    expect(consultRequested, isTrue);
  });

  testWidgets('map lists machines, shows stock and selects one', (
    tester,
  ) async {
    VendingMachine? selected;
    final client = MockClient((request) async {
      // 자판기 상세 재고 (GET /api/v1/map/machines/{id})
      if (request.url.path == '/api/v1/map/machines/near') {
        return http.Response(
          jsonEncode({
            'id': 'near',
            'items': [
              {'item_seq': '1', 'item_name': '베아제정', 'stock': 8, 'price': 4000},
              {
                'item_seq': '2',
                'item_name': '판콜에이내복액',
                'stock': 0,
                'price': 1500,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'far',
              'code': 'VM-009',
              'name': '모약 자판기 도서관',
              'address': '서울 마포구 양화로 160',
              'latitude': 37.47,
              'longitude': 126.66,
              'stock_count': 0,
            },
            {
              'id': 'near',
              'name': '모약 자판기 학생회관',
              'latitude': 37.451,
              'longitude': 126.654,
              'operating_hours': '09:00 ~ 18:00',
              'stock_count': 25,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    await _pumpPhone(
      tester,
      MapScreen(
        client: client,
        selectedMachineId: null,
        onSelectMachine: (machine) => selected = machine,
        onUnselectMachine: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('가까운 자판기 2곳'), findsOneWidget);
    expect(find.text('재고 있음'), findsOneWidget);
    expect(find.text('품절'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('machine-search')), '없는 이름');
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없어요. 자판기 이름이나 주소를 다시 확인해주세요.'), findsOneWidget);
    await tester.tap(find.byTooltip('자판기 검색어 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('가까운 자판기 2곳'), findsOneWidget);
    // 주소·코드로도, 띄어쓰기가 달라도 찾는다
    await tester.enterText(find.byKey(const Key('machine-search')), '마포 구');
    await tester.pumpAndSettle();
    expect(find.text('전체 자판기 검색 결과 1곳'), findsOneWidget);
    expect(find.text('모약 자판기 도서관'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('machine-search')), 'vm-009');
    await tester.pumpAndSettle();
    expect(find.text('모약 자판기 도서관'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('machine-search')), ' 학생 회관 ');
    await tester.pumpAndSettle();
    expect(find.text('전체 자판기 검색 결과 1곳'), findsOneWidget);
    expect(find.text('모약 자판기 도서관'), findsNothing);
    await tester.tap(find.text('모약 자판기 학생회관'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.textContaining('베아제정'), findsOneWidget);
    await tester.ensureVisible(find.text('이 자판기 선택'));
    await tester.tap(find.text('이 자판기 선택'));
    expect(selected?.id, 'near');
  });

  testWidgets('store shows the machine stock', (tester) async {
    await _pumpPhone(
      tester,
      const StorePage(
        machineName: '모약 자판기 학생회관',
        items: [
          StockItem(name: '어린이 해열제', stock: 3, price: 3000),
          StockItem(name: '판콜에이 내복액', stock: 0, price: 2600, category: '의약품'),
          StockItem(name: '대일밴드', stock: 5),
        ],
      ),
    );
    expect(find.text('모약 자판기 학생회관'), findsOneWidget);
    expect(find.text('재고 3개'), findsOneWidget);
    expect(find.text('품절'), findsOneWidget);
    expect(find.text('재고 5개'), findsOneWidget);
    expect(find.text('빠른 구매'), findsNothing);
  });

  testWidgets('entry: device switches and preview buttons stay in sync', (
    tester,
  ) async {
    await _pumpPhone(
      tester,
      ConsultationEntryPage(onBack: () {}, onScanQr: () {}, onEnd: () {}),
    );
    expect(
      find.text('화면 설정만 시연해요. 카메라·마이크 권한을 요청하거나 실제로 연결하지 않습니다.'),
      findsOneWidget,
    );
    expect(find.text('꺼짐 · UI 예시'), findsNWidgets(2));
    expect(find.text('켜짐 · UI 예시'), findsOneWidget);

    // 카메라 카드 스위치를 켜면 미리보기 상자의 버튼도 "끄기"로 바뀐다.
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(find.byTooltip('카메라 끄기'), findsOneWidget);
    expect(find.text('켜짐 · UI 예시'), findsNWidgets(2));

    // 상자 안 마이크 버튼을 누르면 마이크 카드 스위치가 켜진다.
    await tester.tap(find.byTooltip('마이크 켜기'));
    await tester.pump();
    final micSwitch = tester.widget<Switch>(find.byType(Switch).at(1));
    expect(micSwitch.value, isTrue);
  });
}
