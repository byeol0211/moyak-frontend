import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/config/app_config.dart';
import 'package:moyak/data/api_client.dart';
import 'package:moyak/data/auth_session.dart';
import 'package:moyak/data/models.dart';
import 'package:moyak/screens/care_profile_page.dart';
import 'package:moyak/screens/main_home_disconnected_screen.dart';
import 'package:moyak/screens/store_page.dart';
import 'package:moyak/widgets/consult_header.dart';
import 'package:moyak/widgets/machine_switch_sheet.dart';

void main() {
  testWidgets('tapping the home mascot opens the machine store', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: MainHomeConnectedScreen(
              machineName: '강남역 자판기',
              onScanQr: () {},
              onOpenStore: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MachineStorePage(
                    machineName: '강남역 자판기',
                    loadStock: () async => const [
                      StockItem(name: '타이레놀', stock: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('강남역 자판기 재고 보기'));
    await tester.pumpAndSettle();
    expect(find.text('자판기 재고'), findsOneWidget);
    expect(find.text('타이레놀'), findsOneWidget);
    expect(find.text('재고 3개'), findsOneWidget);
  });

  testWidgets('machine store offers retry when stock fails to load', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MachineStorePage(
          machineName: '강남역 자판기',
          loadStock: () async {
            calls++;
            if (calls == 1) throw Exception('offline');
            return const [StockItem(name: '판콜', stock: 0)];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('재고를 불러오지 못했어요.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('판콜'), findsOneWidget);
    expect(find.text('품절'), findsOneWidget);
  });

  testWidgets('care profile save button is green and fixed below the list', (
    tester,
  ) async {
    AppConfig.preview.value = false;
    AuthSession.set('test-token', 3600);
    addTearDown(AuthSession.clear);
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'revision': '2026-10-25T00:00:00Z',
            'care_note': '',
            'conditions': [],
            'medications': [],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: CareProfilePage(api: api)));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(FilledButton, '저장하기');
    expect(save, findsOneWidget);
    // 목록 안이 아니라 하단 고정 영역에 있다.
    expect(
      find.ancestor(of: save, matching: find.byType(Scrollable)),
      findsNothing,
    );
    final button = tester.widget<FilledButton>(save);
    expect(button.style?.backgroundColor?.resolve({}), consultGreen);
  });

  testWidgets('tapping the selected badge switches to another machine', (
    tester,
  ) async {
    const here = VendingMachine(
      id: 'a',
      name: '강남역 자판기',
      latitude: 0,
      longitude: 0,
    );
    const other = VendingMachine(
      id: 'b',
      name: '역삼역 자판기',
      latitude: 0,
      longitude: 0,
      address: '역삼역 2번 출구',
    );
    VendingMachine? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: MainHomeConnectedScreen(
              machineName: here.name,
              onScanQr: () {},
              onChangeMachine: () async {
                picked = await showMachineSwitchSheet(
                  context,
                  currentMachineId: here.id,
                  loadMachines: () async => const [here, other],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('강남역 자판기 선택됨'));
    await tester.pumpAndSettle();
    expect(find.text('연결할 자판기 변경'), findsOneWidget);
    expect(find.text('연결 중'), findsOneWidget);
    expect(find.text('역삼역 2번 출구'), findsOneWidget);

    // 지금 자판기를 누르면 바꾸지 않고 닫는다.
    await tester.tap(find.text('연결 중'));
    await tester.pumpAndSettle();
    expect(picked, isNull);

    await tester.tap(find.text('강남역 자판기 선택됨'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('역삼역 자판기'));
    await tester.pumpAndSettle();
    expect(picked?.id, 'b');
    expect(find.text('연결할 자판기 변경'), findsNothing);
  });
}
