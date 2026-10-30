import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/config/app_config.dart';
import 'package:moyak/data/api_client.dart';
import 'package:moyak/data/auth_session.dart';
import 'package:moyak/screens/care_profile_page.dart';

void main() {
  setUp(() {
    AppConfig.preview.value = false;
    AuthSession.set('test-token', 3600);
  });
  tearDown(AuthSession.clear);

  testWidgets(
    'new cards keep unknown answers empty and save selections and medication',
    (tester) async {
      tester.view.physicalSize = const Size(380, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = <String, dynamic>{
        'revision': 'r1',
        'care_note': '',
        'conditions': [],
        'medications': [],
      };
      Map<String, dynamic>? saved;
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.method == 'PATCH') {
            saved = jsonDecode(request.body) as Map<String, dynamic>;
          }
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await tester.pumpWidget(MaterialApp(home: CareProfilePage(api: api)));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<FilterChip>(find.byType(FilterChip))
            .every((chip) => !chip.selected),
        isTrue,
      );
      await tester.tap(find.text('페니실린계 항생제'));
      await tester.pump();
      await tester.tap(find.text('알러지 없음'));
      await tester.pump();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '페니실린계 항생제'))
            .selected,
        isFalse,
      );
      final drug = find.widgetWithText(TextFormField, '약 이름을 입력하세요');
      await tester.scrollUntilVisible(
        drug,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(drug, '타이레놀 500mg');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장하기'));
      await tester.pumpAndSettle();
      expect((saved!['conditions'] as List).single['label'], '알러지 없음');
      expect((saved!['medications'] as List).single['drug_name'], '타이레놀 500mg');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'loads structured data and saves with Bearer; preserves read-only medications',
    (tester) async {
      final data = <String, dynamic>{
        'revision': '2026-10-25T00:00:00Z',
        'care_note': '기존 메모',
        'conditions': [
          <String, dynamic>{
            'id': 'condition-1',
            'condition_type': 'disease',
            'label': '고혈압',
            'note': '',
          },
        ],
        'medications': [
          <String, dynamic>{
            'id': 'med-1',
            'source': 'prescription',
            'drug_name': '처방약',
            'dosage_note': '',
          },
        ],
      };
      Map<String, dynamic>? saved;
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test-token');
          expect(request.url.path, '/auth/me/care-profile');
          if (request.method == 'PATCH') {
            saved = jsonDecode(request.body) as Map<String, dynamic>;
          }
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await tester.pumpWidget(MaterialApp(home: CareProfilePage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('고혈압'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('기존 메모'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '기존 메모'),
        '상담 때 확인해주세요',
      );
      await tester.scrollUntilVisible(
        find.text('저장하기'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('저장하기'));
      await tester.pumpAndSettle();
      expect(saved!['care_note'], '상담 때 확인해주세요');
      expect(
        (saved!['conditions'] as List).single['condition_type'],
        'disease',
      );
      expect(saved!['medications'], isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('load failure is visible and does not show a save button', (
    tester,
  ) async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response('{"detail":"Login required"}', 401),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: CareProfilePage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Login required'), findsOneWidget);
    expect(find.text('저장하기'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'guest opening care profile shows guidance without calling server',
    (tester) async {
      AuthSession.clear();
      var calls = 0;
      final api = ApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 401);
        }),
      );
      await tester.pumpWidget(MaterialApp(home: CareProfilePage(api: api)));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.textContaining('상담 참고사항은 로그인 후'), findsOneWidget);
      expect(find.text('저장하기'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing deployed endpoint explains server update without showing empty profile',
    (tester) async {
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response('{"detail":"Not Found"}', 404),
        ),
      );
      await tester.pumpWidget(MaterialApp(home: CareProfilePage(api: api)));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('현재 연결된 서버에 상담 참고사항 기능이 아직 반영되지 않았어요.'),
        findsOneWidget,
      );
      expect(find.text('다시 불러오기'), findsOneWidget);
      expect(find.text('저장하기'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
